///|
async test "CodexExec run - rejects when exit happens before stdout closes" {
  with_fake_codex(async fn(fixture) {
    let environment = fixture.environment([])
    environment.set("FAKE_CODEX_HOLD_STDOUT", "1")
    environment.set("FAKE_CODEX_STDERR", "early failure")
    environment.set("FAKE_CODEX_EXIT_CODE", "17")
    let thread = fixture.client(environment).start_thread()
    let detail = try {
      @async.with_timeout(2000, async fn() {
        thread.run(Prompt("fail early")) |> ignore
      })
      "no error"
    } catch {
      CodexSdkError::ExecFailed(code~, stderr~) =>
        "\{code}:\{stderr.trim()}"
      error =>
        if @async.is_cancellation_error(error) {
          "timed out"
        } else {
          "unexpected:\{error}"
        }
    }
    inspect(detail, content="17:early failure")
  })
}

///|
async test "CodexExec env - allows overriding environment passed to CLI" {
  with_fake_codex(async fn(fixture) {
    let environment = fixture.environment([
      completed_events("thread-1", "item-1", "Hi!"),
    ])
    environment.set("CUSTOM_ENV", "custom")
    let client = Codex::Codex(
      options=CodexOptions::CodexOptions(
        codex_path_override=fixture.executable,
        base_url="https://api.example.test/v1",
        api_key="secret-test-key",
        env=environment,
      ),
    )
    client.start_thread().run(Prompt("Hello")) |> ignore
    let recorded_environment = fixture.recorded_lines("env", 1)
    assert_true(recorded_environment.contains("CUSTOM_ENV=custom"))
    assert_true(recorded_environment.contains("CODEX_API_KEY=secret-test-key"))
    assert_true(
      recorded_environment.contains(
        "CODEX_INTERNAL_ORIGINATOR_OVERRIDE=codex_sdk_mbt",
      ),
    )
    assert_true(
      contains_pair(
        fixture.recorded_lines("args", 1),
        "--config",
        "openai_base_url=\"https://api.example.test/v1\"",
      ),
    )
  })
}
