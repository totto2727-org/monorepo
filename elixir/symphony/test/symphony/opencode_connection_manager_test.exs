# このファイルは元のApache 2.0ライセンスのコードから新規に追加されています
# 変更日: 2026-07-04
# 変更者: totto2727
# 変更内容: OpenCode 共有 ConnectionManager の再利用と health check restart のテストを追加

defmodule Symphony.OpencodeConnectionManagerTest do
  use ExUnit.Case, async: false

  alias Symphony.Opencode.ConnectionManager
  alias Symphony.OpencodeConnectionManagerTest.{ErrorHealthApi, HealthyApi, UnhealthyApi}
  alias Symphony.OpencodeFakes.Server

  test "connection starts one local server and reuses it for matching local options" do
    manager = start_connection_manager!(health_api: HealthyApi)
    opts = connection_opts("http://127.0.0.1:4991")

    assert {:ok, connection1} = ConnectionManager.connection(opts, manager)
    assert_received {:opencode_server_start, _server_opts}

    assert {:ok, connection2} = ConnectionManager.connection(opts, manager)
    refute_received {:opencode_server_start, _server_opts}

    assert Keyword.get(connection1.client, :base_url) == "http://127.0.0.1:4991"
    assert Keyword.get(connection2.client, :base_url) == "http://127.0.0.1:4991"
    assert connection1.server == connection2.server
    assert connection2.shared_server_owner == ConnectionManager
  end

  test "health_check keeps healthy shared server running" do
    manager = start_connection_manager!(health_api: HealthyApi)
    opts = connection_opts("http://127.0.0.1:4992")

    assert {:ok, _connection} = ConnectionManager.connection(opts, manager)
    assert_received {:opencode_server_start, _server_opts}

    assert :ok = ConnectionManager.health_check(manager)

    assert_received {:opencode_health_check, client}
    assert Keyword.get(client, :base_url) == "http://127.0.0.1:4992"
    refute_received {:opencode_server_stop, _server}
    refute_received {:opencode_server_start, _server_opts}
  end

  test "health_check restarts shared server after unhealthy response" do
    manager = start_connection_manager!(health_api: UnhealthyApi)
    opts = connection_opts("http://127.0.0.1:4993")

    assert {:ok, _connection} = ConnectionManager.connection(opts, manager)
    assert_received {:opencode_server_start, _server_opts}

    assert :ok = ConnectionManager.health_check(manager)

    assert_received {:opencode_health_check, client}
    assert Keyword.get(client, :base_url) == "http://127.0.0.1:4993"
    assert_received {:opencode_server_stop, %{url: "http://127.0.0.1:4993"}}
    assert_received {:opencode_server_start, restart_opts}
    assert Keyword.get(restart_opts, :config) == %{}
  end

  test "health_check restarts shared server after health API error" do
    manager = start_connection_manager!(health_api: ErrorHealthApi)
    opts = connection_opts("http://127.0.0.1:4994")

    assert {:ok, _connection} = ConnectionManager.connection(opts, manager)
    assert_received {:opencode_server_start, _server_opts}

    assert :ok = ConnectionManager.health_check(manager)

    assert_received {:opencode_health_check, client}
    assert Keyword.get(client, :base_url) == "http://127.0.0.1:4994"
    assert_received {:opencode_server_stop, %{url: "http://127.0.0.1:4994"}}
    assert_received {:opencode_server_start, _restart_opts}
  end

  defp start_connection_manager!(opts) do
    name = Module.concat(__MODULE__, "Manager#{System.unique_integer([:positive])}")

    start_supervised!(
      {ConnectionManager, Keyword.merge([name: name, health_interval_ms: nil], opts)},
      id: name
    )

    name
  end

  defp connection_opts(url) do
    [
      client_opts: [test_pid: self()],
      server_module: Server,
      server_opts: [test_pid: self(), url: url]
    ]
  end

  defmodule HealthyApi do
    @moduledoc false

    @spec global_health(keyword()) :: {:ok, map()}
    def global_health(client) do
      notify(client)
      {:ok, %{healthy: true}}
    end

    defp notify(client) do
      case Keyword.get(client, :test_pid) do
        pid when is_pid(pid) -> send(pid, {:opencode_health_check, client})
        _ -> :ok
      end
    end
  end

  defmodule UnhealthyApi do
    @moduledoc false

    @spec global_health(keyword()) :: {:ok, map()}
    def global_health(client) do
      notify(client)
      {:ok, %{healthy: false}}
    end

    defp notify(client) do
      case Keyword.get(client, :test_pid) do
        pid when is_pid(pid) -> send(pid, {:opencode_health_check, client})
        _ -> :ok
      end
    end
  end

  defmodule ErrorHealthApi do
    @moduledoc false

    @spec global_health(keyword()) :: {:error, atom()}
    def global_health(client) do
      notify(client)
      {:error, :unreachable}
    end

    defp notify(client) do
      case Keyword.get(client, :test_pid) do
        pid when is_pid(pid) -> send(pid, {:opencode_health_check, client})
        _ -> :ok
      end
    end
  end
end
