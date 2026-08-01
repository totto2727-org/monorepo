// Direct test port of https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/tests/run.test.ts

///|
using @codex {
  type Codex,
  type CodexConfigObject,
  type CodexOptions,
  type ThreadEvent,
  type ThreadOptions,
  type TurnOptions,
}
// allow: SIZE_OK — this file intentionally preserves the upstream run.test.ts case grouping.

///|
/// Upstream test: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/tests/run.test.ts#L20
async test "Codex run - returns thread events" {
  with_fake_codex(async fn(fixture) {
    let client = fixture.client(
      fixture.environment([completed_events("thread-1", "item-1", "Hi!")]),
    )
    let thread = client.start_thread()
    let turn = thread.run(@codex.Prompt("Hello, world!"))
    assert_eq(thread.id(), Some("thread-1"))
    inspect(turn.final_response, content="Hi!")
    inspect(turn.items.length(), content="1")
    match turn.items[0] {
      @codex.AgentMessage(message) => inspect(message.text, content="Hi!")
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
/// Upstream test: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/tests/run.test.ts#L53
async test "Codex run - sends previous items when called twice" {
  with_fake_codex(async fn(fixture) {
    let client = fixture.client(
      fixture.environment([
        completed_events("thread-1", "item-1", "First response"),
        completed_events("thread-1", "item-2", "Second response"),
      ]),
    )
    let thread = client.start_thread()
    thread.run(@codex.Prompt("first input")) |> ignore
    thread.run(@codex.Prompt("second input")) |> ignore
    let second_args = fixture.recorded_lines("args", 2)
    assert_true(contains_pair(second_args, "resume", "thread-1"))
    inspect(fixture.recorded_text("input", 2), content="second input")
  })
}

///|
/// Upstream test: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/tests/run.test.ts#L96
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
        sandbox_mode=@codex.WorkspaceWrite,
      ),
    )
    thread.run(@codex.Prompt("first input")) |> ignore
    thread.run(@codex.Prompt("second input")) |> ignore
    let second_args = fixture.recorded_lines("args", 2)
    assert_true(contains_pair(second_args, "resume", "thread-1"))
    assert_true(contains_pair(second_args, "--model", "gpt-test-1"))
    assert_true(contains_pair(second_args, "--sandbox", "workspace-write"))
  })
}

///|
/// Upstream test: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/tests/run.test.ts#L140
async test "Codex resumeThread - resumes thread by ID" {
  with_fake_codex(async fn(fixture) {
    let client = fixture.client(
      fixture.environment([
        completed_events("thread-1", "item-1", "First response"),
        completed_events("thread-1", "item-2", "Second response"),
      ]),
    )
    let original = client.start_thread()
    original.run(@codex.Prompt("first input")) |> ignore
    let resumed = client.resume_thread(original.id().unwrap_or(""))
    let turn = resumed.run(@codex.Prompt("second input"))
    assert_eq(resumed.id(), Some("thread-1"))
    inspect(turn.final_response, content="Second response")
    assert_true(
      contains_pair(fixture.recorded_lines("args", 2), "resume", "thread-1"),
    )
  })
}

///|
/// Upstream test: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/tests/run.test.ts#L187
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
        sandbox_mode=@codex.WorkspaceWrite,
      ),
    )
    .run(@codex.Prompt("apply options"))
    |> ignore
    let args = fixture.recorded_lines("args", 1)
    assert_true(contains_pair(args, "--model", "gpt-test-1"))
    assert_true(contains_pair(args, "--sandbox", "workspace-write"))
  })
}

///|
/// Upstream test: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/tests/run.test.ts#L226
async test "Codex run - passes modelReasoningEffort to exec" {
  with_fake_codex(async fn(fixture) {
    let client = fixture.client(
      fixture.environment([
        completed_events("thread-1", "item-1", "Reasoning effort applied"),
      ]),
    )
    client
    .start_thread(
      options=ThreadOptions::ThreadOptions(model_reasoning_effort=@codex.High),
    )
    .run(@codex.Prompt("apply reasoning effort"))
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

///|
/// Upstream test: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/tests/run.test.ts#L257
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
    .run(@codex.Prompt("apply network access"))
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

///|
/// Upstream test: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/tests/run.test.ts#L288
async test "Codex run - passes webSearchEnabled to exec" {
  with_fake_codex(async fn(fixture) {
    let client = fixture.client(
      fixture.environment([
        completed_events("thread-1", "item-1", "Web search applied"),
      ]),
    )
    client
    .start_thread(options=ThreadOptions::ThreadOptions(web_search_enabled=true))
    .run(@codex.Prompt("apply web search"))
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

///|
/// Upstream test: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/tests/run.test.ts#L319
async test "Codex run - passes webSearchMode to exec" {
  with_fake_codex(async fn(fixture) {
    let client = fixture.client(
      fixture.environment([
        completed_events("thread-1", "item-1", "Web search mode applied"),
      ]),
    )
    client
    .start_thread(options=ThreadOptions::ThreadOptions(web_search_mode=@codex.Cached))
    .run(@codex.Prompt("apply web search mode"))
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

///|
/// Upstream test: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/tests/run.test.ts#L350
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
    .run(@codex.Prompt("disable web search"))
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

///|
/// Upstream test: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/tests/run.test.ts#L381
async test "Codex run - passes approvalPolicy to exec" {
  with_fake_codex(async fn(fixture) {
    let client = fixture.client(
      fixture.environment([
        completed_events("thread-1", "item-1", "Approval applied"),
      ]),
    )
    client
    .start_thread(
      options=ThreadOptions::ThreadOptions(approval_policy=@codex.OnRequest),
    )
    .run(@codex.Prompt("apply approval"))
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

///|
/// Upstream test: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/tests/run.test.ts#L412
async test "Codex run - passes CodexOptions config overrides as TOML flags" {
  with_fake_codex(async fn(fixture) {
    let config : CodexConfigObject = {
      "approval_policy": @codex.ConfigString("never"),
      "sandbox_workspace_write": @codex.ConfigObject({
        "network_access": @codex.ConfigBool(true),
      }),
      "retry_budget": @codex.ConfigInt(3),
      "tool_rules": @codex.ConfigObject({
        "allow": @codex.ConfigArray([
          @codex.ConfigString("git status"),
          @codex.ConfigString("git diff"),
        ]),
      }),
    }
    let client = Codex::Codex(
      options=CodexOptions::CodexOptions(
        codex_path_override=fixture.executable,
        config~,
        env=fixture.environment([
          completed_events("thread-1", "item-1", "Config applied"),
        ]),
      ),
    )
    client.start_thread().run(@codex.Prompt("apply config")) |> ignore
    json_inspect(values_after(fixture.recorded_lines("args", 1), "--config"), content=[
      "approval_policy=\"never\"", "sandbox_workspace_write.network_access=true",
      "retry_budget=3", "tool_rules.allow=[\"git status\", \"git diff\"]",
    ])
  })
}

///|
/// Upstream test: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/tests/run.test.ts#L453
async test "Codex run - lets thread options override CodexOptions config" {
  with_fake_codex(async fn(fixture) {
    let config : CodexConfigObject = {
      "approval_policy": @codex.ConfigString("never"),
    }
    let client = Codex::Codex(
      options=CodexOptions::CodexOptions(
        codex_path_override=fixture.executable,
        config~,
        env=fixture.environment([
          completed_events("thread-1", "item-1", "Override applied"),
        ]),
      ),
    )
    client
    .start_thread(
      options=ThreadOptions::ThreadOptions(approval_policy=@codex.OnRequest),
    )
    .run(@codex.Prompt("apply override"))
    |> ignore
    json_inspect(values_after(fixture.recorded_lines("args", 1), "--config"), content=[
      "approval_policy=\"never\"", "approval_policy=\"on-request\"",
    ])
  })
}

///|
/// Upstream test: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/tests/run.test.ts#L490
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
    .run(@codex.Prompt("apply directories"))
    |> ignore
    json_inspect(values_after(fixture.recorded_lines("args", 1), "--add-dir"), content=[
      "/tmp/one", "/tmp/two",
    ])
  })
}

///|
/// Upstream test: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/tests/run.test.ts#L532
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
      @codex.Prompt("structured"),
      turn_options=TurnOptions::TurnOptions(output_schema=schema),
    )
    |> ignore
    inspect(fixture.recorded_text("schema", 1), content=schema.stringify())
    let schema_path = fixture.recorded_text("schema_path", 1)
    inspect(@fs.exists(schema_path), content="false")
  })
}

///|
/// Upstream test: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/tests/run.test.ts#L589
async test "Codex run - combines structured text input segments" {
  with_fake_codex(async fn(fixture) {
    let client = fixture.client(
      fixture.environment([
        completed_events("thread-1", "item-1", "Combined input applied"),
      ]),
    )
    client
    .start_thread()
    .run(
      @codex.UserInputs([
        @codex.Text("Describe file changes"),
        @codex.Text("Focus on impacted tests"),
      ]),
    )
    |> ignore
    inspect(
      fixture.recorded_text("input", 1),
      content="Describe file changes\n\nFocus on impacted tests",
    )
  })
}

///|
/// Upstream test: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/tests/run.test.ts#L618
async test "Codex run - forwards images to exec" {
  with_fake_codex(async fn(fixture) {
    let client = fixture.client(
      fixture.environment([
        completed_events("thread-1", "item-1", "Images applied"),
      ]),
    )
    client
    .start_thread()
    .run(
      @codex.UserInputs([
        @codex.Text("describe the images"),
        @codex.LocalImage(@path.Path("first.png")),
        @codex.LocalImage(@path.Path("second.jpg")),
      ]),
    )
    |> ignore
    inspect(
      values_after(fixture.recorded_lines("args", 1), "--image").join(","),
      content="first.png,second.jpg",
    )
  })
}

///|
/// Upstream test: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/tests/run.test.ts#L665
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
    .run(@codex.Prompt("use custom working directory"))
    |> ignore
    let args = fixture.recorded_lines("args", 1)
    assert_true(contains_pair(args, "--cd", "/tmp/work"))
    assert_true(args.contains("--skip-git-repo-check"))
  })
}

///|
/// Upstream test: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/tests/run.test.ts#L701
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
      thread.run(@codex.Prompt("use custom working directory")) |> ignore
      "no error"
    } catch {
      @codex.CodexSdkError::ExecFailed(code~, stderr~) =>
        "\{code}:\{stderr.trim()}"
      error => "unexpected:\{error}"
    }
    inspect(detail, content="1:Not inside a trusted directory")
  })
}

///|
/// Upstream test: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/tests/run.test.ts#L732
async test "Codex run - sets the Codex SDK originator" {
  with_fake_codex(async fn(fixture) {
    let client = fixture.client(
      fixture.environment([completed_events("thread-1", "item-1", "Hi!")]),
    )
    client.start_thread().run(@codex.Prompt("Hello, originator!")) |> ignore
    assert_true(
      fixture
      .recorded_lines("env", 1)
      .contains("CODEX_INTERNAL_ORIGINATOR_OVERRIDE=codex_sdk_mbt"),
    )
  })
}

///|
/// Upstream test: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/tests/run.test.ts#L755
async test "Codex run - throws TurnFailed on turn failures" {
  with_fake_codex(async fn(fixture) {
    let events = [
      "{\"type\":\"thread.started\",\"thread_id\":\"thread-1\"}", "{\"type\":\"turn.started\"}",
      "{\"type\":\"turn.failed\",\"error\":{\"message\":\"rate limit exceeded\"}}",
    ].join("\n")
    let environment = fixture.environment([events])
    environment.set("FAKE_CODEX_PAUSE", "1")
    let thread = fixture.client(environment).start_thread()
    let message = try {
      @async.with_timeout(2000, async fn() {
        thread.run(@codex.Prompt("fail")) |> ignore
      })
      "no error"
    } catch {
      @codex.CodexSdkError::@codex.TurnFailed(message~) => message
      @async.TimeoutError => "timed out"
      error => "unexpected:\{error}"
    }
    inspect(message, content="rate limit exceeded")
  })
}

// MoonBit-only native fake replacing the upstream Jest child-process spy, HTTP responses proxy, test client, and CODEX_HOME hooks.
// Upstream child-process spy: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/tests/codexExecSpy.ts
// Upstream responses proxy: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/tests/responsesProxy.ts
// Upstream test client: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/tests/testCodex.ts
// Upstream CODEX_HOME hooks: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/tests/setupCodexHome.ts
// This file is intentionally prefixed moonbit_internal_ because MoonBit tests cannot use the upstream Node/Jest and HTTP proxy machinery.

///|
priv struct FakeCodex {
  root : String
  executable : @path.Path
  record_directory : String
}

///|
async fn create_fake_codex() -> FakeCodex {
  let root = @fs.tmpdir(prefix="codex-sdk-mbt-test-")
  let executable = @path.Path(root) |> @path.Path::join(@path.Path("codex"))
  let record_directory = (root |> @path.Path::join(@path.Path("records"))).to_string()
  @fs.mkdir(record_directory, recursive=true)
  @fs.write_file(
    executable.to_string(),
    fake_codex_script(),
    create_mode=CreateOrTruncate,
  )
  @fs.chmod(executable.to_string(), 0o755)
  { root, executable, record_directory }
}

///|
async fn with_fake_codex(run : async (FakeCodex) -> Unit) -> Unit {
  let fixture = create_fake_codex()
  run(fixture) catch {
    error => {
      @async.protect_from_cancel(async fn() {
        @fs.rmdir(fixture.root, recursive=true)
      })
      raise error
    }
  }
  @fs.rmdir(fixture.root, recursive=true)
}

///|
fn FakeCodex::environment(
  self : FakeCodex,
  events_by_call : Array[String],
) -> Map[String, String] {
  let environment : Map[String, String] = {
    "PATH": "/usr/bin:/bin",
    "FAKE_CODEX_RECORD_DIR": self.record_directory,
  }
  for index, events in events_by_call {
    environment.set("FAKE_CODEX_EVENTS_\{index + 1}", events)
  }
  environment
}

///|
fn FakeCodex::client(
  self : FakeCodex,
  environment : Map[String, String],
) -> Codex {
  Codex::Codex(
    options=CodexOptions::CodexOptions(
      codex_path_override=self.executable,
      env=environment,
    ),
  )
}

///|
async fn FakeCodex::recorded_lines(
  self : FakeCodex,
  name : String,
  call : Int,
) -> Array[String] {
  @fs.read_file("\{self.record_directory}/\{name}.\{call}")
  .text()
  .split("\n")
  .filter_map(line => if line == "" { None } else { Some(line.to_owned()) })
  .collect()
}

///|
async fn FakeCodex::recorded_text(
  self : FakeCodex,
  name : String,
  call : Int,
) -> String {
  @fs.read_file("\{self.record_directory}/\{name}.\{call}").text()
}

///|
fn completed_events(
  thread_id : String,
  item_id : String,
  text : String,
) -> String {
  [
    "{\"type\":\"thread.started\",\"thread_id\":\"\{thread_id}\"}",
    "{\"type\":\"turn.started\"}",
    "{\"type\":\"item.completed\",\"item\":{\"id\":\"\{item_id}\",\"type\":\"agent_message\",\"text\":\{Json::string(text).stringify()}}}",
    "{\"type\":\"turn.completed\",\"usage\":{\"input_tokens\":42,\"cached_input_tokens\":12,\"output_tokens\":5,\"reasoning_output_tokens\":0}}",
  ].join("\n")
}

///|
fn fake_codex_script() -> String {
  let script =
    #|#!/bin/sh
    #|set -eu
    #|record_dir="${FAKE_CODEX_RECORD_DIR:?}"
    #|counter_file="$record_dir/counter"
    #|if [ -f "$counter_file" ]; then
    #|  call=$(/bin/cat "$counter_file")
    #|else
    #|  call=0
    #|fi
    #|call=$((call + 1))
    #|printf '%s' "$call" > "$counter_file"
    #|: > "$record_dir/args.$call"
    #|for arg in "$@"; do
    #|  printf '%s\n' "$arg" >> "$record_dir/args.$call"
    #|done
    #|/bin/cat > "$record_dir/input.$call"
    #|/usr/bin/env | /usr/bin/sort > "$record_dir/env.$call"
    #|previous=
    #|for arg in "$@"; do
    #|  if [ "$previous" = "--output-schema" ]; then
    #|    /bin/cp "$arg" "$record_dir/schema.$call"
    #|    printf '%s' "$arg" > "$record_dir/schema_path.$call"
    #|  fi
    #|  previous="$arg"
    #|done
    #|if [ "${FAKE_CODEX_REJECT_UNTRUSTED-}" = "1" ]; then
    #|  has_skip=0
    #|  for arg in "$@"; do
    #|    if [ "$arg" = "--skip-git-repo-check" ]; then has_skip=1; fi
    #|  done
    #|  if [ "$has_skip" = "0" ]; then
    #|    printf '%s\n' 'Not inside a trusted directory' >&2
    #|    exit 1
    #|  fi
    #|fi
    #|case "$call" in
    #|  1) events="${FAKE_CODEX_EVENTS_1-}" ;;
    #|  2) events="${FAKE_CODEX_EVENTS_2-}" ;;
    #|  3) events="${FAKE_CODEX_EVENTS_3-}" ;;
    #|  *) events="${FAKE_CODEX_EVENTS-}" ;;
    #|esac
    #|if [ -n "$events" ]; then printf '%s\n' "$events"; fi
    #|if [ -n "${FAKE_CODEX_STDERR-}" ]; then
    #|  printf '%s' "$FAKE_CODEX_STDERR" >&2
    #|fi
    #|if [ "${FAKE_CODEX_HOLD_STDOUT-}" = "1" ]; then
    #|  (/bin/sleep 30) 2>/dev/null &
    #|fi
    #|if [ "${FAKE_CODEX_PAUSE-}" = "1" ]; then /bin/sleep 30; fi
    #|exit "${FAKE_CODEX_EXIT_CODE-0}"
    #|
  script
}

///|
fn contains_pair(args : Array[String], key : String, value : String) -> Bool {
  args
  .iter2()
  .iter()
  .any(fn(entry) {
    let (index, item) = entry
    item == key && args.get(index + 1) == Some(value)
  })
}

///|
fn values_after(args : Array[String], key : String) -> Array[String] {
  args
  .iter2()
  .iter()
  .filter_map(fn(entry) {
    let (index, item) = entry
    if item == key {
      args.get(index + 1)
    } else {
      None
    }
  })
  .collect()
}

// Direct test port of https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/tests/runStreamed.test.ts

// MoonBit-only assertion adapter for comparing callback events without TypeScript object matchers.
// Corresponding upstream assertion: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/tests/runStreamed.test.ts#L24-L55

///|
fn moonbit_internal_streamed_event_summary(event : ThreadEvent) -> String {
  match event {
    @codex.ThreadStarted(started) => "thread.started:\{started.thread_id}"
    @codex.TurnStarted(_) => "turn.started"
    @codex.ItemCompleted({ item: @codex.AgentMessage(message) }) =>
      "item.completed:\{message.id}:\{message.text}"
    @codex.TurnCompleted(completed) =>
      "turn.completed:\{completed.usage.input_tokens}:\{completed.usage.output_tokens}"
    @codex.TurnFailed(failed) => "turn.failed:\{failed.error.message}"
    @codex.ItemStarted(_) => "item.started"
    @codex.ItemUpdated(_) => "item.updated"
    @codex.ItemCompleted(_) => "item.completed"
    @codex.StreamError(error) => "error:\{error.message}"
  }
}

///|
/// Upstream test: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/tests/runStreamed.test.ts#L15
async test "Codex runStreamed - returns thread events" {
  with_fake_codex(async fn(fixture) {
    let client = fixture.client(
      fixture.environment([completed_events("thread-1", "item-1", "Hi!")]),
    )
    let thread = client.start_thread()
    let events : Array[String] = []
    thread.run_streamed(@codex.Prompt("Hello, world!"), async fn(event) {
      events.push(moonbit_internal_streamed_event_summary(event))
      @async.pause()
    })
    json_inspect(events, content=[
      "thread.started:thread-1", "turn.started", "item.completed:item-1:Hi!", "turn.completed:42:5",
    ])
    assert_eq(thread.id(), Some("thread-1"))
  })
}

///|
/// Upstream test: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/tests/runStreamed.test.ts#L65
async test "Codex runStreamed - sends previous items when called twice" {
  with_fake_codex(async fn(fixture) {
    let client = fixture.client(
      fixture.environment([
        completed_events("thread-1", "item-1", "First response"),
        completed_events("thread-1", "item-2", "Second response"),
      ]),
    )
    let thread = client.start_thread()
    thread.run_streamed(@codex.Prompt("first input"), async fn(_) { @async.pause() })
    thread.run_streamed(@codex.Prompt("second input"), async fn(_) { @async.pause() })
    let second_args = fixture.recorded_lines("args", 2)
    assert_true(contains_pair(second_args, "resume", "thread-1"))
    inspect(fixture.recorded_text("input", 2), content="second input")
  })
}

///|
/// Upstream test: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/tests/runStreamed.test.ts#L111
async test "Codex runStreamed - resumes thread by ID" {
  with_fake_codex(async fn(fixture) {
    let client = fixture.client(
      fixture.environment([
        completed_events("thread-1", "item-1", "First response"),
        completed_events("thread-1", "item-1", "Resumed response"),
      ]),
    )
    let original = client.start_thread()
    original.run_streamed(@codex.Prompt("first input"), async fn(_) { @async.pause() })
    let resumed = client.resume_thread(original.id().unwrap_or(""))
    resumed.run_streamed(@codex.Prompt("second input"), async fn(_) { @async.pause() })
    assert_true(
      contains_pair(fixture.recorded_lines("args", 2), "resume", "thread-1"),
    )
    assert_eq(resumed.id(), original.id())
  })
}

///|
/// Upstream test: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/tests/runStreamed.test.ts#L159
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
      @codex.Prompt("structured"),
      async fn(_) { @async.pause() },
      turn_options=TurnOptions::TurnOptions(output_schema=schema),
    )
    inspect(fixture.recorded_text("schema", 1), content=schema.stringify())
    let schema_path = fixture.recorded_text("schema_path", 1)
    assert_eq(@fs.exists(schema_path), false)
  })
}

// Direct test port of https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/tests/abort.test.ts

// MoonBit-only deterministic synchronization for the upstream setTimeout-based execution test.
// Corresponding upstream test: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/tests/abort.test.ts#L82

///|
async fn moonbit_internal_wait_for_test_file(path : String) -> Unit {
  @async.with_timeout(2000, async fn() {
    while !@fs.exists(path) {
      @async.pause()
    }
  })
}

// MoonBit-only assertion adapter for AbortSignal rejection semantics.
// Corresponding upstream cancellation assertions: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/tests/abort.test.ts#L21-L140

///|
async fn moonbit_internal_wait_for_cancellation(
  task : @async.Task[Unit],
) -> Bool {
  try {
    task.wait()
    false
  } catch {
    error => @async.is_cancellation_error(error)
  }
}

///|
/// Upstream test: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/tests/abort.test.ts#L21
async test "Codex run - cancels when task is cancelled" {
  with_fake_codex(async fn(fixture) {
    let environment = fixture.environment([
      completed_events("thread-1", "item-1", "Hi!"),
    ])
    environment.set("FAKE_CODEX_PAUSE", "1")
    let thread = fixture.client(environment).start_thread()
    @async.with_task_group(async fn(group) {
      let task = group.spawn(
        async fn() { thread.run(@codex.Prompt("Hello")) |> ignore },
        allow_failure=true,
      )
      task.cancel()
      assert_true(moonbit_internal_wait_for_cancellation(task))
    })
  })
}

///|
/// Upstream test: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/tests/abort.test.ts#L43
async test "Codex runStreamed - cancels when task is cancelled" {
  with_fake_codex(async fn(fixture) {
    let environment = fixture.environment([
      completed_events("thread-1", "item-1", "Hi!"),
    ])
    environment.set("FAKE_CODEX_PAUSE", "1")
    let thread = fixture.client(environment).start_thread()
    let events : Array[ThreadEvent] = []
    @async.with_task_group(async fn(group) {
      let task = group.spawn(
        async fn() {
          thread.run_streamed(@codex.Prompt("Hello"), async fn(event) {
            events.push(event)
            @async.pause()
          })
        },
        allow_failure=true,
      )
      task.cancel()
      assert_true(moonbit_internal_wait_for_cancellation(task))
    })
    assert_eq(events.length(), 0)
  })
}

///|
/// Upstream test: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/tests/abort.test.ts#L82
async test "Codex run - cancels during execution" {
  with_fake_codex(async fn(fixture) {
    let environment = fixture.environment([
      completed_events("thread-1", "item-1", "Hi!"),
    ])
    environment.set("FAKE_CODEX_PAUSE", "1")
    let thread = fixture.client(environment).start_thread()
    @async.with_task_group(async fn(group) {
      let task = group.spawn(
        async fn() { thread.run(@codex.Prompt("Hello")) |> ignore },
        allow_failure=true,
      )
      moonbit_internal_wait_for_test_file("\{fixture.record_directory}/args.1")
      task.cancel()
      assert_true(moonbit_internal_wait_for_cancellation(task))
    })
  })
}

///|
/// Upstream test: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/tests/abort.test.ts#L108
async test "Codex runStreamed - cancels during iteration" {
  with_fake_codex(async fn(fixture) {
    let environment = fixture.environment([
      completed_events("thread-1", "item-1", "Hi!"),
    ])
    let started : @aqueue.Queue[Unit] = @aqueue.Queue(kind=@aqueue.Unbounded)
    let release : @aqueue.Queue[Unit] = @aqueue.Queue(kind=@aqueue.Unbounded)
    let thread = fixture.client(environment).start_thread()
    @async.with_task_group(async fn(group) {
      let task = group.spawn(
        async fn() {
          thread.run_streamed(@codex.Prompt("Hello"), async fn(_) {
            started.put(())
            release.get()
          })
        },
        allow_failure=true,
      )
      started.get()
      task.cancel()
      assert_true(moonbit_internal_wait_for_cancellation(task))
    })
  })
}

///|
/// Upstream test: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/tests/abort.test.ts#L143
async test "Codex run - completes normally when task is not cancelled" {
  with_fake_codex(async fn(fixture) {
    let client = fixture.client(
      fixture.environment([completed_events("thread-1", "item-1", "Hi!")]),
    )
    let result = client.start_thread().run(@codex.Prompt("Hello"))
    inspect(result.final_response, content="Hi!")
  })
}
