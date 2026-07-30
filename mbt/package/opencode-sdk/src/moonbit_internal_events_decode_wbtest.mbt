///|
fn decode_event_for_test(source : String) -> ThreadEvent raise {
  moonbit_internal_thread_event_from_json(@json.parse(source))
}

///|
test "ThreadEvent decode 1 - decodes completed reasoning" {
  let event = decode_event_for_test(
    "{\"type\":\"reasoning\",\"timestamp\":1,\"sessionID\":\"session-1\",\"part\":{\"type\":\"reasoning\",\"text\":\"Thought\"}}",
  )
  match event {
    Reasoning(reasoning) => {
      inspect(reasoning.session_id, content="session-1")
      inspect(reasoning.text, content="Thought")
    }
    _ => fail("expected reasoning event")
  }
}

///|
test "ThreadEvent decode 2 - decodes completed tool use" {
  let event = decode_event_for_test(
    "{\"type\":\"tool_use\",\"timestamp\":1,\"sessionID\":\"session-1\",\"part\":{\"type\":\"tool\",\"callID\":\"call-1\",\"tool\":\"bash\",\"state\":{\"status\":\"completed\"}}}",
  )
  match event {
    ToolUse(tool) => {
      inspect(tool.session_id, content="session-1")
      inspect(tool.call_id, content="call-1")
      inspect(tool.tool, content="bash")
      debug_inspect(tool.status, content="Completed")
    }
    _ => fail("expected tool-use event")
  }
}

///|
test "ThreadEvent decode 3 - decodes failed tool use" {
  let event = decode_event_for_test(
    "{\"type\":\"tool_use\",\"timestamp\":1,\"sessionID\":\"session-1\",\"part\":{\"type\":\"tool\",\"callID\":\"call-2\",\"tool\":\"bash\",\"state\":{\"status\":\"error\"}}}",
  )
  match event {
    ToolUse(tool) => debug_inspect(tool.status, content="Failed")
    _ => fail("expected tool-use event")
  }
}

///|
test "ThreadEvent decode 4 - decodes step usage" {
  let event = decode_event_for_test(
    "{\"type\":\"step_finish\",\"timestamp\":1,\"sessionID\":\"session-1\",\"part\":{\"type\":\"step-finish\",\"reason\":\"stop\",\"cost\":0.5,\"tokens\":{\"total\":14,\"input\":10,\"output\":3,\"reasoning\":1,\"cache\":{\"read\":2,\"write\":1}}}}",
  )
  match event {
    StepFinish(step) => {
      inspect(step.reason, content="stop")
      inspect(step.cost, content="0.5")
      debug_inspect(
        step.usage,
        content=(
          #|{
          #|  input_tokens: 10,
          #|  output_tokens: 3,
          #|  reasoning_tokens: 1,
          #|  cache_read_tokens: 2,
          #|  cache_write_tokens: 1,
          #|}
        ),
      )
    }
    _ => fail("expected step-finish event")
  }
}

///|
test "ThreadEvent decode 5 - decodes stream errors" {
  let event = decode_event_for_test(
    "{\"type\":\"error\",\"timestamp\":1,\"sessionID\":\"session-1\",\"error\":{\"name\":\"UnknownError\",\"data\":{\"message\":\"provider failed\"}}}",
  )
  match event {
    StreamError(error) => {
      assert_eq(error.session_id, Some("session-1"))
      inspect(error.message, content="provider failed")
    }
    _ => fail("expected error event")
  }
}

///|
test "ThreadEvent decode 6 - rejects an unknown event type" {
  let message = try {
    decode_event_for_test(
      "{\"type\":\"future_event\",\"timestamp\":1,\"sessionID\":\"session-1\"}",
    )
    |> ignore
    "no error"
  } catch {
    InvalidEvent(message~) => message
    error => "unexpected: \{@debug.to_string(error)}"
  }
  inspect(message, content="unsupported thread event type: future_event")
}
