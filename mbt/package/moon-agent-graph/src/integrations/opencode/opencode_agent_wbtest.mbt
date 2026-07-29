///|
fn opencode_test_context(
  group : @async.TaskGroup[Unit],
  environment : Map[String, String],
) -> @core.CodingAgentOpenContext {
  let run_id = @core.RunId::parse("opencode-test-run") catch {
    _ => abort("test run ID must be valid")
  }
  @core.CodingAgentOpenContext::{
    run_id,
    task_group: group,
    workspace: @core.WorkspaceRef::{
      root: @path.Path("/workspace"),
      additional_writable_roots: [],
    },
    approval: @core.Never,
    network: @core.Disabled,
    environment,
    events: @core.EventSink::discard(),
  }
}

///|
async test "opencode_agent 1 - builds official session and message JSON" {
  @async.with_task_group() <| group => {
    let context = opencode_test_context(group, Map([]))
    json_inspect(session_body(context), content={
      "title": "moon-agent-graph opencode-test-run workspace /workspace",
    })
    json_inspect(
      message_body(context.workspace.root, @core.CodingAgentRequest::{
        instruction: "fix the issue",
        context_files: [@path.Path("README.md"), @path.Path("/shared/guide.md")],
      }),
      content={
        "parts": [
          {
            "type": "text",
            "text": "fix the issue\n\nContext file paths supplied by the caller (not attached):\n/workspace/README.md\n/shared/guide.md",
          },
        ],
      },
    )
    inspect(session_path(), content="/session")
    inspect(message_path("ses-42"), content="/session/ses-42/message")
  }
}

///|
async test "opencode_agent 2 - merges adapter environment under caller context" {
  @async.with_task_group() <| group => {
    let options = OpenCodeAgentOptions::OpenCodeAgentOptions(extra_env={
      "adapter": "enabled",
      "shared": "adapter-value",
    })
    let environment = merged_environment(
      options,
      opencode_test_context(group, { "run": "active", "shared": "run-value" }),
    )
    inspect(environment.get("adapter").unwrap_or(""), content="enabled")
    inspect(environment.get("run").unwrap_or(""), content="active")
    inspect(environment.get("shared").unwrap_or(""), content="run-value")
  }
}

///|
test "opencode_agent 3 - decodes the official session response and rejects malformed JSON" {
  inspect(
    decode_session_id(Json::object({ "id": "ses-42".to_json() })),
    content="ses-42",
  )
  let malformed = try {
    decode_session_id(Json::object({ "id": "".to_json() })) |> ignore
    false
  } catch {
    OpenCodeAdapterError::InvalidSessionResponse => true
    _ => false
  }
  inspect(malformed, content="true")
}

///|
test "opencode_agent 4 - decodes summary raw JSON and continuation exactly" {
  let raw = Json::object({
    "info": Json::empty_object(),
    "parts": Json::array([
      Json::object({ "type": "tool".to_json(), "text": "ignored".to_json() }),
      Json::object({ "type": "text".to_json(), "text": "Hello ".to_json() }),
      Json::object({ "type": "text".to_json(), "text": "OpenCode".to_json() }),
    ]),
  })
  let response = decode_response("ses-42", raw)
  debug_inspect(response.status, content="Succeeded")
  debug_inspect(response.summary, content="Some(\"Hello OpenCode\")")
  debug_inspect(response.continuation_id, content="Some(\"ses-42\")")
  inspect(response.changed_files.length(), content="0")
  inspect(response.artifacts.length(), content="0")
  match response.raw_output {
    Some(output) =>
      json_inspect(output, content={
        "info": Json::empty_object(),
        "parts": [
          { "type": "tool", "text": "ignored" },
          { "type": "text", "text": "Hello " },
          { "type": "text", "text": "OpenCode" },
        ],
      })
    None => fail("raw OpenCode response must be preserved")
  }
}

///|
test "opencode_agent 5 - preserves message info.error and malformed response errors" {
  let malformed = try {
    decode_response("ses-42", Json::object({ "parts": Json::array([]) }))
    |> ignore
    false
  } catch {
    OpenCodeAdapterError::InvalidMessageResponse => true
    _ => false
  }
  inspect(malformed, content="true")
  let error_response = try {
    decode_response(
      "ses-42",
      Json::object({
        "info": Json::object({
          "error": Json::object({ "message": "permission denied".to_json() }),
        }),
        "parts": Json::array([]),
      }),
    )
    |> ignore
    "missing error"
  } catch {
    OpenCodeAdapterError::MessageFailed(message) => message
    _ => "wrong error"
  }
  inspect(error_response, content="{\"message\":\"permission denied\"}")
}

///|
test "opencode_agent 6 - exposes SessionClosed as the session terminal error" {
  let closed = try {
    raise OpenCodeAdapterError::SessionClosed
  } catch {
    OpenCodeAdapterError::SessionClosed => true
    _ => false
  }
  inspect(closed, content="true")
}
