defmodule OpencodeClient.EventStream do
  @moduledoc """
  Server-Sent Events subscription helpers for OpenCode Server.

  SSE frame parsing is delegated to `ReqServerSentEvents`; this module only opens
  the `/event` HTTP stream and JSON-decodes frame payloads.
  """

  @type event :: %{
          type: String.t() | nil,
          data: term,
          id: String.t() | nil,
          retry: non_neg_integer() | nil
        }

  @spec stream(keyword) :: {:ok, Enumerable.t()}
  def stream(opts \\ []) do
    owner = self()
    ref = make_ref()
    timeout = Keyword.get(opts, :receive_timeout, 30_000)

    task =
      Task.async(fn ->
        result = request_stream(owner, ref, opts)
        send(owner, {ref, {:done, result}})
        result
      end)

    {:ok, stream_from_mailbox(ref, task, timeout)}
  end

  @doc false
  @spec decode_frame_for_test(map()) :: event()
  def decode_frame_for_test(frame), do: decode_frame(frame)

  defp request_stream(owner, ref, opts) do
    req =
      Req.new(
        base_url: Keyword.get(opts, :base_url, OpencodeClient.Config.base_url()),
        method: :get,
        url: "/event",
        into: fn {:sse_event, frame}, {req, resp} ->
          send(owner, {ref, {:event, frame}})
          {:cont, {req, resp}}
        end
      )
      |> OpencodeClient.Auth.apply(Keyword.get(opts, :auth, OpencodeClient.Config.auth()))
      |> ReqServerSentEvents.attach()

    Req.request(req)
  end

  defp stream_from_mailbox(ref, task, timeout) do
    Stream.resource(
      fn -> {ref, task, timeout} end,
      fn {ref, _task, timeout} = state ->
        receive do
          {^ref, {:event, frame}} -> {[decode_frame(frame)], state}
          {^ref, {:done, _result}} -> {:halt, state}
        after
          timeout -> {:halt, state}
        end
      end,
      fn {_ref, task, _timeout} -> Task.shutdown(task, :brutal_kill) end
    )
  end

  defp decode_frame(%{event: event, data: data, id: id, retry: retry}) do
    decoded_data = decode_data(data)

    %{
      type: event || event_type(decoded_data),
      data: decoded_data,
      id: id,
      retry: retry
    }
  end

  defp decode_data(nil), do: nil

  defp decode_data(data) do
    case Jason.decode(data) do
      {:ok, decoded} -> decoded
      {:error, _reason} -> data
    end
  end

  defp event_type(%{"type" => type}) when is_binary(type), do: type
  defp event_type(%{type: type}) when is_binary(type), do: type
  defp event_type(%{"payload" => payload}) when is_map(payload), do: event_type(payload)
  defp event_type(%{payload: payload}) when is_map(payload), do: event_type(payload)
  defp event_type(_data), do: nil
end
