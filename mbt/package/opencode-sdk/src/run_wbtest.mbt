///|
async test "OpenCode run 1 - returns a completed turn" {
  with_fake_opencode(async fn(fixture) {
    let client = fixture.client(
      fixture.environment([completed_events("session-1", "Hello!")]),
    )
    let thread = client.start_thread(
      options=ThreadOptions::ThreadOptions(model="test/model"),
    )
    let turn = thread.run(Prompt("Say hello"))
    assert_eq(thread.id(), Some("session-1"))
    inspect(turn.final_response, content="Hello!")
    inspect(turn.events.length(), content="3")
    let args = fixture.recorded_lines("args", 1)
    assert_true(args[0] == "run")
    assert_true(contains_pair(args, "--format", "json"))
    assert_true(contains_pair(args, "--model", "test/model"))
    inspect(fixture.recorded_text("input", 1), content="Say hello")
  })
}

///|
async test "OpenCode run 2 - continues the session on a second turn" {
  with_fake_opencode(async fn(fixture) {
    let thread = fixture
      .client(
        fixture.environment([
          completed_events("session-1", "First"),
          completed_events("session-1", "Second"),
        ]),
      )
      .start_thread()
    thread.run(Prompt("first")) |> ignore
    let turn = thread.run(Prompt("second"))
    inspect(turn.final_response, content="Second")
    assert_true(
      contains_pair(fixture.recorded_lines("args", 2), "--session", "session-1"),
    )
    inspect(fixture.recorded_text("input", 2), content="second")
  })
}

///|
async test "OpenCode resume_thread - resumes a session by ID" {
  with_fake_opencode(async fn(fixture) {
    let thread = fixture
      .client(fixture.environment([completed_events("session-7", "Resumed")]))
      .resume_thread("session-7")
    let turn = thread.run(Prompt("continue"))
    assert_eq(thread.id(), Some("session-7"))
    inspect(turn.final_response, content="Resumed")
    assert_true(
      contains_pair(fixture.recorded_lines("args", 1), "--session", "session-7"),
    )
  })
}
