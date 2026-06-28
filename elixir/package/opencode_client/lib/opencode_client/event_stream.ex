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

  defp request_stream(owner, ref, opts) do
    req =
      Req.new(
        base_url: Keyword.get(opts, :base_url, base_url()),
        method: :get,
        url: "/event",
        into: fn {:sse_event, frame}, {req, resp} ->
          send(owner, {ref, {:event, frame}})
          {:cont, {req, resp}}
        end
      )
      |> apply_auth(Keyword.get(opts, :auth, auth()))
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

  defp decode_frame(%ReqServerSentEvents.Frame{} = frame) do
    %{
      type: frame.event,
      data: decode_data(frame.data),
      id: frame.id,
      retry: frame.retry
    }
  end

  defp decode_data(nil), do: nil

  defp decode_data(data) do
    case Jason.decode(data) do
      {:ok, decoded} -> decoded
      {:error, _reason} -> data
    end
  end

  defp apply_auth(req, {:basic, username, password}) do
    Req.merge(req, auth: {:basic, username, password})
  end

  defp apply_auth(req, {:bearer, token}) do
    Req.merge(req, auth: {:bearer, token})
  end

  defp apply_auth(req, _auth), do: req

  defp base_url do
    Application.get_env(:opencode_client, :base_url, "http://localhost:4096")
  end

  defp auth do
    Application.get_env(:opencode_client, :auth)
  end
end
