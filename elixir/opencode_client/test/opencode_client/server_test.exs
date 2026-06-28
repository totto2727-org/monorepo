defmodule OpencodeClient.ServerTest do
  use ExUnit.Case

  describe "module interface" do
    test "exports server lifecycle functions" do
      assert {:module, OpencodeClient.Server} = Code.ensure_loaded(OpencodeClient.Server)
      assert function_exported?(OpencodeClient.Server, :start, 1)
      assert function_exported?(OpencodeClient.Server, :start_link, 1)
      assert function_exported?(OpencodeClient.Server, :url, 1)
      assert function_exported?(OpencodeClient.Server, :stop, 1)
    end
  end

  describe "with fake opencode binary" do
    setup do
      tmp_dir = Path.join(System.tmp_dir!(), "opencode_client_test_#{System.unique_integer([:positive])}")
      File.mkdir_p!(tmp_dir)
      fake_bin = Path.join(tmp_dir, "opencode")

      script = """
      #!/bin/sh
      echo "opencode server listening on http://127.0.0.1:9999"
      sleep 60
      """

      File.write!(fake_bin, script)
      File.chmod!(fake_bin, 0o755)

      original_path = System.get_env("PATH")
      System.put_env("PATH", tmp_dir <> ":" <> original_path)

      on_exit(fn ->
        System.put_env("PATH", original_path)
        File.rm_rf!(tmp_dir)
      end)

      :ok
    end

    test "starts server, returns url, and stops cleanly" do
      assert {:ok, server} = OpencodeClient.Server.start(port: 9999, timeout: 3_000)
      assert "http://127.0.0.1:9999" = OpencodeClient.Server.url(server)
      assert :ok = OpencodeClient.Server.stop(server)
    end

    test "start_link returns linked server" do
      assert {:ok, server} = OpencodeClient.Server.start_link(port: 9999, timeout: 3_000)
      assert "http://127.0.0.1:9999" = OpencodeClient.Server.url(server)
      assert :ok = OpencodeClient.Server.stop(server)
    end
  end

  describe "without opencode in PATH" do
    setup do
      original_path = System.get_env("PATH")
      System.put_env("PATH", "")
      on_exit(fn -> System.put_env("PATH", original_path) end)
      :ok
    end

    test "returns opencode_not_found error" do
      assert {:error, :opencode_not_found} = OpencodeClient.Server.start()
    end
  end
end
