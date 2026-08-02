// MoonBit-only tests for the standard FromJson implementations required by the language type system.
// Corresponding upstream parse/cast: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/thread.ts#L96-L109
// Event shapes under test: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/events.ts#L5-L84

///|
fn event_decode_error(source : String) -> String {
  try {
    let event : ThreadEvent = @json.from_json(@json.parse(source))
    event |> ignore
    "no error"
  } catch {
    @json.JsonDecodeError((_, message)) => message
    error => "unexpected:\{error}"
  }
}

///|
test "MoonBit event decoder - decodes thread started" {
  let event : ThreadEvent = @json.from_json(
    @json.parse("{\"type\":\"thread.started\",\"thread_id\":\"thread-1\"}"),
  )
  match event {
    ThreadStarted(event) => inspect(event.thread_id, content="thread-1")
    _ => fail("expected thread started")
  }
}

///|
test "MoonBit event decoder - decodes turn started" {
  let event : ThreadEvent = @json.from_json(
    @json.parse("{\"type\":\"turn.started\"}"),
  )
  match event {
    TurnStarted(_) => ()
    _ => fail("expected turn started")
  }
}

///|
test "MoonBit event decoder - decodes completed turn usage" {
  let event : ThreadEvent = @json.from_json(
    @json.parse(
      "{\"type\":\"turn.completed\",\"usage\":{\"input_tokens\":10,\"cached_input_tokens\":2,\"cache_write_input_tokens\":3,\"output_tokens\":4,\"reasoning_output_tokens\":1}}",
    ),
  )
  match event {
    TurnCompleted(event) => {
      inspect(event.usage.input_tokens, content="10")
      inspect(event.usage.cached_input_tokens, content="2")
      inspect(event.usage.cache_write_input_tokens, content="3")
      inspect(event.usage.output_tokens, content="4")
      inspect(event.usage.reasoning_output_tokens, content="1")
    }
    _ => fail("expected turn completed")
  }
  let event_without_cache_write : ThreadEvent = @json.from_json(
    @json.parse(
      "{\"type\":\"turn.completed\",\"usage\":{\"input_tokens\":10,\"cached_input_tokens\":2,\"output_tokens\":4,\"reasoning_output_tokens\":1}}",
    ),
  )
  match event_without_cache_write {
    TurnCompleted(event) =>
      inspect(event.usage.cache_write_input_tokens, content="0")
    _ => fail("expected turn completed")
  }
}

///|
test "MoonBit event decoder - decodes turn failed" {
  let event : ThreadEvent = @json.from_json(
    @json.parse(
      "{\"type\":\"turn.failed\",\"error\":{\"message\":\"rate limited\"}}",
    ),
  )
  match event {
    TurnFailed(event) => inspect(event.error.message, content="rate limited")
    _ => fail("expected turn failed")
  }
}

///|
test "MoonBit event decoder - decodes item started" {
  let event : ThreadEvent = @json.from_json(
    @json.parse(
      "{\"type\":\"item.started\",\"item\":{\"id\":\"reasoning-1\",\"type\":\"reasoning\",\"text\":\"thinking\"}}",
    ),
  )
  match event {
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
  let event : ThreadEvent = @json.from_json(
    @json.parse(
      "{\"type\":\"item.updated\",\"item\":{\"id\":\"command-1\",\"type\":\"command_execution\",\"command\":\"pwd\",\"aggregated_output\":\"/tmp\\n\",\"exit_code\":null,\"status\":\"in_progress\"}}",
    ),
  )
  match event {
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
  let event : ThreadEvent = @json.from_json(
    @json.parse(
      "{\"type\":\"item.completed\",\"item\":{\"id\":\"message-1\",\"type\":\"agent_message\",\"text\":\"done\"}}",
    ),
  )
  match event {
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
  let event : ThreadEvent = @json.from_json(
    @json.parse("{\"type\":\"error\",\"message\":\"stream unavailable\"}"),
  )
  match event {
    StreamError(event) => inspect(event.message, content="stream unavailable")
    _ => fail("expected stream error")
  }
}

///|
test "MoonBit event decoder - rejects unknown event types" {
  inspect(
    event_decode_error("{\"type\":\"turn.unknown\"}"),
    content="unsupported thread event type: turn.unknown",
  )
}

///|
test "MoonBit event decoder - rejects missing event types" {
  assert_true(event_decode_error("{}").contains("MissingProperty"))
}

///|
test "MoonBit event decoder - rejects non-object events" {
  inspect(event_decode_error("[]"), content="thread event must be an object")
}

///|
test "MoonBit event decoder - rejects invalid nested payloads" {
  inspect(
    event_decode_error(
      "{\"type\":\"turn.completed\",\"usage\":{\"input_tokens\":\"ten\",\"cached_input_tokens\":2,\"output_tokens\":4,\"reasoning_output_tokens\":1}}",
    ),
    content="Int::from_json: expected number",
  )
}
