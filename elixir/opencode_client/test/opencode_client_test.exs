defmodule OpencodeClientTest do
  use ExUnit.Case

  describe "generated OpenAPI client" do
    test "exports generated session operations" do
      assert {:module, OpencodeClient.Generated.Session} =
               Code.ensure_loaded(OpencodeClient.Generated.Session)

      assert function_exported?(OpencodeClient.Generated.Session, :session_create, 2)
      assert function_exported?(OpencodeClient.Generated.Session, :session_prompt_async, 3)
      assert function_exported?(OpencodeClient.Generated.Session, :session_delete, 2)
    end

    test "provides generated client transport" do
      assert {:module, OpencodeClient.Client} = Code.ensure_loaded(OpencodeClient.Client)

      assert function_exported?(OpencodeClient.Client, :request, 1)
    end

    test "provides SSE event stream backed by ReqServerSentEvents" do
      assert {:module, OpencodeClient.EventStream} =
               Code.ensure_loaded(OpencodeClient.EventStream)

      assert function_exported?(OpencodeClient.EventStream, :stream, 1)

      frame =
        ReqServerSentEvents.Frame.parse(~s(event: session.idle\ndata: {"type":"session.idle"}))

      assert %{event: "session.idle", data: ~s({"type":"session.idle"})} = frame
    end

    test "passes workspace location query params to the SSE endpoint" do
      {:ok, server} = __MODULE__.EventServer.start(self())

      assert {:ok, events} =
               OpencodeClient.EventStream.stream(
                 auth: :none,
                 base_url: __MODULE__.EventServer.url(server),
                 directory: "/tmp/symphony workspace",
                 receive_timeout: 1_000,
                 workspace: "workspace-id"
               )

      assert [%{type: "session.idle"}] = Enum.take(events, 1)

      assert_receive {:event_server_request_path, path}, 1_000
      assert path =~ "/event?"
      assert path =~ "directory=%2Ftmp%2Fsymphony+workspace"
      assert path =~ "workspace=workspace-id"
    end
  end

  describe "OpenCode connection lifecycle" do
    test "builds generated-client opts from an existing base URL" do
      assert {:ok, connection} =
               OpencodeClient.Connection.start(
                 auth: {:bearer, "token"},
                 base_url: "http://127.0.0.1:5001",
                 client_opts: [test_pid: self()]
               )

      assert connection.server == nil
      assert Keyword.get(connection.client, :base_url) == "http://127.0.0.1:5001"
      assert Keyword.get(connection.client, :auth) == {:bearer, "token"}
      assert Keyword.get(connection.client, :test_pid) == self()

      assert OpencodeClient.Connection.metadata(connection).opencode_base_url ==
               "http://127.0.0.1:5001"
    end

    test "starts a local OpenCode server when no base URL is configured" do
      assert {:ok, connection} =
               OpencodeClient.Connection.start(
                 base_url: nil,
                 server_config: %{log_level: "debug"},
                 server_module: OpencodeClientTest.FakeServer,
                 server_opts: [test_pid: self(), url: "http://127.0.0.1:5002"]
               )

      assert_receive {:fake_opencode_server_start, start_opts}
      assert Keyword.get(start_opts, :config) == %{log_level: "debug"}
      assert Keyword.get(connection.client, :base_url) == "http://127.0.0.1:5002"
      assert :ok = OpencodeClient.Connection.stop(connection)
      assert_receive {:fake_opencode_server_stop, %{url: "http://127.0.0.1:5002"}}
    end

    test "requires a base URL when local server startup is disabled" do
      assert {:error, :opencode_base_url_required} =
               OpencodeClient.Connection.start(allow_server_start: false, base_url: nil)
    end
  end
end

defmodule OpencodeClientTest.EventServer do
  @moduledoc false

  defstruct [:listen_socket, :port, :task]

  def start(test_pid) do
    {:ok, listen_socket} =
      :gen_tcp.listen(0, [:binary, active: false, packet: :raw, reuseaddr: true])

    {:ok, {_address, port}} = :inet.sockname(listen_socket)

    task =
      Task.async(fn ->
        {:ok, socket} = :gen_tcp.accept(listen_socket)
        :gen_tcp.close(listen_socket)

        {:ok, request} = :gen_tcp.recv(socket, 0, 1_000)
        [request_line | _headers] = String.split(request, "\r\n")
        ["GET", path, "HTTP/1.1"] = String.split(request_line, " ")
        send(test_pid, {:event_server_request_path, path})

        :ok =
          :gen_tcp.send(socket, [
            "HTTP/1.1 200 OK\r\n",
            "content-type: text/event-stream\r\n",
            "connection: close\r\n",
            "\r\n",
            "event: session.idle\n",
            ~s(data: {"type":"session.idle"}),
            "\n\n"
          ])

        :gen_tcp.close(socket)
      end)

    {:ok, %__MODULE__{listen_socket: listen_socket, port: port, task: task}}
  end

  def url(%__MODULE__{port: port}), do: "http://127.0.0.1:#{port}"
end

defmodule OpencodeClientTest.FakeServer do
  @moduledoc false

  def start(opts) do
    server = %{test_pid: Keyword.get(opts, :test_pid), url: Keyword.fetch!(opts, :url)}
    notify(server, {:fake_opencode_server_start, opts})
    {:ok, server}
  end

  def url(%{url: url}), do: url

  def stop(server) do
    notify(server, {:fake_opencode_server_stop, server})
    :ok
  end

  defp notify(%{test_pid: pid}, message) when is_pid(pid), do: send(pid, message)
  defp notify(_server, _message), do: :ok
end
