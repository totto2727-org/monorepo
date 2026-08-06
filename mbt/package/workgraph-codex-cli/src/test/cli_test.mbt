///|
struct CodexIntegrationFixture {
  root : String
  executable : @path.Path
  records : String
}

///|
async fn codex_integration_fixture() -> CodexIntegrationFixture {
  let root = @fs.tmpdir(prefix="moon-agent-codex-integration-")
  let executable = @path.Path("\{root}/codex")
  let records = "\{root}/records"
  @fs.mkdir(records, recursive=true)
  @fs.write_file(
    executable.to_string(),
    (
      #|#!/bin/sh
      #|set -eu
      #|records="${FAKE_CODEX_RECORDS:?}"
      #|counter="$records/counter"
      #|call=0
      #|if [ -f "$counter" ]; then call=$(/bin/cat "$counter"); fi
      #|call=$((call + 1))
      #|printf '%s' "$call" > "$counter"
      #|: > "$records/args.$call"
      #|for arg in "$@"; do printf '%s\n' "$arg" >> "$records/args.$call"; done
      #|/usr/bin/env | /usr/bin/sort > "$records/env.$call"
      #|/bin/cat > "$records/input.$call"
      #|printf '%s' "$$" > "$records/pid.$call"
      #|: > "$records/started.$call"
      #|case "${FAKE_CODEX_MODE-success}" in
      #|  success)
      #|    printf '%s\n' '{"type":"thread.started","thread_id":"thread-1"}'
      #|    printf '%s\n' '{"type":"turn.started"}'
      #|    printf '%s\n' '{"type":"item.completed","item":{"id":"patch-1","type":"file_change","changes":[{"path":"src/success.mbt","kind":"update"}],"status":"completed"}}'
      #|    printf '%s\n' "{\"type\":\"item.completed\",\"item\":{\"id\":\"message-$call\",\"type\":\"agent_message\",\"text\":\"summary-$call\"}}"
      #|    printf '%s\n' '{"type":"turn.completed","usage":{"input_tokens":3,"cached_input_tokens":0,"output_tokens":2,"reasoning_output_tokens":0}}'
      #|    ;;
      #|  failed)
      #|    printf '%s\n' '{"type":"thread.started","thread_id":"thread-failed"}'
      #|    printf '%s\n' '{"type":"turn.started"}'
      #|    printf '%s\n' '{"type":"turn.failed","error":{"message":"deterministic failure"}}'
      #|    /bin/sleep 30
      #|    ;;
      #|  pause)
      #|    trap 'exit 0' TERM INT
      #|    /bin/sleep 30
      #|    : > "$records/finished.$call"
      #|    ;;
      #|esac
      #|
    ),
    create_mode=CreateOrTruncate,
  )
  @fs.chmod(executable.to_string(), 0o755)
  { root, executable, records }
}

///|
async fn with_codex_integration_fixture(
  run : async (CodexIntegrationFixture) -> Unit,
) -> String {
  let fixture = codex_integration_fixture()
  run(fixture) catch {
    error => {
      @async.protect_from_cancel(async fn() {
        @fs.rmdir(fixture.root, recursive=true)
      })
      raise error
    }
  }
  @fs.rmdir(fixture.root, recursive=true)
  fixture.root
}

///|
async fn codex_integration_text(path : String) -> String {
  @fs.read_file(path).text()
}

///|
async fn codex_integration_wait_for(path : String) -> Unit {
  @async.with_timeout(2000, async fn() {
    while !@fs.exists(path) {
      @async.pause()
    }
  })
}

///|
fn codex_integration_context(
  fixture : CodexIntegrationFixture,
  group : @async.TaskGroup[Unit],
  mode : String,
) -> @coding_agent.CodingAgentOpenContext {
  @coding_agent.CodingAgentOpenContext::CodingAgentOpenContext(
    run_id=@core.RunId::parse("codex-integration-run") catch {
      _ => abort("integration run ID must be valid")
    },
    task_group=group,
    workspace=@coding_agent.WorkspaceRef::WorkspaceRef(
      @path.Path(fixture.root),
      [@path.Path("\{fixture.root}/extra")],
    ),
    approval=@coding_agent.OnRequest,
    network=@coding_agent.Enabled,
    environment=@immut_hashmap.HashMap([
      ("PATH", "/usr/bin:/bin"),
      ("FAKE_CODEX_RECORDS", fixture.records),
      ("FAKE_CODEX_MODE", mode),
      ("MAPPED_ENV", "present"),
    ]),
    events=@core.EventSink::discard(),
  )
}

///|
fn codex_integration_agent(
  fixture : CodexIntegrationFixture,
) -> @coding_agent.CodingAgent {
  @codex.codex_agent(
    @coding_agent.CodingAgentId::CodingAgentId("codex-integration") catch {
      _ => abort("integration agent ID must be valid")
    },
    @codex.CodexAgentOptions::CodexAgentOptions(
      codex_path_override=fixture.executable,
      api_key="test-key",
      model="codex-test",
      sandbox=@codex_sdk.WorkspaceWrite,
      skip_git=true,
      reasoning=@codex_sdk.High,
      web_search=@codex_sdk.Cached,
    ),
  )
}

///|
async test "codex_agent integration 1 - starts then resumes with mapped CLI options and successful files" {
  let root = with_codex_integration_fixture(async fn(fixture) {
    @async.with_task_group() <| group => {
      let session = (codex_integration_agent(fixture).open)(
        codex_integration_context(fixture, group, "success"),
      )
      let first = session.execute(
        @coding_agent.CodingAgentRequest::CodingAgentRequest(
          "first instruction",
          [@path.Path("README.md")],
        ),
      )
      let second = session.execute(
        @coding_agent.CodingAgentRequest::CodingAgentRequest(
          "second instruction",
          [],
        ),
      )
      debug_inspect(first.summary, content="Some(\"summary-1\")")
      debug_inspect(first.continuation_id, content="Some(\"thread-1\")")
      inspect(first.changed_files[0].to_string(), content="src/success.mbt")
      debug_inspect(second.summary, content="Some(\"summary-2\")")
      debug_inspect(second.continuation_id, content="Some(\"thread-1\")")
      let first_args = codex_integration_text("\{fixture.records}/args.1")
      let second_args = codex_integration_text("\{fixture.records}/args.2")
      assert_false(first_args.contains("\nresume\n"))
      assert_true(second_args.contains("\nresume\nthread-1\n"))
      assert_true(first_args.contains("\n--model\ncodex-test\n"))
      assert_true(first_args.contains("\n--sandbox\nworkspace-write\n"))
      assert_true(first_args.contains("\n--cd\n\{fixture.root}\n"))
      assert_true(first_args.contains("\n--add-dir\n\{fixture.root}/extra\n"))
      assert_true(first_args.contains("\n--skip-git-repo-check\n"))
      assert_true(
        first_args.contains("\n--config\napproval_policy=\"on-request\"\n"),
      )
      assert_true(
        first_args.contains(
          "\n--config\nsandbox_workspace_write.network_access=true\n",
        ),
      )
      assert_true(
        codex_integration_text("\{fixture.records}/env.1").contains(
          "MAPPED_ENV=present",
        ),
      )
      assert_true(
        codex_integration_text("\{fixture.records}/input.1").contains(
          "Context files supplied by the caller:\nREADME.md",
        ),
      )
      session.close()
    }
  })
  assert_false(@fs.exists(root))
}

///|
async test "codex_agent integration 2 - propagates turn.failed without waiting for the fake process" {
  let root = with_codex_integration_fixture(async fn(fixture) {
    @async.with_task_group() <| group => {
      let session = (codex_integration_agent(fixture).open)(
        codex_integration_context(fixture, group, "failed"),
      )
      let message = try {
        @async.with_timeout(2000, async fn() {
          session.execute(
            @coding_agent.CodingAgentRequest::CodingAgentRequest("fail", []),
          )
          |> ignore
        })
        "no error"
      } catch {
        @codex_sdk.CodexSdkError::TurnFailed(message~) => message
        @async.TimeoutError => "timed out"
        error => "unexpected:\{error}"
      }
      inspect(message, content="deterministic failure")
      session.close()
    }
  })
  assert_false(@fs.exists(root))
}

///|
async test "codex_agent integration 3 - caller cancellation kills the started subprocess and leaves no finish marker" {
  let root = with_codex_integration_fixture(async fn(fixture) {
    @async.with_task_group() <| group => {
      let node_id = @core.NodeId::NodeId("codex-cancel")
      let events : Array[@core.GraphEvent] = []
      let definition = @core.GraphDefinition::GraphDefinition(
        @core.Reducer::Reducer(fn(state : Int, patch : Int) { state + patch }),
      )
      definition.add_node(
        @coding_agent.coding_agent_node(
          node_id,
          @core.NodeMetadata::NodeMetadata(
            name="codex-cancel",
            description=None,
            kind=@core.CodingAgent,
            tags=["integration"],
          ),
          @coding_agent.CodingAgentNodeSpec::CodingAgentNodeSpec(
            codex_integration_agent(fixture),
            @core.ResourceKey::parse("codex-cancel"),
            @core.Run,
            fn(context, _state) {
              codex_integration_context(fixture, context.task_group, "pause")
            },
            fn(_context, _state) {
              @coding_agent.CodingAgentRequest::CodingAgentRequest("cancel", [])
            },
            fn(_state, _response) {
              @core.NodeOutput::NodeOutput(Some(1), None)
            },
          ),
        ),
      )
      definition.set_router(
        node_id,
        @core.router([], fn(_state, _completion) { @core.End }),
      )
      definition.set_entry(node_id)
      let runtime = @core.GraphRuntime::GraphRuntime(
        definition.compile(),
        events=@core.EventSink::EventSink(fn(event) { events.push(event) }),
      )
      let task = group.spawn(
        async fn() { runtime.invoke(0) |> ignore },
        allow_failure=true,
      )
      codex_integration_wait_for("\{fixture.records}/started.1")
      let pid = codex_integration_text("\{fixture.records}/pid.1")
      task.cancel()
      let cancelled = try {
        task.wait()
        false
      } catch {
        error => @async.is_cancellation_error(error)
      }
      @async.with_timeout(2000, async fn() {
        while @process.collect_output("/bin/kill", ["-0", pid.trim().to_owned()]).0 ==
              0 {
          @async.pause()
        }
      })
      let mut run_cancelled = 0
      for event in events {
        if event is @core.RunCancelled(_) {
          run_cancelled = run_cancelled + 1
        }
      }
      inspect(cancelled, content="true")
      inspect(run_cancelled, content="1")
      assert_false(@fs.exists("\{fixture.records}/finished.1"))
    }
  })
  assert_false(@fs.exists(root))
}
