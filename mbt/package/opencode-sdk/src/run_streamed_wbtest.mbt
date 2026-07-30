///|
async test "OpenCode run_streamed - emits typed events" {
  with_fake_opencode(async fn(fixture) {
    let thread = fixture
      .client(fixture.environment([completed_events("session-1", "Streamed")]))
      .start_thread()
    let events : Array[ThreadEvent] = []
    thread.run_streamed(Prompt("stream"), async fn(event) {
      events.push(event)
      @async.pause()
    })
    assert_eq(thread.id(), Some("session-1"))
    inspect(events.length(), content="3")
    match events[1] {
      Text(event) => {
        inspect(event.session_id, content="session-1")
        inspect(event.text, content="Streamed")
      }
      _ => fail("expected text event")
    }
  })
}
