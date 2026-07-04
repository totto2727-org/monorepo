# このファイルは元のApache 2.0ライセンスのコードから新規に追加されています
# 変更日: 2026-07-04
# 変更者: totto2727
# 変更内容: OpenCode のローカル共有サーバー接続を管理する GenServer を追加

defmodule Symphony.Opencode.ConnectionManager do
  @moduledoc """
  Owns the app-wide local OpenCode server connection.

  Explicit `base_url` connections remain externally owned by callers. This
  manager only starts and supervises the local `opencode serve` process used
  when Symphony runs agents on the local machine.
  """

  use GenServer

  require Logger

  alias OpencodeClient.Connection
  alias OpencodeClient.Generated.Global

  @default_health_interval_ms 30_000

  defstruct connection: nil,
            connection_key: nil,
            connection_opts: nil,
            health_api: Global,
            health_interval_ms: @default_health_interval_ms,
            health_timer: nil,
            last_error: nil

  @type server :: GenServer.server()

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    {name, opts} = Keyword.pop(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @spec connection(keyword(), server()) :: {:ok, Connection.t()} | {:error, term()}
  def connection(opts, server \\ __MODULE__) do
    with :ok <- ensure_default_manager_started(server) do
      GenServer.call(server, {:connection, opts}, :infinity)
    end
  end

  @spec health_check(server()) :: :ok | {:error, term()}
  def health_check(server \\ __MODULE__) do
    GenServer.call(server, :health_check, :infinity)
  end

  @spec stop_connection(server()) :: :ok
  def stop_connection(server \\ __MODULE__) do
    GenServer.call(server, :stop_connection, :infinity)
  end

  @impl true
  def init(opts) do
    health_interval_ms = Keyword.get(opts, :health_interval_ms, @default_health_interval_ms)

    state = %__MODULE__{
      health_api: Keyword.get(opts, :health_api, Global),
      health_interval_ms: health_interval_ms
    }

    {:ok, schedule_health_check(state)}
  end

  @impl true
  def handle_call({:connection, opts}, _from, state) do
    case ensure_connection(opts, state) do
      {:ok, connection, next_state} ->
        {:reply, {:ok, session_connection(connection, opts)}, next_state}

      {:error, reason, next_state} ->
        {:reply, {:error, reason}, next_state}
    end
  end

  def handle_call(:health_check, _from, state) do
    {reply, next_state} = run_health_check(state)
    {:reply, reply, next_state}
  end

  def handle_call(:stop_connection, _from, state) do
    {:reply, :ok, stop_owned_connection(state)}
  end

  @impl true
  def handle_info(:health_check, state) do
    {_reply, next_state} = run_health_check(%{state | health_timer: nil})
    {:noreply, schedule_health_check(next_state)}
  end

  @impl true
  def terminate(_reason, state) do
    _state = stop_owned_connection(state)
    :ok
  end

  defp ensure_connection(opts, %{connection: connection, connection_key: key} = state)
       when not is_nil(connection) do
    next_key = connection_key(opts)

    if next_key == key do
      {:ok, connection, state}
    else
      state
      |> stop_owned_connection()
      |> start_connection(opts)
    end
  end

  defp ensure_connection(opts, state), do: start_connection(state, opts)

  defp start_connection(state, opts) do
    connection_opts = Keyword.put(opts, :allow_server_start, true)

    case Connection.start(connection_opts) do
      {:ok, connection} ->
        {:ok, connection,
         %{
           state
           | connection: connection,
             connection_key: connection_key(opts),
             connection_opts: connection_opts,
             last_error: nil
         }}

      {:error, reason} ->
        {:error, reason, %{state | connection: nil, last_error: reason}}
    end
  end

  defp run_health_check(%{connection: nil} = state), do: {:ok, state}

  defp run_health_check(%{connection: %{client: client}, health_api: health_api} = state) do
    case health_api.global_health(client) do
      {:ok, %{healthy: true}} ->
        {:ok, %{state | last_error: nil}}

      {:ok, %{"healthy" => true}} ->
        {:ok, %{state | last_error: nil}}

      {:ok, response} ->
        restart_unhealthy_connection({:unhealthy, response}, state)

      {:error, reason} ->
        restart_unhealthy_connection(reason, state)
    end
  end

  defp restart_unhealthy_connection(reason, state) do
    Logger.warning("OpenCode health check failed; restarting shared server: #{inspect(reason)}")

    restart_opts = state.connection_opts
    stopped_state = stop_owned_connection(state)

    case restart_opts do
      nil ->
        {{:error, reason}, %{stopped_state | last_error: reason}}

      opts ->
        case start_connection(stopped_state, opts) do
          {:ok, _connection, next_state} -> {:ok, next_state}
          {:error, start_reason, next_state} -> {{:error, start_reason}, next_state}
        end
    end
  end

  defp stop_owned_connection(%{connection: nil} = state) do
    %{state | connection_key: nil, connection_opts: nil}
  end

  defp stop_owned_connection(%{connection: connection} = state) do
    Connection.stop(connection)
    %{state | connection: nil, connection_key: nil, connection_opts: nil}
  end

  defp session_connection(%{client: client} = connection, opts) do
    %{
      connection
      | client: session_client(client, opts)
    }
    |> Map.put(:shared_server_owner, __MODULE__)
  end

  defp session_client(shared_client, opts) do
    base_url = Keyword.fetch!(shared_client, :base_url)
    client_opts = Keyword.get(opts, :client_opts, [])

    auth =
      Keyword.get(opts, :auth, Keyword.get(client_opts, :auth, Keyword.get(shared_client, :auth)))

    client_opts
    |> Keyword.put(:base_url, base_url)
    |> Keyword.put(:auth, auth)
  end

  defp schedule_health_check(%{health_interval_ms: interval_ms} = state)
       when is_integer(interval_ms) and interval_ms > 0 do
    %{state | health_timer: Process.send_after(self(), :health_check, interval_ms)}
  end

  defp schedule_health_check(state), do: state

  defp connection_key(opts) do
    {
      Keyword.get(opts, :server_module),
      Keyword.get(opts, :server_opts, []),
      Keyword.get(opts, :server_config, %{}),
      Keyword.get(opts, :auth)
    }
  end

  defp ensure_default_manager_started(__MODULE__) do
    case Process.whereis(__MODULE__) do
      nil ->
        case start_link([]) do
          {:ok, _pid} -> :ok
          {:error, {:already_started, _pid}} -> :ok
          {:error, reason} -> {:error, reason}
        end

      _pid ->
        :ok
    end
  end

  defp ensure_default_manager_started(_server), do: :ok
end
