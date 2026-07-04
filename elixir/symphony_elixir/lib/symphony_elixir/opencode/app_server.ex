# このファイルは元のApache 2.0ライセンスのコードから新規に追加されています
# 変更日: 2026-06-28
# 変更者: totto2727
# 変更内容: OpenCode HTTP server 連携用 AppServer を追加し、server/client 起動責務を opencode_client へ委譲

defmodule SymphonyElixir.Opencode.AppServer do
  @moduledoc """
  HTTP-based client for the OpenCode server.

  Session lifecycle maps as follows:

    * `start_session/2` -> start or connect to `opencode serve`, then POST /session
    * `run_turn/4`      -> POST /session/{id}/prompt_async + GET /event (SSE)
    * `stop_session/1`  -> DELETE /session/{id}

  The SSE event stream is consumed in a linked helper process that forwards parsed
  events to the calling process.  A turn is considered complete when a `session.idle`
  event is received for the session, and failed when a `session.error` event arrives.
  """

  require Logger

  alias OpencodeClient.{Connection, EventStream}
  alias OpencodeClient.Generated.Session
  alias SymphonyElixir.{Config, Linear.Issue, PathSafety}
  alias SymphonyElixir.Opencode.ConnectionManager

  @default_turn_timeout_ms 3_600_000

  @type session :: %{
          client: keyword(),
          connection: Connection.t(),
          event_stream: module(),
          session_id: String.t(),
          session_api: module(),
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
    worker_host = Keyword.get(opts, :worker_host)

    with {:ok, expanded_workspace} <- validate_workspace_cwd(workspace, worker_host),
         {:ok, connection} <- start_connection(opts, worker_host) do
      create_session(expanded_workspace, opts, connection)
    end
  end

  @spec run_turn(session(), String.t(), map(), keyword()) :: {:ok, map()} | {:error, term()}
  def run_turn(
        %{
          client: client,
          event_stream: event_stream,
          session_api: session_api,
          session_id: session_id,
          workspace: workspace
        } = session,
        prompt,
        issue,
        opts \\ []
      ) do
    on_message = Keyword.get(opts, :on_message, &default_on_message/1)
    timeout_ms = turn_timeout_ms(opts)

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

    body =
      %{parts: [%{type: "text", text: prompt}]}
      |> maybe_put_system(Keyword.get(opts, :system))

    parent = self()
    sse_pid = spawn_link(fn -> sse_listener(event_stream, client, parent) end)

    try do
      case session_api.session_prompt_async(session_id, body, client) do
        :ok ->
          Logger.info(
            "OpenCode prompt accepted for #{issue_context(issue)} session_id=#{session_id} workspace=#{workspace}"
          )

          case await_turn_completion(session_id, on_message, session.metadata, timeout_ms, issue) do
            {:ok, result} ->
              Logger.info(
                "OpenCode session completed for #{issue_context(issue)} session_id=#{session_id}"
              )

              {:ok,
               %{
                 result: result,
                 session_id: session_id,
                 thread_id: session_id,
                 turn_id: session_id
               }}

            {:error, reason} ->
              Logger.warning(
                "OpenCode session ended with error for #{issue_context(issue)} session_id=#{session_id}: #{inspect(reason)}"
              )

              emit_message(
                on_message,
                :turn_ended_with_error,
                %{session_id: session_id, reason: reason},
                session.metadata
              )

              {:error, reason}
          end

        {:ok, body} ->
          {:error, {:prompt_async_failed, body}}

        {:error, reason} ->
          {:error, {:prompt_async_error, reason}}
      end
    after
      stop_sse_listener(sse_pid)
    end
  end

  @spec stop_session(session()) :: :ok
  def stop_session(%{client: client, session_api: session_api, session_id: session_id} = session) do
    case session_api.session_delete(session_id, client) do
      {:ok, _} ->
        :ok

      :ok ->
        :ok

      {:error, reason} ->
        Logger.warning(
          "OpenCode session delete failed for session_id=#{session_id}: #{inspect(reason)}"
        )

        :ok
    end
  catch
    kind, reason ->
      Logger.warning(
        "OpenCode session delete raised for session_id=#{session_id}: #{inspect({kind, reason})}"
      )

      :ok
  after
    stop_connection(session.connection)
  end

  defp create_session(workspace, opts, %{client: client} = connection) do
    session_api = Keyword.get(opts, :session_api, Session)
    event_stream = Keyword.get(opts, :event_stream, EventStream)
    title = Keyword.get(opts, :title, "Symphony agent run")
    body = %{title: title, directory: workspace}

    case session_api.session_create(body, client) do
      {:ok, body_json} when is_map(body_json) ->
        case get_field(body_json, :id) do
          session_id when is_binary(session_id) and session_id != "" ->
            {:ok,
             %{
               client: client,
               connection: connection,
               event_stream: event_stream,
               session_api: session_api,
               session_id: session_id,
               workspace: workspace,
               metadata: session_metadata(session_id, client, connection)
             }}

          _ ->
            stop_connection(connection)
            {:error, {:invalid_session_response, body_json}}
        end

      {:ok, body} ->
        stop_connection(connection)
        {:error, {:session_create_failed, body}}

      {:error, reason} ->
        stop_connection(connection)
        {:error, {:session_create_error, reason}}
    end
  end

  defp start_connection(opts, worker_host) do
    server_config =
      Map.merge(Config.opencode_server_config(), Keyword.get(opts, :server_config, %{}))

    opts =
      opts
      |> Keyword.take([
        :auth,
        :base_url,
        :client_opts,
        :connection_manager,
        :server_config,
        :server_module,
        :server_opts
      ])
      |> Keyword.put(:server_config, server_config)
      |> Keyword.put(:allow_server_start, is_nil(worker_host))

    if shared_local_connection?(opts, worker_host) do
      manager = Keyword.get(opts, :connection_manager, ConnectionManager)

      case ConnectionManager.connection(opts, manager) do
        {:ok, connection} -> {:ok, Map.put(connection, :worker_host, worker_host)}
        {:error, reason} -> {:error, reason}
      end
    else
      start_direct_connection(opts, worker_host)
    end
  end

  defp start_direct_connection(opts, worker_host) do
    case Connection.start(opts) do
      {:ok, connection} ->
        {:ok, Map.put(connection, :worker_host, worker_host)}

      {:error, :opencode_base_url_required} when is_binary(worker_host) ->
        {:error, {:opencode_remote_worker_requires_base_url, worker_host}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp shared_local_connection?(opts, nil), do: is_nil(explicit_base_url(opts))
  defp shared_local_connection?(_opts, _worker_host), do: false

  defp explicit_base_url(opts) do
    opts
    |> Keyword.get(:base_url, System.get_env("OPENCODE_BASE_URL"))
    |> case do
      url when is_binary(url) ->
        url = String.trim(url)
        if url == "", do: nil, else: url

      _ ->
        nil
    end
  end

  defp stop_connection(%{shared_server_owner: ConnectionManager}), do: :ok
  defp stop_connection(connection), do: Connection.stop(connection)

  defp session_metadata(session_id, client, connection) do
    connection
    |> Connection.metadata()
    |> Map.put(:opencode_base_url, Keyword.get(client, :base_url))
    |> Map.put(:opencode_session_id, session_id)
    |> maybe_put(:worker_host, connection.worker_host)
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp maybe_put_system(body, system) when is_binary(system) do
    case String.trim(system) do
      "" -> body
      trimmed -> Map.put(body, :system, trimmed)
    end
  end

  defp maybe_put_system(body, _system), do: body

  defp validate_workspace_cwd(workspace, nil) when is_binary(workspace) do
    expanded_workspace = Path.expand(workspace)
    expanded_root = Path.expand(Config.settings!().workspace.root)
    expanded_root_prefix = expanded_root <> "/"

    with {:ok, canonical_workspace} <- PathSafety.canonicalize(expanded_workspace),
         {:ok, canonical_root} <- PathSafety.canonicalize(expanded_root) do
      canonical_root_prefix = canonical_root <> "/"

      cond do
        canonical_workspace == canonical_root ->
          {:error, {:invalid_workspace_cwd, :workspace_root, canonical_workspace}}

        String.starts_with?(canonical_workspace <> "/", canonical_root_prefix) ->
          {:ok, canonical_workspace}

        String.starts_with?(expanded_workspace <> "/", expanded_root_prefix) ->
          {:error, {:invalid_workspace_cwd, :symlink_escape, expanded_workspace, canonical_root}}

        true ->
          {:error,
           {:invalid_workspace_cwd, :outside_workspace_root, canonical_workspace, canonical_root}}
      end
    else
      {:error, {:path_canonicalize_failed, path, reason}} ->
        {:error, {:invalid_workspace_cwd, :path_unreadable, path, reason}}
    end
  end

  defp validate_workspace_cwd(workspace, worker_host)
       when is_binary(workspace) and is_binary(worker_host) do
    cond do
      String.trim(workspace) == "" ->
        {:error, {:invalid_workspace_cwd, :empty_remote_workspace, worker_host}}

      String.contains?(workspace, ["\n", "\r", <<0>>]) ->
        {:error, {:invalid_workspace_cwd, :invalid_remote_workspace, worker_host, workspace}}

      true ->
        {:ok, workspace}
    end
  end

  defp get_field(map, field) when is_map(map) do
    Map.get(map, field) || Map.get(map, Atom.to_string(field))
  end

  defp turn_timeout_ms(opts) do
    case Keyword.get(opts, :turn_timeout_ms) do
      timeout_ms when is_integer(timeout_ms) and timeout_ms > 0 ->
        timeout_ms

      _ ->
        case Config.settings() do
          {:ok, settings} -> settings.opencode.turn_timeout_ms
          _ -> @default_turn_timeout_ms
        end
    end
  end

  defp sse_listener(event_stream, client, parent) do
    case event_stream.stream(client) do
      {:ok, stream} ->
        stream
        |> Stream.each(fn event ->
          send(parent, {:sse_event, event})
        end)
        |> Stream.run()

      {:error, reason} ->
        send(parent, {:sse_error, reason})

      other ->
        send(parent, {:sse_error, {:invalid_stream_response, other}})
    end
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
      {:sse_event, event} ->
        type = event_type(event)
        data = event_data(event)

        Logger.debug(
          "OpenCode SSE event for #{issue_context(issue)} session_id=#{session_id} type=#{inspect(type)}"
        )

        handle_sse_event(session_id, type, data, on_message, metadata, deadline, issue)

      {:sse_error, reason} ->
        {:error, {:sse_stream_error, reason}}
    after
      timeout_ms ->
        {:error, :turn_timeout}
    end
  end

  defp handle_sse_event(session_id, "session.idle", data, on_message, metadata, deadline, issue) do
    if event_for_session?(data, session_id) do
      emit_message(on_message, :turn_completed, %{session_id: session_id}, metadata)
      {:ok, :turn_completed}
    else
      continue_after_notification(
        session_id,
        "session.idle",
        data,
        on_message,
        metadata,
        deadline,
        issue
      )
    end
  end

  defp handle_sse_event(session_id, "session.error", data, on_message, metadata, deadline, issue) do
    if event_for_session?(data, session_id) do
      error = event_error(data)
      emit_message(on_message, :turn_failed, %{session_id: session_id, error: error}, metadata)
      {:error, {:session_error, error}}
    else
      continue_after_notification(
        session_id,
        "session.error",
        data,
        on_message,
        metadata,
        deadline,
        issue
      )
    end
  end

  defp handle_sse_event(session_id, type, data, on_message, metadata, deadline, issue)
       when type in ["permission.asked", "question.asked"] do
    if event_for_session?(data, session_id) do
      reason = {:interactive_input_required, type, data}

      emit_message(
        on_message,
        :turn_input_required,
        %{session_id: session_id, reason: reason},
        metadata
      )

      {:error, reason}
    else
      continue_after_notification(session_id, type, data, on_message, metadata, deadline, issue)
    end
  end

  defp handle_sse_event(session_id, type, data, on_message, metadata, deadline, issue) do
    continue_after_notification(session_id, type, data, on_message, metadata, deadline, issue)
  end

  defp continue_after_notification(session_id, type, data, on_message, metadata, deadline, issue) do
    emit_message(on_message, :notification, %{type: type, payload: data}, metadata)
    now = System.monotonic_time(:millisecond)

    if now >= deadline do
      {:error, :turn_timeout}
    else
      await_turn_completion(session_id, on_message, metadata, deadline - now, issue)
    end
  end

  defp event_type(%{type: type}) when is_binary(type), do: type
  defp event_type(%{"type" => type}) when is_binary(type), do: type
  defp event_type(%{data: data}), do: event_type(data)
  defp event_type(%{"data" => data}), do: event_type(data)
  defp event_type(event), do: find_nested_field(event, [:type, "type"])

  defp event_data(%{data: data}), do: data
  defp event_data(%{"data" => data}), do: data
  defp event_data(event), do: event

  defp event_for_session?(data, session_id) do
    case find_nested_field(data, [:sessionID, "sessionID", :session_id, "session_id"]) do
      nil -> false
      ^session_id -> true
      _ -> false
    end
  end

  defp event_error(data) do
    find_nested_field(data, [:error, "error"]) || :unknown
  end

  defp find_nested_field(nil, _keys), do: nil

  defp find_nested_field(data, keys) when is_map(data) do
    Enum.find_value(keys, &Map.get(data, &1)) ||
      data
      |> nested_maps()
      |> Enum.find_value(&find_nested_field(&1, keys))
  end

  defp find_nested_field(_data, _keys), do: nil

  defp nested_maps(data) when is_map(data) do
    data
    |> Map.take([:payload, "payload", :properties, "properties"])
    |> Map.values()
    |> Enum.filter(&is_map/1)
  end

  defp emit_message(on_message, event, details, metadata) when is_function(on_message, 1) do
    message =
      metadata
      |> Map.merge(details)
      |> Map.put(:event, event)
      |> Map.put(:timestamp, DateTime.utc_now())

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
