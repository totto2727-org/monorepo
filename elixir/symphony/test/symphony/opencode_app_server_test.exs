# このファイルは元のApache 2.0ライセンスのコードから新規に追加されています
# 変更日: 2026-06-28
# 変更者: totto2727
# 変更内容: Symphony OpenCode AppServer と opencode_client lifecycle 連携のテストを追加

defmodule Symphony.OpencodeAppServerTest do
  use Symphony.TestSupport

  alias Symphony.Opencode.AppServer
  alias Symphony.Opencode.ConnectionManager
  alias Symphony.OpencodeFakes.{EventStream, Server, SessionApi}

  test "app server uses opencode_client server, session API, event stream, and cleanup lifecycle" do
    test_root =
      Path.join(
        System.tmp_dir!(),
        "symphony-opencode-app-server-lifecycle-#{System.unique_integer([:positive])}"
      )

    try do
      workspace_root = Path.join(test_root, "workspaces")
      workspace = Path.join(workspace_root, "MT-OC-1")
      File.mkdir_p!(workspace)

      write_workflow_file!(Workflow.workflow_file_path(), workspace_root: workspace_root)

      issue = %Issue{
        id: "issue-opencode-lifecycle",
        identifier: "MT-OC-1",
        title: "Validate OpenCode lifecycle",
        description: "Exercise generated OpenCode client path",
        state: "In Progress"
      }

      manager = start_connection_manager!()

      assert {:ok, %{session_id: "ses_lifecycle"}} =
               AppServer.run(workspace, "Use OpenCode", issue,
                 client_opts: [test_pid: self(), session_id: "ses_lifecycle"],
                 connection_manager: manager,
                 event_stream: EventStream,
                 server_module: Server,
                 server_opts: [test_pid: self(), url: "http://127.0.0.1:4999"],
                 session_api: SessionApi,
                 turn_timeout_ms: 1_000
               )

      assert_received {:opencode_server_start, server_opts}
      assert Keyword.get(server_opts, :config) == %{}

      assert_received {:opencode_session_create, body, create_opts}
      assert {:ok, canonical_workspace} = Symphony.PathSafety.canonicalize(workspace)
      assert body == %{title: "Symphony agent run"}
      assert Keyword.get(create_opts, :directory) == canonical_workspace
      assert Keyword.get(create_opts, :base_url) == "http://127.0.0.1:4999"

      assert_received {:opencode_prompt_async, "ses_lifecycle", prompt_body, prompt_opts}
      assert prompt_body == %{parts: [%{type: "text", text: "Use OpenCode"}]}
      assert Keyword.get(prompt_opts, :directory) == canonical_workspace

      assert_received {:opencode_session_delete, "ses_lifecycle", delete_opts}
      assert Keyword.get(delete_opts, :directory) == canonical_workspace
      refute_received {:opencode_server_stop, %{url: "http://127.0.0.1:4999"}}
    after
      File.rm_rf(test_root)
    end
  end

  test "app server reuses one local server across multiple sessions and does not stop it per session" do
    test_root =
      Path.join(
        System.tmp_dir!(),
        "symphony-opencode-app-server-shared-server-#{System.unique_integer([:positive])}"
      )

    try do
      workspace_root = Path.join(test_root, "workspaces")
      workspace = Path.join(workspace_root, "MT-OC-SHARED")
      File.mkdir_p!(workspace)

      write_workflow_file!(Workflow.workflow_file_path(), workspace_root: workspace_root)
      manager = start_connection_manager!()

      assert {:ok, session1} =
               AppServer.start_session(workspace,
                 client_opts: [test_pid: self(), session_id: "ses_shared_1"],
                 connection_manager: manager,
                 event_stream: EventStream,
                 server_module: Server,
                 server_opts: [test_pid: self(), url: "http://127.0.0.1:4997"],
                 session_api: SessionApi
               )

      assert_received {:opencode_server_start, _server_opts}

      assert {:ok, session2} =
               AppServer.start_session(workspace,
                 client_opts: [test_pid: self(), session_id: "ses_shared_2"],
                 connection_manager: manager,
                 event_stream: EventStream,
                 server_module: Server,
                 server_opts: [test_pid: self(), url: "http://127.0.0.1:4997"],
                 session_api: SessionApi
               )

      refute_received {:opencode_server_start, _server_opts}

      assert :ok = AppServer.stop_session(session1)
      assert_received {:opencode_session_delete, "ses_shared_1", _client}
      refute_received {:opencode_server_stop, _server}

      assert :ok = AppServer.stop_session(session2)
      assert_received {:opencode_session_delete, "ses_shared_2", _client}
      refute_received {:opencode_server_stop, _server}
    after
      File.rm_rf(test_root)
    end
  end

  test "app server prompt opts make git operations target the issue workspace" do
    test_root =
      Path.join(
        System.tmp_dir!(),
        "symphony-opencode-app-server-git-cwd-#{System.unique_integer([:positive])}"
      )

    try do
      workspace_root = Path.join(test_root, "workspaces")
      workspace = Path.join(workspace_root, "MT-OC-GIT")
      File.mkdir_p!(workspace)

      assert {_, 0} = System.cmd("git", ["-C", workspace, "init", "-b", "main"])
      assert {_, 0} = System.cmd("git", ["-C", workspace, "config", "user.name", "Test User"])

      assert {_, 0} =
               System.cmd("git", ["-C", workspace, "config", "user.email", "test@example.com"])

      File.write!(Path.join(workspace, "README.md"), "# workspace\n")
      assert {_, 0} = System.cmd("git", ["-C", workspace, "add", "README.md"])
      assert {_, 0} = System.cmd("git", ["-C", workspace, "commit", "-m", "initial"])

      write_workflow_file!(Workflow.workflow_file_path(), workspace_root: workspace_root)

      issue = %Issue{
        id: "issue-opencode-git-cwd",
        identifier: "MT-OC-GIT",
        title: "Validate OpenCode git cwd",
        description: "Exercise generated OpenCode directory query opts",
        state: "In Progress"
      }

      manager = start_connection_manager!()

      assert {:ok, %{session_id: "ses_git_cwd"}} =
               AppServer.run(workspace, "Check git cwd", issue,
                 client_opts: [
                   test_pid: self(),
                   session_id: "ses_git_cwd",
                   assert_git_toplevel: true
                 ],
                 connection_manager: manager,
                 event_stream: EventStream,
                 server_module: Server,
                 server_opts: [test_pid: self(), url: "http://127.0.0.1:4995"],
                 session_api: SessionApi,
                 turn_timeout_ms: 1_000
               )

      assert {:ok, canonical_workspace} = Symphony.PathSafety.canonicalize(workspace)
      assert_received {:opencode_git_toplevel, ^canonical_workspace, ^canonical_workspace}
    after
      File.rm_rf(test_root)
    end
  end

  test "app server preserves explicit base_url without starting a local server" do
    test_root =
      Path.join(
        System.tmp_dir!(),
        "symphony-opencode-app-server-explicit-base-url-#{System.unique_integer([:positive])}"
      )

    try do
      workspace_root = Path.join(test_root, "workspaces")
      workspace = Path.join(workspace_root, "MT-OC-BASEURL")
      File.mkdir_p!(workspace)

      write_workflow_file!(Workflow.workflow_file_path(), workspace_root: workspace_root)

      assert {:ok, session} =
               AppServer.start_session(workspace,
                 base_url: "http://127.0.0.1:4996",
                 client_opts: [test_pid: self(), session_id: "ses_base_url"],
                 event_stream: EventStream,
                 server_module: Server,
                 server_opts: [test_pid: self(), url: "http://127.0.0.1:4996"],
                 session_api: SessionApi
               )

      assert_received {:opencode_session_create, _body, client}
      assert Keyword.get(client, :base_url) == "http://127.0.0.1:4996"
      refute_received {:opencode_server_start, _server_opts}

      assert :ok = AppServer.stop_session(session)

      assert_received {:opencode_session_delete, "ses_base_url", _client}
      refute_received {:opencode_server_stop, _server}
    after
      File.rm_rf(test_root)
    end
  end

  test "app server rejects remote workers without a base_url" do
    test_root =
      Path.join(
        System.tmp_dir!(),
        "symphony-opencode-app-server-remote-no-base-url-#{System.unique_integer([:positive])}"
      )

    try do
      workspace = Path.join(test_root, "remote-workspace")
      File.mkdir_p!(test_root)

      assert {:error, {:opencode_remote_worker_requires_base_url, "worker-1"}} =
               AppServer.start_session(workspace,
                 client_opts: [test_pid: self()],
                 event_stream: EventStream,
                 session_api: SessionApi,
                 worker_host: "worker-1"
               )

      refute_received {:opencode_session_create, _body, _client}
      refute_received {:opencode_server_start, _server_opts}
      refute_received {:opencode_server_stop, _server}
    after
      File.rm_rf(test_root)
    end
  end

  test "app server passes workflow opencode model to local server config" do
    test_root =
      Path.join(
        System.tmp_dir!(),
        "symphony-opencode-app-server-model-#{System.unique_integer([:positive])}"
      )

    try do
      workspace_root = Path.join(test_root, "workspaces")
      workspace = Path.join(workspace_root, "MT-OC-MODEL")
      File.mkdir_p!(workspace)

      write_workflow_file!(Workflow.workflow_file_path(),
        workspace_root: workspace_root,
        opencode_model: "openai/gpt-5.5"
      )

      issue = %Issue{
        id: "issue-opencode-model",
        identifier: "MT-OC-MODEL",
        title: "Validate OpenCode model config",
        description: "Exercise workflow model forwarding",
        state: "In Progress"
      }

      manager = start_connection_manager!()

      assert {:ok, %{session_id: "ses_model"}} =
               AppServer.run(workspace, "Use configured model", issue,
                 client_opts: [test_pid: self(), session_id: "ses_model"],
                 connection_manager: manager,
                 event_stream: EventStream,
                 server_module: Server,
                 server_opts: [test_pid: self(), url: "http://127.0.0.1:4998"],
                 session_api: SessionApi,
                 turn_timeout_ms: 1_000
               )

      assert_received {:opencode_server_start, server_opts}
      assert Keyword.get(server_opts, :config) == %{model: "openai/gpt-5.5"}
    after
      File.rm_rf(test_root)
    end
  end

  test "app server ignores SSE lifecycle events for other sessions" do
    test_root =
      Path.join(
        System.tmp_dir!(),
        "symphony-opencode-app-server-session-filter-#{System.unique_integer([:positive])}"
      )

    try do
      workspace_root = Path.join(test_root, "workspaces")
      workspace = Path.join(workspace_root, "MT-OC-2")
      File.mkdir_p!(workspace)

      write_workflow_file!(Workflow.workflow_file_path(), workspace_root: workspace_root)

      issue = %Issue{
        id: "issue-opencode-session-filter",
        identifier: "MT-OC-2",
        title: "Filter OpenCode session events",
        description: "Ignore unrelated global SSE events",
        state: "In Progress"
      }

      events = [
        EventStream.idle_event("ses_other"),
        EventStream.idle_event("ses_target")
      ]

      manager = start_connection_manager!()

      assert {:ok, %{session_id: "ses_target"}} =
               AppServer.run(workspace, "Use OpenCode", issue,
                 client_opts: [events: events, session_id: "ses_target"],
                 connection_manager: manager,
                 event_stream: EventStream,
                 server_module: Server,
                 server_opts: [url: "http://127.0.0.1:4999"],
                 session_api: SessionApi,
                 turn_timeout_ms: 1_000
               )
    after
      File.rm_rf(test_root)
    end
  end

  test "app server rejects unsafe local workspace paths before creating OpenCode sessions" do
    test_root =
      Path.join(
        System.tmp_dir!(),
        "symphony-opencode-app-server-cwd-guard-#{System.unique_integer([:positive])}"
      )

    try do
      workspace_root = Path.join(test_root, "workspaces")
      outside_workspace = Path.join(test_root, "outside")
      File.mkdir_p!(workspace_root)
      File.mkdir_p!(outside_workspace)

      write_workflow_file!(Workflow.workflow_file_path(), workspace_root: workspace_root)

      assert {:error, {:invalid_workspace_cwd, :workspace_root, _path}} =
               AppServer.start_session(workspace_root,
                 base_url: "http://127.0.0.1:4999",
                 client_opts: [test_pid: self()],
                 event_stream: EventStream,
                 session_api: SessionApi
               )

      assert {:error, {:invalid_workspace_cwd, :outside_workspace_root, _path, _root}} =
               AppServer.start_session(outside_workspace,
                 base_url: "http://127.0.0.1:4999",
                 client_opts: [test_pid: self()],
                 event_stream: EventStream,
                 session_api: SessionApi
               )

      refute_received {:opencode_session_create, _body, _client}
    after
      File.rm_rf(test_root)
    end
  end

  defp start_connection_manager! do
    name = Module.concat(__MODULE__, "Manager#{System.unique_integer([:positive])}")

    start_supervised!(
      {ConnectionManager, name: name, health_interval_ms: nil},
      id: name
    )

    name
  end
end
