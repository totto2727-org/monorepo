///|
fn fake_response() -> @core.CodingAgentResponse {
  @core.CodingAgentResponse::CodingAgentResponse(
    status=@core.Succeeded,
    summary=Some("done"),
    continuation_id=Some("continue-1"),
    changed_files=[],
    artifacts=[],
    raw_output=None,
  )
}

///|
fn fake_open_context(
  group : @async.TaskGroup[Unit],
) -> @core.CodingAgentOpenContext {
  @core.CodingAgentOpenContext::CodingAgentOpenContext(
    run_id=@core.RunId::parse("fake-run") catch {
      _ => abort("static fake run ID must be valid")
    },
    task_group=group,
    workspace=@core.WorkspaceRef::WorkspaceRef(@path.Path("/workspace"), []),
    approval=@core.Never,
    network=@core.Disabled,
    environment=@immut_hashmap.new(),
    events=@core.EventSink::discard(),
  )
}

///|
fn fake_chat_response() -> @llm.ChatResponse {
  @llm.ChatResponse::{
    id: "fake-response",
    object: "chat.completion",
    created: 0L,
    model: "fake-model",
    choices: [],
    usage: None,
    system_fingerprint: None,
  }
}

///|
async test "fake_coding_agent records exact open request and idempotent close order" {
  @async.with_task_group() <| group => {
    let session_id = @core.SessionId::parse("fake-session")
    let fixture = fake_coding_agent(fake_response(), session_id~)
    let agent = fixture.agent()
    let session = (agent.open)(fake_open_context(group))
    let request = @core.CodingAgentRequest::CodingAgentRequest(
      "update fixture",
      [@path.Path("README.md")],
    )
    let response = session.execute(request)
    session.close()
    session.close()
    debug_inspect(response.summary, content="Some(\"done\")")
    let open_calls = fixture.open_calls()
    inspect(open_calls.length(), content="1")
    inspect(open_calls[0].context.run_id.to_string(), content="fake-run")
    let requests = fixture.request_calls()
    inspect(requests.length(), content="1")
    inspect(requests[0].request.instruction, content="update fixture")
    inspect(
      requests[0].request.context_files[0].to_string(),
      content="README.md",
    )
    debug_inspect(
      fixture.session_ids(),
      content="<ReadOnlyArray: [Some(SessionId(\"fake-session\"))]>",
    )
    debug_inspect(
      fixture.close_order(),
      content="<ReadOnlyArray: [Some(SessionId(\"fake-session\"))]>",
    )
  }
}

///|
async test "fake_coding_agent preserves scripted open and execute errors" {
  @async.with_task_group() <| group => {
    let open_fixture = fake_coding_agent(
      fake_response(),
      open_error=@llm.Transport("open-failed"),
    )
    let open_error = try {
      (open_fixture.agent().open)(fake_open_context(group)) |> ignore
      "no error"
    } catch {
      @llm.Transport(message) => "Transport:\{message}"
      _ => "wrong error"
    }
    inspect(open_error, content="Transport:open-failed")
    inspect(open_fixture.open_calls().length(), content="1")
    inspect(open_fixture.session_ids().length(), content="0")

    let execute_fixture = fake_coding_agent(
      fake_response(),
      execute_error=@llm.Transport("execute-failed"),
    )
    let session = (execute_fixture.agent().open)(fake_open_context(group))
    let execute_error = try {
      session.execute(@core.CodingAgentRequest::CodingAgentRequest("fail", []))
      |> ignore
      "no error"
    } catch {
      @llm.Transport(message) => "Transport:\{message}"
      _ => "wrong error"
    }
    inspect(execute_error, content="Transport:execute-failed")
    inspect(execute_fixture.request_calls().length(), content="1")
  }
}

///|
async test "fake_moonllm_invoke records typed requests and preserves errors" {
  let fixture = fake_moonllm_invoke(fake_chat_response())
  let callback = fixture.callback()
  let response = callback(
    @llm.ChatRequest::new("fixture-model", [@llm.Message::user("hello")]),
  )
  inspect(response.id, content="fake-response")
  let requests = fixture.requests()
  inspect(requests.length(), content="1")
  inspect(requests[0].model, content="fixture-model")
  inspect(requests[0].messages[0].content.to_text(), content="hello")

  let failing = fake_moonllm_invoke(
    fake_chat_response(),
    error=@llm.Transport("offline"),
  )
  let error = try {
    failing.callback()(
      @llm.ChatRequest::new("fixture-model", [@llm.Message::user("retry")]),
    )
    |> ignore
    "no error"
  } catch {
    @llm.Transport(message) => "Transport:\{message}"
    _ => "wrong error"
  }
  inspect(error, content="Transport:offline")
  inspect(failing.requests()[0].messages[0].content.to_text(), content="retry")
}
