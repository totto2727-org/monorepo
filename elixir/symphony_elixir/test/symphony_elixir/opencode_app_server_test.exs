# このファイルは元のApache 2.0ライセンスのコードから新規に追加されています
# 変更日: 2026-06-28
# 変更者: totto2727
# 変更内容: Symphony OpenCode AppServer と opencode_client lifecycle 連携のテストを追加

defmodule SymphonyElixir.OpencodeAppServerTest do
  use SymphonyElixir.TestSupport

  alias SymphonyElixir.Opencode.AppServer
  alias SymphonyElixir.OpencodeFakes.{EventStream, Server, SessionApi}

  test "app server uses opencode_client server, session API, event stream, and cleanup lifecycle" do
    test_root =
      Path.join(
        System.tmp_dir!(),
        "symphony-elixir-opencode-app-server-lifecycle-#{System.unique_integer([:positive])}"
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

      assert {:ok, %{session_id: "ses_lifecycle"}} =
               AppServer.run(workspace, "Use OpenCode", issue,
                 client_opts: [test_pid: self(), session_id: "ses_lifecycle"],
                 event_stream: EventStream,
                 server_module: Server,
                 server_opts: [test_pid: self(), url: "http://127.0.0.1:4999"],
                 session_api: SessionApi,
                 turn_timeout_ms: 1_000
               )

      assert_received {:opencode_server_start, server_opts}
      assert Keyword.get(server_opts, :config) == %{}

      assert_received {:opencode_session_create, body, client}
      assert {:ok, canonical_workspace} = SymphonyElixir.PathSafety.canonicalize(workspace)
      assert body.title == "Symphony agent run"
      assert body.directory == canonical_workspace
      assert Keyword.get(client, :base_url) == "http://127.0.0.1:4999"

      assert_received {:opencode_prompt_async, "ses_lifecycle", prompt_body, _client}
      assert prompt_body == %{parts: [%{type: "text", text: "Use OpenCode"}]}

      assert_received {:opencode_session_delete, "ses_lifecycle", _client}
      assert_received {:opencode_server_stop, %{url: "http://127.0.0.1:4999"}}
    after
      File.rm_rf(test_root)
    end
  end

  test "app server ignores SSE lifecycle events for other sessions" do
    test_root =
      Path.join(
        System.tmp_dir!(),
        "symphony-elixir-opencode-app-server-session-filter-#{System.unique_integer([:positive])}"
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

      assert {:ok, %{session_id: "ses_target"}} =
               AppServer.run(workspace, "Use OpenCode", issue,
                 client_opts: [events: events, session_id: "ses_target"],
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
        "symphony-elixir-opencode-app-server-cwd-guard-#{System.unique_integer([:positive])}"
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
end
