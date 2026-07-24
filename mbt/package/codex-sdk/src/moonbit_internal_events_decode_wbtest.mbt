// MoonBit-only tests for the explicit event decoder required by the language type system.
// Corresponding upstream parse/cast: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/thread.ts#L96-L109
// Event shapes under test: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/events.ts#L5-L84
// This file is intentionally prefixed moonbit_internal_ because upstream relies on a TypeScript cast and has no decoder test module.

fn moonbit_internal_decode_event(source : String) -> ThreadEvent raise {
  moonbit_internal_thread_event_from_json(@json.parse(source))
}

fn moonbit_internal_event_decode_error(source : String) -> String {
  try {
    moonbit_internal_decode_event(source) |> ignore
    "no error"
  } catch {
    CodexSdkError::InvalidEvent(message~) => message
    error => "unexpected:\{error}"
  }
}

///|
test "MoonBit event decoder - decodes thread started" {
  match moonbit_internal_decode_event(
    "{\"type\":\"thread.started\",\"thread_id\":\"thread-1\"}",
  ) {
    ThreadStarted(event) => inspect(event.thread_id, content="thread-1")
    _ => fail("expected thread started")
  }
}

///|
test "MoonBit event decoder - decodes turn started" {
  match moonbit_internal_decode_event("{\"type\":\"turn.started\"}") {
    TurnStarted(_) => ()
    _ => fail("expected turn started")
  }
}

///|
test "MoonBit event decoder - decodes completed turn usage" {
  match moonbit_internal_decode_event(
    "{\"type\":\"turn.completed\",\"usage\":{\"input_tokens\":10,\"cached_input_tokens\":2,\"cache_write_input_tokens\":3,\"output_tokens\":4,\"reasoning_output_tokens\":1}}",
  ) {
    TurnCompleted(event) => {
      inspect(event.usage.input_tokens, content="10")
      inspect(event.usage.cached_input_tokens, content="2")
      inspect(event.usage.cache_write_input_tokens, content="3")
      inspect(event.usage.output_tokens, content="4")
      inspect(event.usage.reasoning_output_tokens, content="1")
    }
    _ => fail("expected turn completed")
  }
  match moonbit_internal_decode_event(
    "{\"type\":\"turn.completed\",\"usage\":{\"input_tokens\":10,\"cached_input_tokens\":2,\"output_tokens\":4,\"reasoning_output_tokens\":1}}",
  ) {
    TurnCompleted(event) =>
      inspect(event.usage.cache_write_input_tokens, content="0")
    _ => fail("expected turn completed")
  }
}

///|
test "MoonBit event decoder - decodes turn failed" {
  match moonbit_internal_decode_event(
    "{\"type\":\"turn.failed\",\"error\":{\"message\":\"rate limited\"}}",
  ) {
    TurnFailed(event) => inspect(event.error.message, content="rate limited")
    _ => fail("expected turn failed")
  }
}

///|
test "MoonBit event decoder - decodes item started" {
  match moonbit_internal_decode_event(
    "{\"type\":\"item.started\",\"item\":{\"id\":\"reasoning-1\",\"type\":\"reasoning\",\"text\":\"thinking\"}}",
  ) {
    ItemStarted(event) =>
      match event.item {
        Reasoning(item) => inspect(item.text, content="thinking")
        _ => fail("expected reasoning item")
      }
    _ => fail("expected item started")
  }
}

///|
test "MoonBit event decoder - decodes item updated" {
  match moonbit_internal_decode_event(
    "{\"type\":\"item.updated\",\"item\":{\"id\":\"command-1\",\"type\":\"command_execution\",\"command\":\"pwd\",\"aggregated_output\":\"/tmp\\n\",\"exit_code\":null,\"status\":\"in_progress\"}}",
  ) {
    ItemUpdated(event) =>
      match event.item {
        CommandExecution(item) => {
          inspect(item.aggregated_output, content="/tmp\n")
          assert_eq(item.status, InProgress)
        }
        _ => fail("expected command execution")
      }
    _ => fail("expected item updated")
  }
}

///|
test "MoonBit event decoder - decodes item completed" {
  match moonbit_internal_decode_event(
    "{\"type\":\"item.completed\",\"item\":{\"id\":\"message-1\",\"type\":\"agent_message\",\"text\":\"done\"}}",
  ) {
    ItemCompleted(event) =>
      match event.item {
        AgentMessage(item) => inspect(item.text, content="done")
        _ => fail("expected agent message")
      }
    _ => fail("expected item completed")
  }
}

///|
test "MoonBit event decoder - decodes stream errors" {
  match moonbit_internal_decode_event(
    "{\"type\":\"error\",\"message\":\"stream unavailable\"}",
  ) {
    StreamError(event) => inspect(event.message, content="stream unavailable")
    _ => fail("expected stream error")
  }
}

///|
test "MoonBit event decoder - rejects unknown event types" {
  inspect(
    moonbit_internal_event_decode_error("{\"type\":\"turn.unknown\"}"),
    content="unsupported thread event type: turn.unknown",
  )
}

///|
test "MoonBit event decoder - rejects missing event types" {
  inspect(
    moonbit_internal_event_decode_error("{}"),
    content="thread event is missing type",
  )
}

///|
test "MoonBit event decoder - rejects non-object events" {
  inspect(
    moonbit_internal_event_decode_error("[]"),
    content="thread event must be an object",
  )
}

///|
test "MoonBit event decoder - rejects invalid nested payloads" {
  inspect(
    moonbit_internal_event_decode_error(
      "{\"type\":\"turn.completed\",\"usage\":{\"input_tokens\":\"ten\",\"cached_input_tokens\":2,\"output_tokens\":4,\"reasoning_output_tokens\":1}}",
    ),
    content="usage.input_tokens must be a number",
  )
}

///|
async test "MoonBit event decoder - wraps malformed JSONL input" {
  with_fake_codex(async fn(fixture) {
    let thread = fixture
      .client(fixture.environment(["{not-json"]))
      .start_thread()
    let message = try {
      thread.run_streamed(
        Prompt("invalid event"),
        async fn(_) { @async.pause() },
      )
      "no error"
    } catch {
      CodexSdkError::InvalidEvent(message~) => message
      error => "unexpected:\{error}"
    }
    assert_true(message.contains("Failed to parse item: {not-json"))
  })
}
