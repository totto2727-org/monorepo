///|
async test "Codex run - returns thread events" {
  with_fake_codex(async fn(fixture) {
    let client = fixture.client(
      fixture.environment([completed_events("thread-1", "item-1", "Hi!")]),
    )
    let thread = client.start_thread()
    let turn = thread.run(Prompt("Hello, world!"))
    assert_eq(thread.id(), Some("thread-1"))
    inspect(turn.final_response, content="Hi!")
    inspect(turn.items.length(), content="1")
    match turn.items[0] {
      AgentMessage(message) => inspect(message.text, content="Hi!")
      _ => fail("expected agent message")
    }
    match turn.usage {
      Some(usage) => {
        inspect(usage.input_tokens, content="42")
        inspect(usage.cached_input_tokens, content="12")
        inspect(usage.cache_write_input_tokens, content="0")
        inspect(usage.output_tokens, content="5")
        inspect(usage.reasoning_output_tokens, content="0")
      }
      None => fail("expected usage")
    }
  })
}

///|
async test "Codex run - sends previous items when called twice" {
  with_fake_codex(async fn(fixture) {
    let client = fixture.client(
      fixture.environment([
        completed_events("thread-1", "item-1", "First response"),
        completed_events("thread-1", "item-2", "Second response"),
      ]),
    )
    let thread = client.start_thread()
    thread.run(Prompt("first input")) |> ignore
    thread.run(Prompt("second input")) |> ignore
    let second_args = fixture.recorded_lines("args", 2)
    assert_true(contains_pair(second_args, "resume", "thread-1"))
    inspect(fixture.recorded_text("input", 2), content="second input")
  })
}

///|
async test "Codex run - continues the thread when called twice with options" {
  with_fake_codex(async fn(fixture) {
    let client = fixture.client(
      fixture.environment([
        completed_events("thread-1", "item-1", "First response"),
        completed_events("thread-1", "item-2", "Second response"),
      ]),
    )
    let thread = client.start_thread(
      options=ThreadOptions::ThreadOptions(
        model="gpt-test-1",
        sandbox_mode=WorkspaceWrite,
      ),
    )
    thread.run(Prompt("first input")) |> ignore
    thread.run(Prompt("second input")) |> ignore
    let second_args = fixture.recorded_lines("args", 2)
    assert_true(contains_pair(second_args, "resume", "thread-1"))
    assert_true(contains_pair(second_args, "--model", "gpt-test-1"))
    assert_true(contains_pair(second_args, "--sandbox", "workspace-write"))
  })
}

///|
async test "Codex resumeThread - resumes thread by ID" {
  with_fake_codex(async fn(fixture) {
    let client = fixture.client(
      fixture.environment([
        completed_events("thread-1", "item-1", "First response"),
        completed_events("thread-1", "item-2", "Second response"),
      ]),
    )
    let original = client.start_thread()
    original.run(Prompt("first input")) |> ignore
    let resumed = client.resume_thread(original.id().unwrap_or(""))
    let turn = resumed.run(Prompt("second input"))
    assert_eq(resumed.id(), Some("thread-1"))
    inspect(turn.final_response, content="Second response")
    assert_true(
      contains_pair(
        fixture.recorded_lines("args", 2),
        "resume",
        "thread-1",
      ),
    )
  })
}

///|
async test "Codex run - writes output schema to a temporary file and forwards it" {
  with_fake_codex(async fn(fixture) {
    let client = fixture.client(
      fixture.environment([
        completed_events("thread-1", "item-1", "Structured response"),
      ]),
    )
    let schema = @json.parse(
      "{\"type\":\"object\",\"properties\":{\"answer\":{\"type\":\"string\"}},\"required\":[\"answer\"],\"additionalProperties\":false}",
    )
    let thread = client.start_thread()
    thread.run(
      Prompt("structured"),
      turn_options=TurnOptions::TurnOptions(output_schema=schema),
    )
    |> ignore
    inspect(fixture.recorded_text("schema", 1), content=schema.stringify())
    let schema_path = fixture.recorded_text("schema_path", 1)
    inspect(@fs.exists(schema_path), content="false")
  })
}

///|
async test "Codex run - combines structured text input segments" {
  with_fake_codex(async fn(fixture) {
    let client = fixture.client(
      fixture.environment([
        completed_events("thread-1", "item-1", "Combined input applied"),
      ]),
    )
    client
    .start_thread()
    .run(UserInputs([
      Text("Describe file changes"),
      Text("Focus on impacted tests"),
    ]))
    |> ignore
    inspect(
      fixture.recorded_text("input", 1),
      content="Describe file changes\n\nFocus on impacted tests",
    )
  })
}

///|
async test "Codex run - forwards images to exec" {
  with_fake_codex(async fn(fixture) {
    let client = fixture.client(
      fixture.environment([
        completed_events("thread-1", "item-1", "Images applied"),
      ]),
    )
    client
    .start_thread()
    .run(UserInputs([
      Text("describe the images"),
      LocalImage(@path.Path("first.png")),
      LocalImage(@path.Path("second.jpg")),
    ]))
    |> ignore
    inspect(
      values_after(fixture.recorded_lines("args", 1), "--image").join(","),
      content="first.png,second.jpg",
    )
  })
}

///|
async test "Codex run - runs in provided working directory" {
  with_fake_codex(async fn(fixture) {
    let client = fixture.client(
      fixture.environment([
        completed_events("thread-1", "item-1", "Working directory applied"),
      ]),
    )
    client
    .start_thread(
      options=ThreadOptions::ThreadOptions(
        working_directory=@path.Path("/tmp/work"),
        skip_git_repo_check=true,
      ),
    )
    .run(Prompt("use custom working directory"))
    |> ignore
    let args = fixture.recorded_lines("args", 1)
    assert_true(contains_pair(args, "--cd", "/tmp/work"))
    assert_true(args.contains("--skip-git-repo-check"))
  })
}

///|
async test "Codex run - throws when working directory is untrusted" {
  with_fake_codex(async fn(fixture) {
    let environment = fixture.environment([])
    environment.set("FAKE_CODEX_REJECT_UNTRUSTED", "1")
    let thread = fixture
      .client(environment)
      .start_thread(
        options=ThreadOptions::ThreadOptions(
          working_directory=@path.Path("/tmp/not-git"),
        ),
      )
    let detail = try {
      thread.run(Prompt("use custom working directory")) |> ignore
      "no error"
    } catch {
      ExecFailed(code~, stderr~) => "\{code}:\{stderr.trim()}"
      error => "unexpected:\{error}"
    }
    inspect(detail, content="1:Not inside a trusted directory")
  })
}

///|
async test "Codex run - sets the Codex SDK originator" {
  with_fake_codex(async fn(fixture) {
    let client = fixture.client(
      fixture.environment([
        completed_events("thread-1", "item-1", "Hi!"),
      ]),
    )
    client.start_thread().run(Prompt("Hello, originator!")) |> ignore
    assert_true(
      fixture
      .recorded_lines("env", 1)
      .contains("CODEX_INTERNAL_ORIGINATOR_OVERRIDE=codex_sdk_mbt"),
    )
  })
}

///|
async test "Codex run - throws TurnFailed on turn failures" {
  with_fake_codex(async fn(fixture) {
    let events = [
      "{\"type\":\"thread.started\",\"thread_id\":\"thread-1\"}",
      "{\"type\":\"turn.started\"}",
      "{\"type\":\"turn.failed\",\"error\":{\"message\":\"rate limit exceeded\"}}",
    ].join("\n")
    let thread = fixture
      .client(fixture.environment([events]))
      .start_thread()
    let message = try {
      thread.run(Prompt("fail")) |> ignore
      "no error"
    } catch {
      CodexSdkError::TurnFailed(message~) => message
      error => "unexpected:\{error}"
    }
    inspect(message, content="rate limit exceeded")
  })
}
