///|
async fn wait_for_test_file(path : String) -> Unit {
  @async.with_timeout(2000, async fn() {
    while !@fs.exists(path) {
      @async.pause()
    }
  })
}

///|
async fn process_is_running(pid : Int) -> Bool {
  let (code, _, _) = @process.collect_output("kill", ["-0", pid.to_string()])
  code == 0
}

///|
async test "OpenCodeExec run 1 - reports nonzero exits" {
  with_fake_opencode(async fn(fixture) {
    let environment = fixture.environment([])
    environment["FAKE_OPENCODE_STDERR"] = "cli failed"
    environment["FAKE_OPENCODE_EXIT_CODE"] = "17"
    let message = try {
      fixture.client(environment).start_thread().run(@opencode.Prompt("fail")) |> ignore
      "no error"
    } catch {
      @opencode.OpenCodeSdkError::ExecFailed(code~, stderr~) => "\{code}:\{stderr}"
      error => "unexpected: \{error}"
    }
    inspect(message, content="17:cli failed")
  })
}

///|
async test "OpenCodeExec run 2 - rejects malformed JSONL" {
  with_fake_opencode(async fn(fixture) {
    let message = try {
      fixture
      .client(fixture.environment(["{not-json"]))
      .start_thread()
      .run(@opencode.Prompt("malformed"))
      |> ignore
      "no error"
    } catch {
      @opencode.OpenCodeSdkError::InvalidEvent(message~) => message
      error => "unexpected: \{error}"
    }
    assert_true(message.has_prefix("Failed to parse OpenCode event: {not-json"))
  })
}

///|
async test "OpenCodeExec run 3 - raises a turn failure from an error event" {
  with_fake_opencode(async fn(fixture) {
    let events = "{\"type\":\"error\",\"timestamp\":1,\"sessionID\":\"session-1\",\"error\":{\"name\":\"UnknownError\",\"data\":{\"message\":\"provider failed\"}}}"
    let message = try {
      fixture
      .client(fixture.environment([events]))
      .start_thread()
      .run(@opencode.Prompt("error"))
      |> ignore
      "no error"
    } catch {
      @opencode.OpenCodeSdkError::TurnFailed(message~) => message
      error => "unexpected: \{error}"
    }
    inspect(message, content="provider failed")
  })
}

///|
async test "OpenCodeExec run 4 - stops the child when cancelled" {
  with_fake_opencode(async fn(fixture) {
    let environment = fixture.environment([])
    environment["FAKE_OPENCODE_PAUSE"] = "1"
    let thread = fixture.client(environment).start_thread()
    @async.with_task_group(async fn(group) {
      let task = group.spawn(
        async fn() { thread.run(@opencode.Prompt("pause")) |> ignore },
        allow_failure=true,
      )
      let pid_path = "\{fixture.record_directory}/pid.1"
      wait_for_test_file(pid_path)
      let pid = @string.parse_int(
        @fs.read_file(pid_path).text().trim(),
        base=10,
      )
      assert_true(process_is_running(pid))
      task.cancel()
      let cancelled = try {
        task.wait()
        false
      } catch {
        error => @async.is_cancellation_error(error)
      }
      assert_true(cancelled)
      assert_false(process_is_running(pid))
    })
  })
}
