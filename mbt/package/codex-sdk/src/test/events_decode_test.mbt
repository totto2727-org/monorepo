///|
async test "MoonBit event decoder - wraps malformed JSONL input" {
  with_fake_codex(async fn(fixture) {
    let thread = fixture
      .client(fixture.environment(["{not-json"]))
      .start_thread()
    let message = try {
      thread.run_streamed(@codex.Prompt("invalid event"), async fn(_) {
        @async.pause()
      })
      "no error"
    } catch {
      @codex.CodexSdkError::InvalidEvent(message~) => message
      error => "unexpected:\{error}"
    }
    assert_true(message.contains("Failed to parse item: {not-json"))
  })
}
