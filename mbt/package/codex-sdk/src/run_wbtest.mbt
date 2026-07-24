// Direct test port of https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/tests/run.test.ts
// allow: SIZE_OK — this file intentionally preserves the upstream run.test.ts case grouping.

///| Upstream test: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/tests/run.test.ts#L20
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

///| Upstream test: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/tests/run.test.ts#L53
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

///| Upstream test: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/tests/run.test.ts#L96
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

///| Upstream test: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/tests/run.test.ts#L140
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

///| Upstream test: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/tests/run.test.ts#L187
async test "Codex run - passes turn options to exec" {
  with_fake_codex(async fn(fixture) {
    let client = fixture.client(
      fixture.environment([
        completed_events("thread-1", "item-1", "Turn options applied"),
      ]),
    )
    client
    .start_thread(
      options=ThreadOptions::ThreadOptions(
        model="gpt-test-1",
        sandbox_mode=WorkspaceWrite,
      ),
    )
    .run(Prompt("apply options"))
    |> ignore
    let args = fixture.recorded_lines("args", 1)
    assert_true(contains_pair(args, "--model", "gpt-test-1"))
    assert_true(contains_pair(args, "--sandbox", "workspace-write"))
  })
}

///| Upstream test: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/tests/run.test.ts#L226
async test "Codex run - passes modelReasoningEffort to exec" {
  with_fake_codex(async fn(fixture) {
    let client = fixture.client(
      fixture.environment([
        completed_events("thread-1", "item-1", "Reasoning effort applied"),
      ]),
    )
    client
    .start_thread(
      options=ThreadOptions::ThreadOptions(model_reasoning_effort=High),
    )
    .run(Prompt("apply reasoning effort"))
    |> ignore
    assert_true(
      contains_pair(
        fixture.recorded_lines("args", 1),
        "--config",
        "model_reasoning_effort=\"high\"",
      ),
    )
  })
}

///| Upstream test: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/tests/run.test.ts#L257
async test "Codex run - passes networkAccessEnabled to exec" {
  with_fake_codex(async fn(fixture) {
    let client = fixture.client(
      fixture.environment([
        completed_events("thread-1", "item-1", "Network access applied"),
      ]),
    )
    client
    .start_thread(
      options=ThreadOptions::ThreadOptions(network_access_enabled=true),
    )
    .run(Prompt("apply network access"))
    |> ignore
    assert_true(
      contains_pair(
        fixture.recorded_lines("args", 1),
        "--config",
        "sandbox_workspace_write.network_access=true",
      ),
    )
  })
}

///| Upstream test: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/tests/run.test.ts#L288
async test "Codex run - passes webSearchEnabled to exec" {
  with_fake_codex(async fn(fixture) {
    let client = fixture.client(
      fixture.environment([
        completed_events("thread-1", "item-1", "Web search applied"),
      ]),
    )
    client
    .start_thread(
      options=ThreadOptions::ThreadOptions(web_search_enabled=true),
    )
    .run(Prompt("apply web search"))
    |> ignore
    assert_true(
      contains_pair(
        fixture.recorded_lines("args", 1),
        "--config",
        "web_search=\"live\"",
      ),
    )
  })
}

///| Upstream test: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/tests/run.test.ts#L319
async test "Codex run - passes webSearchMode to exec" {
  with_fake_codex(async fn(fixture) {
    let client = fixture.client(
      fixture.environment([
        completed_events("thread-1", "item-1", "Web search mode applied"),
      ]),
    )
    client
    .start_thread(
      options=ThreadOptions::ThreadOptions(web_search_mode=Cached),
    )
    .run(Prompt("apply web search mode"))
    |> ignore
    assert_true(
      contains_pair(
        fixture.recorded_lines("args", 1),
        "--config",
        "web_search=\"cached\"",
      ),
    )
  })
}

///| Upstream test: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/tests/run.test.ts#L350
async test "Codex run - passes webSearchEnabled false to exec" {
  with_fake_codex(async fn(fixture) {
    let client = fixture.client(
      fixture.environment([
        completed_events("thread-1", "item-1", "Web search disabled"),
      ]),
    )
    client
    .start_thread(
      options=ThreadOptions::ThreadOptions(web_search_enabled=false),
    )
    .run(Prompt("disable web search"))
    |> ignore
    assert_true(
      contains_pair(
        fixture.recorded_lines("args", 1),
        "--config",
        "web_search=\"disabled\"",
      ),
    )
  })
}

///| Upstream test: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/tests/run.test.ts#L381
async test "Codex run - passes approvalPolicy to exec" {
  with_fake_codex(async fn(fixture) {
    let client = fixture.client(
      fixture.environment([
        completed_events("thread-1", "item-1", "Approval applied"),
      ]),
    )
    client
    .start_thread(
      options=ThreadOptions::ThreadOptions(approval_policy=OnRequest),
    )
    .run(Prompt("apply approval"))
    |> ignore
    assert_true(
      contains_pair(
        fixture.recorded_lines("args", 1),
        "--config",
        "approval_policy=\"on-request\"",
      ),
    )
  })
}

///| Upstream test: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/tests/run.test.ts#L412
async test "Codex run - passes CodexOptions config overrides as TOML flags" {
  with_fake_codex(async fn(fixture) {
    let config : CodexConfigObject = {
      "approval_policy": ConfigString("never"),
      "sandbox_workspace_write": ConfigObject({
        "network_access": ConfigBool(true),
      }),
      "retry_budget": ConfigInt(3),
      "tool_rules": ConfigObject({
        "allow": ConfigArray([
          ConfigString("git status"),
          ConfigString("git diff"),
        ]),
      }),
    }
    let client = Codex::Codex(
      options=CodexOptions::CodexOptions(
        codex_path_override=fixture.executable,
        config=config,
        env=fixture.environment([
          completed_events("thread-1", "item-1", "Config applied"),
        ]),
      ),
    )
    client.start_thread().run(Prompt("apply config")) |> ignore
    json_inspect(
      values_after(fixture.recorded_lines("args", 1), "--config"),
      content=[
        "approval_policy=\"never\"",
        "sandbox_workspace_write.network_access=true",
        "retry_budget=3",
        "tool_rules.allow=[\"git status\", \"git diff\"]",
      ],
    )
  })
}

///| Upstream test: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/tests/run.test.ts#L453
async test "Codex run - lets thread options override CodexOptions config" {
  with_fake_codex(async fn(fixture) {
    let config : CodexConfigObject = {
      "approval_policy": ConfigString("never"),
    }
    let client = Codex::Codex(
      options=CodexOptions::CodexOptions(
        codex_path_override=fixture.executable,
        config=config,
        env=fixture.environment([
          completed_events("thread-1", "item-1", "Override applied"),
        ]),
      ),
    )
    client
    .start_thread(
      options=ThreadOptions::ThreadOptions(approval_policy=OnRequest),
    )
    .run(Prompt("apply override"))
    |> ignore
    json_inspect(
      values_after(fixture.recorded_lines("args", 1), "--config"),
      content=["approval_policy=\"never\"", "approval_policy=\"on-request\""],
    )
  })
}

///| Upstream test: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/tests/run.test.ts#L490
async test "Codex run - passes additionalDirectories as repeated flags" {
  with_fake_codex(async fn(fixture) {
    let client = fixture.client(
      fixture.environment([
        completed_events("thread-1", "item-1", "Directories applied"),
      ]),
    )
    client
    .start_thread(
      options=ThreadOptions::ThreadOptions(additional_directories=[
        @path.Path("/tmp/one"),
        @path.Path("/tmp/two"),
      ]),
    )
    .run(Prompt("apply directories"))
    |> ignore
    json_inspect(
      values_after(fixture.recorded_lines("args", 1), "--add-dir"),
      content=["/tmp/one", "/tmp/two"],
    )
  })
}

///| Upstream test: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/tests/run.test.ts#L532
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

///| Upstream test: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/tests/run.test.ts#L589
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

///| Upstream test: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/tests/run.test.ts#L618
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

///| Upstream test: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/tests/run.test.ts#L665
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

///| Upstream test: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/tests/run.test.ts#L701
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

///| Upstream test: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/tests/run.test.ts#L732
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

///| Upstream test: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/tests/run.test.ts#L755
async test "Codex run - throws TurnFailed on turn failures" {
  with_fake_codex(async fn(fixture) {
    let events = [
      "{\"type\":\"thread.started\",\"thread_id\":\"thread-1\"}",
      "{\"type\":\"turn.started\"}",
      "{\"type\":\"turn.failed\",\"error\":{\"message\":\"rate limit exceeded\"}}",
    ].join("\n")
    let environment = fixture.environment([events])
    environment.set("FAKE_CODEX_PAUSE", "1")
    let thread = fixture
      .client(environment)
      .start_thread()
    let message = try {
      @async.with_timeout(2000, async fn() {
        thread.run(Prompt("fail")) |> ignore
      })
      "no error"
    } catch {
      CodexSdkError::TurnFailed(message~) => message
      @async.TimeoutError => "timed out"
      error => "unexpected:\{error}"
    }
    inspect(message, content="rate limit exceeded")
  })
}
