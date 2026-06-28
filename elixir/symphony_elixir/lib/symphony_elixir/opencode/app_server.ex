# このファイルは元のApache 2.0ライセンスのコードから新規に追加されています
# 変更日: 2026-06-28
# 変更者: totto2727
# 変更内容: OpenCode HTTP server 連携用 AppServer を追加

defmodule SymphonyElixir.Opencode.AppServer do
  @moduledoc """
  HTTP-based client for the OpenCode server, mirroring the Codex.AppServer interface.

  Instead of spawning a codex app-server subprocess over stdio, this module talks to
  a running `opencode serve` instance via HTTP.  Session lifecycle maps as follows:

    * `start_session/2` -> POST /session
    * `run_turn/4`      -> POST /session/{id}/prompt_async + GET /event (SSE)
    * `stop_session/1`  -> DELETE /session/{id}

  The SSE event stream is consumed in a linked helper process that forwards parsed
  events to the calling process.  A turn is considered complete when a `session.idle`
  event is received for the session, and failed when a `session.error` event arrives.
  """

  require Logger

  alias SymphonyElixir.{Config, Linear.Issue}
  alias OpencodeClient.EventStream
  alias OpencodeClient.Generated.Session

  @default_base_url "http://localhost:4096"
  @default_turn_timeout_ms 3_600_000

  @type session :: %{
          client: keyword(),
          session_id: String.t(),
          workspace: Path.t(),
          metadata: map()
        }

  @spec run(Path.t(), String.t(), map(), keyword()) :: {:ok, map()} | {:error, term()}
  def run(workspace, prompt, issue, opts \\ []) do
    with {:ok, session} <- start_session(workspace, opts) do
      try do
        run_turn(session, prompt, issue, opts)
      after
        stop_session(session)
      end
    end
  end

  @spec start_session(Path.t(), keyword()) :: {:ok, session()} | {:error, term()}
  def start_session(workspace, opts \\ []) do
    client = build_client(opts)
    title = Keyword.get(opts, :title, "Symphony agent run")
    body = %{title: title, directory: workspace}

    case Session.session_create(body, client) do
      {:ok, body_json} when is_map(body_json) ->
        session_id = get_field(body_json, :id)

        if is_binary(session_id) and session_id != "" do
          {:ok,
           %{
             client: client,
             session_id: session_id,
             workspace: workspace,
             metadata: %{opencode_session_id: session_id}
           }}
        else
          {:error, {:invalid_session_response, body_json}}
        end

      {:ok, body} ->
        {:error, {:session_create_failed, body}}

      {:error, reason} ->
        {:error, {:session_create_error, reason}}
    end
  end

  @spec run_turn(session(), String.t(), map(), keyword()) :: {:ok, map()} | {:error, term()}
  def run_turn(%{client: client, session_id: session_id, workspace: workspace} = session, prompt, issue, opts \\ []) do
    on_message = Keyword.get(opts, :on_message, &default_on_message/1)
    timeout_ms = turn_timeout_ms()

    emit_message(
      on_message,
      :session_started,
      %{
        session_id: session_id,
        thread_id: session_id,
        turn_id: session_id
      },
      session.metadata
    )

    body = %{parts: [%{type: "text", text: prompt}]}

    parent = self()
    sse_pid = spawn_link(fn -> sse_listener(client, session_id, parent) end)

    case Session.session_prompt_async(session_id, body, client) do
      :ok ->
        Logger.info("OpenCode prompt accepted for #{issue_context(issue)} session_id=#{session_id} workspace=#{workspace}")

        case await_turn_completion(session_id, on_message, session.metadata, timeout_ms, issue) do
          {:ok, result} ->
            Logger.info("OpenCode session completed for #{issue_context(issue)} session_id=#{session_id}")
            {:ok, %{result: result, session_id: session_id, thread_id: session_id, turn_id: session_id}}

          {:error, reason} ->
            Logger.warning("OpenCode session ended with error for #{issue_context(issue)} session_id=#{session_id}: #{inspect(reason)}")
            emit_message(on_message, :turn_ended_with_error, %{session_id: session_id, reason: reason}, session.metadata)
            {:error, reason}
        end

      {:ok, body} ->
        stop_sse_listener(sse_pid)
        {:error, {:prompt_async_failed, body}}

      {:error, reason} ->
        stop_sse_listener(sse_pid)
        {:error, {:prompt_async_error, reason}}
    end
  end

  @spec stop_session(session()) :: :ok
  def stop_session(%{client: client, session_id: session_id}) do
    case Session.session_delete(session_id, client) do
      {:ok, _} ->
        :ok

      :ok ->
        :ok

      {:error, reason} ->
        Logger.warning("OpenCode session delete failed for session_id=#{session_id}: #{inspect(reason)}")
        :ok
    end
  end

  defp build_client(opts) do
    base_url =
      Keyword.get(opts, :base_url) ||
        System.get_env("OPENCODE_BASE_URL") ||
        @default_base_url

    auth =
      case {System.get_env("OPENCODE_AUTH_USER"), System.get_env("OPENCODE_AUTH_PASS")} do
        {user, pass} when is_binary(user) and is_binary(pass) -> {:basic, user, pass}
        _ -> nil
      end

    [base_url: base_url, auth: auth]
  end

  defp get_field(map, field) when is_map(map) do
    Map.get(map, field) || Map.get(map, Atom.to_string(field))
  end

  defp turn_timeout_ms do
    case Config.settings() do
      {:ok, settings} -> settings.codex.turn_timeout_ms
      _ -> @default_turn_timeout_ms
    end
  end

  defp sse_listener(client, _session_id, parent) do
    {:ok, stream} = EventStream.stream(client)

    stream
    |> Stream.each(fn event ->
      send(parent, {:sse_event, event})
    end)
    |> Stream.run()
  catch
    kind, reason ->
      send(parent, {:sse_error, {kind, reason}})
  end

  defp stop_sse_listener(pid) when is_pid(pid) do
    Process.unlink(pid)
    Process.exit(pid, :kill)
  catch
    _, _ -> :ok
  end

  defp await_turn_completion(session_id, on_message, metadata, timeout_ms, issue) do
    deadline = System.monotonic_time(:millisecond) + timeout_ms

    receive do
      {:sse_event, %{type: "session.idle", data: %{"properties" => %{"sessionID" => ^session_id}}}} ->
        emit_message(on_message, :turn_completed, %{session_id: session_id}, metadata)
        {:ok, :turn_completed}

      {:sse_event, %{type: "session.idle", data: %{"sessionID" => ^session_id}}} ->
        emit_message(on_message, :turn_completed, %{session_id: session_id}, metadata)
        {:ok, :turn_completed}

      {:sse_event, %{type: "session.error", data: %{"properties" => %{"sessionID" => ^session_id, "error" => error}}}} ->
        emit_message(on_message, :turn_failed, %{session_id: session_id, error: error}, metadata)
        {:error, {:session_error, error}}

      {:sse_event, %{type: "session.error", data: %{"sessionID" => ^session_id}}} ->
        emit_message(on_message, :turn_failed, %{session_id: session_id}, metadata)
        {:error, {:session_error, :unknown}}

      {:sse_event, %{type: type, data: data}} ->
        Logger.debug("OpenCode SSE event for #{issue_context(issue)} session_id=#{session_id} type=#{type}")
        emit_message(on_message, :notification, %{type: type, payload: data}, metadata)
        now = System.monotonic_time(:millisecond)

        if now >= deadline do
          {:error, :turn_timeout}
        else
          await_turn_completion(session_id, on_message, metadata, deadline - now, issue)
        end

      {:sse_error, reason} ->
        {:error, {:sse_stream_error, reason}}
    after
      timeout_ms ->
        {:error, :turn_timeout}
    end
  end

  defp emit_message(on_message, event, details, metadata) when is_function(on_message, 1) do
    message = metadata |> Map.merge(details) |> Map.put(:event, event) |> Map.put(:timestamp, DateTime.utc_now())
    on_message.(message)
  end

  defp default_on_message(_message), do: :ok

  defp issue_context(%Issue{id: issue_id, identifier: identifier}) do
    "issue_id=#{issue_id} issue_identifier=#{identifier}"
  end

  defp issue_context(%{id: issue_id, identifier: identifier}) do
    "issue_id=#{issue_id} issue_identifier=#{identifier}"
  end

  defp issue_context(_), do: "issue_id=unknown"
end
