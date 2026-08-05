///|
fn codex_agent_test_run_id() -> @core.RunId {
  @core.RunId::parse("codex-agent-test-run") catch {
    _ => abort("test run ID must be valid")
  }
}

///|
fn codex_agent_test_id() -> @core.CodingAgentId {
  @core.CodingAgentId::parse("codex-agent-test") catch {
    _ => abort("test coding-agent ID must be valid")
  }
}

///|
fn codex_agent_test_context(
  group : @async.TaskGroup[Unit],
  environment : Map[String, String],
) -> @core.CodingAgentOpenContext {
  @core.CodingAgentOpenContext::CodingAgentOpenContext(
    run_id=codex_agent_test_run_id(),
    task_group=group,
    workspace=@core.WorkspaceRef::WorkspaceRef(@path.Path("/workspace"), [
      @path.Path("/workspace/extra"),
    ]),
    approval=@core.OnRequest,
    network=@core.Enabled,
    environment=@immut_hashmap.HashMap(environment.to_array()),
    events=@core.EventSink::discard(),
  )
}

///|
async fn with_fake_codex(
  events : String,
  run : async (@path.Path, Map[String, String], String) -> Unit,
) -> Unit {
  let root = @fs.tmpdir(prefix="moon-agent-graph-codex-test-")
  let executable = @path.Path(root).join("codex")
  let input_path = "\{root}/input"
  let script =
    #|#!/bin/sh
    #|/bin/cat > "$FAKE_CODEX_INPUT"
    #|printf '%s\n' "$FAKE_CODEX_EVENTS"
    #|
  @fs.write_file(executable.to_string(), script, create_mode=CreateOrTruncate)
  @fs.chmod(executable.to_string(), 0o755)
  let environment = {
    "PATH": "/usr/bin:/bin",
    "FAKE_CODEX_EVENTS": events,
    "FAKE_CODEX_INPUT": input_path,
  }
  run(executable, environment, input_path) catch {
    error => {
      @async.protect_from_cancel(async fn() { @fs.rmdir(root, recursive=true) })
      raise error
    }
  }
  @fs.rmdir(root, recursive=true)
}

///|
fn successful_events() -> String {
  [
    "{\"type\":\"thread.started\",\"thread_id\":\"thread-42\"}", "{\"type\":\"turn.started\"}",
    "{\"type\":\"item.completed\",\"item\":{\"id\":\"patch-1\",\"type\":\"file_change\",\"changes\":[{\"path\":\"src/new.mbt\",\"kind\":\"add\"},{\"path\":\"src/old.mbt\",\"kind\":\"delete\"}],\"status\":\"completed\"}}",
    "{\"type\":\"item.completed\",\"item\":{\"id\":\"message-1\",\"type\":\"agent_message\",\"text\":\"completed response\"}}",
    "{\"type\":\"turn.completed\",\"usage\":{\"input_tokens\":1,\"cached_input_tokens\":0,\"output_tokens\":2,\"reasoning_output_tokens\":0}}",
  ].join("\n")
}

///|
test "codex_agent 1 - retains public adapter options" {
  let options = CodexAgentOptions::CodexAgentOptions(
    resume_thread_id="thread-existing",
    model="gpt-5",
    sandbox=@sdk.WorkspaceWrite,
    skip_git=true,
    reasoning=@sdk.High,
    web_search=@sdk.Live,
  )
  debug_inspect(options.resume_thread_id, content="Some(\"thread-existing\")")
  debug_inspect(options.model, content="Some(\"gpt-5\")")
  debug_inspect(options.sandbox, content="Some(WorkspaceWrite)")
  debug_inspect(options.skip_git, content="Some(true)")
  debug_inspect(options.reasoning, content="Some(High)")
  debug_inspect(options.web_search, content="Some(Live)")
}

///|
async test "codex_agent 2 - maps request context and normalizes a successful SDK turn" {
  with_fake_codex(successful_events(), async fn(
    executable,
    environment,
    input_path,
  ) {
    @async.with_task_group() <| group => {
      let agent = codex_agent(
        codex_agent_test_id(),
        CodexAgentOptions::CodexAgentOptions(codex_path_override=executable),
      )
      let session = (agent.open)(codex_agent_test_context(group, environment))
      let response = session.execute(
        @core.CodingAgentRequest::CodingAgentRequest("apply the patch", [
          @path.Path("README.md"),
        ]),
      )
      debug_inspect(response.status, content="Succeeded")
      debug_inspect(response.summary, content="Some(\"completed response\")")
      debug_inspect(response.continuation_id, content="Some(\"thread-42\")")
      inspect(
        response.changed_files.map(fn(path) { path.to_string() }).join(","),
        content="src/new.mbt,src/old.mbt",
      )
      inspect(response.artifacts.length(), content="0")
      debug_inspect(response.raw_output, content="None")
      inspect(
        @fs.read_file(input_path).text(),
        content="apply the patch\n\nContext files supplied by the caller:\nREADME.md",
      )
      session.close()
    }
  })
}

///|
async test "codex_agent 3 - keeps unproven file changes empty" {
  with_fake_codex(
    [
      "{\"type\":\"thread.started\",\"thread_id\":\"thread-unproven\"}", "{\"type\":\"turn.started\"}",
      "{\"type\":\"item.completed\",\"item\":{\"id\":\"patch-failed\",\"type\":\"file_change\",\"changes\":[{\"path\":\"src/unproven.mbt\",\"kind\":\"update\"}],\"status\":\"failed\"}}",
      "{\"type\":\"item.completed\",\"item\":{\"id\":\"message-2\",\"type\":\"agent_message\",\"text\":\"no proven files\"}}",
      "{\"type\":\"turn.completed\",\"usage\":{\"input_tokens\":1,\"cached_input_tokens\":0,\"output_tokens\":1,\"reasoning_output_tokens\":0}}",
    ].join("\n"),
    async fn(executable, environment, _input_path) {
      @async.with_task_group() <| group => {
        let agent = codex_agent(
          codex_agent_test_id(),
          CodexAgentOptions::CodexAgentOptions(codex_path_override=executable),
        )
        let session = (agent.open)(codex_agent_test_context(group, environment))
        let response = session.execute(
          @core.CodingAgentRequest::CodingAgentRequest(
            "inspect unproven files",
            [],
          ),
        )
        inspect(response.changed_files.length(), content="0")
        inspect(response.artifacts.length(), content="0")
        debug_inspect(response.raw_output, content="None")
        session.close()
      }
    },
  )
}

///|
async test "codex_agent 4 - preserves turn failures and rejects execution after close" {
  with_fake_codex(
    [
      "{\"type\":\"thread.started\",\"thread_id\":\"thread-failed\"}", "{\"type\":\"turn.started\"}",
      "{\"type\":\"turn.failed\",\"error\":{\"message\":\"rate limited\"}}",
    ].join("\n"),
    async fn(executable, environment, _input_path) {
      @async.with_task_group() <| group => {
        let agent = codex_agent(
          codex_agent_test_id(),
          CodexAgentOptions::CodexAgentOptions(codex_path_override=executable),
        )
        let session = (agent.open)(codex_agent_test_context(group, environment))
        let turn_failed = try {
          session.execute(
            @core.CodingAgentRequest::CodingAgentRequest("fail", []),
          )
          |> ignore
          false
        } catch {
          @sdk.CodexSdkError::TurnFailed(message~) => message == "rate limited"
          _ => false
        }
        inspect(turn_failed, content="true")
        session.close()
        let closed = try {
          session.execute(
            @core.CodingAgentRequest::CodingAgentRequest("after-close", []),
          )
          |> ignore
          false
        } catch {
          CodexAdapterError::SessionClosed => true
          _ => false
        }
        inspect(closed, content="true")
      }
    },
  )
}

// The native fake follows the pinned upstream Codex SDK executable-spy pattern:
// https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/tests/codexExecSpy.ts
