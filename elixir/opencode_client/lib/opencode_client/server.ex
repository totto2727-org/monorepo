defmodule OpencodeClient.Server do
  @moduledoc """
  Spawns and manages an `opencode serve` subprocess, mirroring the TypeScript SDK's
  `createOpencodeServer()` behaviour.

  Usage:

      {:ok, server} = OpencodeClient.Server.start(hostname: "127.0.0.1", port: 4096)
      url = OpencodeClient.Server.url(server)
      # ... use the OpenCode HTTP client against `url` ...
      OpencodeClient.Server.stop(server)

  The server process is a `GenServer` that owns the Erlang `Port`.  If the GenServer
  crashes or is stopped, the port is closed and the `opencode` subprocess is terminated
  automatically.
  """

  use GenServer

  @default_hostname "127.0.0.1"
  @default_port 4096
  @default_timeout 5_000

  defmodule State do
    @moduledoc false
    defstruct [
      :port,
      :url,
      :buffer,
      :opts,
      :start_ref,
      :waiting_pid,
      :start_timer
    ]
  end

  @spec start(keyword()) :: GenServer.on_start()
  def start(opts \\ []) do
    GenServer.start(__MODULE__, opts)
  end

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts)
  end

  @spec url(GenServer.server()) :: String.t()
  def url(server) do
    GenServer.call(server, :get_url, :infinity)
  end

  @spec stop(GenServer.server()) :: :ok
  def stop(server) do
    GenServer.stop(server, :normal)
  end

  @impl GenServer
  def init(opts) do
    hostname = Keyword.get(opts, :hostname, @default_hostname)
    port_num = Keyword.get(opts, :port, @default_port)
    timeout = Keyword.get(opts, :timeout, @default_timeout)
    config = Keyword.get(opts, :config, %{})

    executable = System.find_executable("opencode")

    if is_nil(executable) do
      {:stop, :opencode_not_found}
    else
      port =
        Port.open(
          {:spawn_executable, String.to_charlist(executable)},
          [
            :binary,
            :exit_status,
            :stderr_to_stdout,
            args: Enum.map(build_args(hostname, port_num, config), &String.to_charlist/1),
            env: build_env(config)
          ]
        )

      timer = Process.send_after(self(), :startup_timeout, timeout)

      {:ok,
       %State{
         port: port,
         url: nil,
         buffer: "",
         opts: opts,
         start_ref: make_ref(),
         waiting_pid: nil,
         start_timer: timer
       }}
    end
  end

  @impl GenServer
  def handle_call(:get_url, from, %{url: nil} = state) do
    {:noreply, %{state | waiting_pid: from}}
  end

  def handle_call(:get_url, _from, %{url: url} = state) do
    {:reply, url, state}
  end

  @impl GenServer
  def handle_info({port, {:data, data}}, %{port: port} = state) when is_port(port) do
    buffer = state.buffer <> data
    lines = String.split(buffer, "\n")

    case find_listening_url(lines) do
      {:ok, url} ->
        cancel_timer(state.start_timer)
        new_state = %{state | url: url, buffer: ""}

        if state.waiting_pid do
          GenServer.reply(state.waiting_pid, url)
        end

        {:noreply, %{new_state | waiting_pid: nil}}

      :not_found ->
        {:noreply, %{state | buffer: List.last(lines) || ""}}
    end
  end

  def handle_info({port, {:exit_status, status}}, %{port: port} = state) when is_port(port) do
    cancel_timer(state.start_timer)

    if state.waiting_pid do
      GenServer.reply(state.waiting_pid, {:error, {:server_exited, status, state.buffer}})
    end

    {:stop, {:shutdown, build_exit_message(status, state.buffer)}, state}
  end

  def handle_info(:startup_timeout, state) do
    stop_port(state.port)

    if state.waiting_pid do
      GenServer.reply(state.waiting_pid, {:error, {:timeout, state.buffer}})
    end

    {:stop, {:shutdown, :startup_timeout}, state}
  end

  @impl GenServer
  def terminate(_reason, state) do
    stop_port(state.port)
    :ok
  end

  defp build_args(hostname, port_num, config) do
    base = [
      "serve",
      "--hostname=#{hostname}",
      "--port=#{port_num}"
    ]

    case config[:log_level] do
      nil -> base
      level -> base ++ ["--log-level=#{level}"]
    end
  end

  defp build_env(config) do
    case Jason.encode(config) do
      {:ok, json} -> [{~c"OPENCODE_CONFIG_CONTENT", String.to_charlist(json)}]
      _ -> []
    end
  end

  defp find_listening_url(lines) do
    Enum.find_value(lines, fn line ->
      if String.starts_with?(line, "opencode server listening") do
        case Regex.run(~r/on\s+(https?:\/\/[^\s]+)/, line) do
          [_, url] -> {:ok, url}
          _ -> {:error, :url_parse_failed}
        end
      end
    end) || :not_found
  end

  defp stop_port(port) when is_port(port) do
    Port.close(port)
  end

  defp cancel_timer(nil), do: :ok
  defp cancel_timer(timer), do: Process.cancel_timer(timer)

  defp build_exit_message(status, ""), do: "OpenCode server exited with code #{status}"

  defp build_exit_message(status, buffer),
    do: "OpenCode server exited with code #{status}\nServer output:\n" <> buffer
end
