// Direct test port of https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/tests/runStreamed.test.ts

// MoonBit-only assertion adapter for comparing callback events without TypeScript object matchers.
// Corresponding upstream assertion: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/tests/runStreamed.test.ts#L24-L55
fn moonbit_internal_streamed_event_summary(event : ThreadEvent) -> String {
  match event {
    ThreadStarted(started) => "thread.started:\{started.thread_id}"
    TurnStarted(_) => "turn.started"
    ItemCompleted({ item: AgentMessage(message) }) =>
      "item.completed:\{message.id}:\{message.text}"
    TurnCompleted(completed) =>
      "turn.completed:\{completed.usage.input_tokens}:\{completed.usage.output_tokens}"
    TurnFailed(failed) => "turn.failed:\{failed.error.message}"
    ItemStarted(_) => "item.started"
    ItemUpdated(_) => "item.updated"
    ItemCompleted(_) => "item.completed"
    StreamError(error) => "error:\{error.message}"
  }
}

///| Upstream test: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/tests/runStreamed.test.ts#L15
async test "Codex runStreamed - returns thread events" {
  with_fake_codex(async fn(fixture) {
    let client = fixture.client(
      fixture.environment([completed_events("thread-1", "item-1", "Hi!")]),
    )
    let thread = client.start_thread()
    let events : Array[String] = []
    thread.run_streamed(
      Prompt("Hello, world!"),
      async fn(event) {
        events.push(moonbit_internal_streamed_event_summary(event))
        @async.pause()
      },
    )
    json_inspect(events, content=[
      "thread.started:thread-1",
      "turn.started",
      "item.completed:item-1:Hi!",
      "turn.completed:42:5",
    ])
    assert_eq(thread.id(), Some("thread-1"))
  })
}

///| Upstream test: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/tests/runStreamed.test.ts#L65
async test "Codex runStreamed - sends previous items when called twice" {
  with_fake_codex(async fn(fixture) {
    let client = fixture.client(
      fixture.environment([
        completed_events("thread-1", "item-1", "First response"),
        completed_events("thread-1", "item-2", "Second response"),
      ]),
    )
    let thread = client.start_thread()
    thread.run_streamed(
      Prompt("first input"),
      async fn(_) { @async.pause() },
    )
    thread.run_streamed(
      Prompt("second input"),
      async fn(_) { @async.pause() },
    )
    let second_args = fixture.recorded_lines("args", 2)
    assert_true(contains_pair(second_args, "resume", "thread-1"))
    inspect(fixture.recorded_text("input", 2), content="second input")
  })
}

///| Upstream test: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/tests/runStreamed.test.ts#L111
async test "Codex runStreamed - resumes thread by ID" {
  with_fake_codex(async fn(fixture) {
    let client = fixture.client(
      fixture.environment([
        completed_events("thread-1", "item-1", "First response"),
        completed_events("thread-1", "item-1", "Resumed response"),
      ]),
    )
    let original = client.start_thread()
    original.run_streamed(
      Prompt("first input"),
      async fn(_) { @async.pause() },
    )
    let resumed = client.resume_thread(original.id().unwrap_or(""))
    resumed.run_streamed(
      Prompt("second input"),
      async fn(_) { @async.pause() },
    )
    assert_true(
      contains_pair(
        fixture.recorded_lines("args", 2),
        "resume",
        "thread-1",
      ),
    )
    assert_eq(resumed.id(), original.id())
  })
}

///| Upstream test: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/tests/runStreamed.test.ts#L159
async test "Codex runStreamed - applies output schema turn options" {
  with_fake_codex(async fn(fixture) {
    let client = fixture.client(
      fixture.environment([
        completed_events("thread-1", "item-1", "Structured response"),
      ]),
    )
    let schema = @json.parse(
      "{\"type\":\"object\",\"properties\":{\"answer\":{\"type\":\"string\"}},\"required\":[\"answer\"],\"additionalProperties\":false}",
    )
    client
    .start_thread()
    .run_streamed(
      Prompt("structured"),
      async fn(_) { @async.pause() },
      turn_options=TurnOptions::TurnOptions(output_schema=schema),
    )
    inspect(fixture.recorded_text("schema", 1), content=schema.stringify())
    let schema_path = fixture.recorded_text("schema_path", 1)
    assert_eq(@fs.exists(schema_path), false)
  })
}
