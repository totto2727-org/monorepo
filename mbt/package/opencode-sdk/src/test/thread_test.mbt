///|
using @opencode {
  type OpenCode,
  type OpenCodeOptions,
  type ThreadEvent,
  type ThreadOptions,
}

///|
async test "OpenCode run 1 - returns a completed turn" {
  with_fake_opencode(async fn(fixture) {
    let client = fixture.client(
      fixture.environment([completed_events("session-1", "Hello!")]),
    )
    let thread = client.start_thread(
      options=ThreadOptions::ThreadOptions(model="test/model"),
    )
    let turn = thread.run(@opencode.Prompt("Say hello"))
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
    thread.run(@opencode.Prompt("first")) |> ignore
    let turn = thread.run(@opencode.Prompt("second"))
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
    let turn = thread.run(@opencode.Prompt("continue"))
    assert_eq(thread.id(), Some("session-7"))
    inspect(turn.final_response, content="Resumed")
    assert_true(
      contains_pair(fixture.recorded_lines("args", 1), "--session", "session-7"),
    )
  })
}

// MoonBit-only fake executable for the OpenCode CLI JSONL contract.
// Official CLI: https://dev.opencode.ai/docs/cli/
// Canonical JSONL emitter: https://github.com/anomalyco/opencode/blob/1e17856ba4b5b052650c8115060852f3f023844e/packages/opencode/src/cli/cmd/run.ts#L678-L691

///|
priv struct FakeOpenCode {
  root : String
  executable : @path.Path
  record_directory : String
}

///|
async fn create_fake_opencode() -> FakeOpenCode {
  let root = @fs.tmpdir(prefix="opencode-sdk-mbt-test-")
  let executable = @path.Path(root) |> @path.Path::join(@path.Path("opencode"))
  let record_directory = (root |> @path.Path::join(@path.Path("records"))).to_string()
  @fs.mkdir(record_directory, recursive=true)
  @fs.write_file(
    executable.to_string(),
    fake_opencode_script(),
    create_mode=CreateOrTruncate,
  )
  @fs.chmod(executable.to_string(), 0o755)
  { root, executable, record_directory }
}

///|
async fn with_fake_opencode(run : async (FakeOpenCode) -> Unit) -> Unit {
  let fixture = create_fake_opencode()
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
fn FakeOpenCode::environment(
  self : FakeOpenCode,
  events_by_call : Array[String],
) -> Map[String, String] {
  let environment : Map[String, String] = {
    "PATH": "/usr/bin:/bin",
    "FAKE_OPENCODE_RECORD_DIR": self.record_directory,
  }
  for index, events in events_by_call {
    environment.set("FAKE_OPENCODE_EVENTS_\{index + 1}", events)
  }
  environment
}

///|
fn FakeOpenCode::client(
  self : FakeOpenCode,
  environment : Map[String, String],
) -> OpenCode {
  OpenCode::OpenCode(
    options=OpenCodeOptions::OpenCodeOptions(
      opencode_path_override=self.executable,
      env=environment,
    ),
  )
}

///|
async fn FakeOpenCode::recorded_lines(
  self : FakeOpenCode,
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
async fn FakeOpenCode::recorded_text(
  self : FakeOpenCode,
  name : String,
  call : Int,
) -> String {
  @fs.read_file("\{self.record_directory}/\{name}.\{call}").text()
}

///|
fn completed_events(session_id : String, text : String) -> String {
  [
    "{\"type\":\"step_start\",\"timestamp\":1,\"sessionID\":\"\{session_id}\",\"part\":{\"type\":\"step-start\"}}",
    "{\"type\":\"text\",\"timestamp\":2,\"sessionID\":\"\{session_id}\",\"part\":{\"type\":\"text\",\"text\":\{Json::string(text).stringify()}}}",
    "{\"type\":\"step_finish\",\"timestamp\":3,\"sessionID\":\"\{session_id}\",\"part\":{\"type\":\"step-finish\",\"reason\":\"stop\",\"cost\":0,\"tokens\":{\"total\":0,\"input\":0,\"output\":0,\"reasoning\":0,\"cache\":{\"read\":0,\"write\":0}}}}",
  ].join("\n")
}

///|
fn fake_opencode_script() -> String {
  let script =
    #|#!/bin/sh
    #|set -eu
    #|record_dir="${FAKE_OPENCODE_RECORD_DIR:?}"
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
    #|printf '%s\n' "$$" > "$record_dir/pid.$call"
    #|case "$call" in
    #|  1) events="${FAKE_OPENCODE_EVENTS_1-}" ;;
    #|  2) events="${FAKE_OPENCODE_EVENTS_2-}" ;;
    #|  3) events="${FAKE_OPENCODE_EVENTS_3-}" ;;
    #|  *) events="${FAKE_OPENCODE_EVENTS-}" ;;
    #|esac
    #|if [ -n "$events" ]; then printf '%s\n' "$events"; fi
    #|if [ -n "${FAKE_OPENCODE_STDERR-}" ]; then
    #|  printf '%s' "$FAKE_OPENCODE_STDERR" >&2
    #|fi
    #|if [ "${FAKE_OPENCODE_PAUSE-}" = "1" ]; then /bin/sleep 30; fi
    #|exit "${FAKE_OPENCODE_EXIT_CODE-0}"
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
async test "OpenCode run_streamed - emits typed events" {
  with_fake_opencode(async fn(fixture) {
    let thread = fixture
      .client(fixture.environment([completed_events("session-1", "Streamed")]))
      .start_thread()
    let events : Array[ThreadEvent] = []
    thread.run_streamed(@opencode.Prompt("stream"), async fn(event) {
      events.push(event)
      @async.pause()
    })
    assert_eq(thread.id(), Some("session-1"))
    inspect(events.length(), content="3")
    match events[1] {
      @opencode.Text(event) => {
        inspect(event.session_id, content="session-1")
        inspect(event.text, content="Streamed")
      }
      _ => fail("expected text event")
    }
  })
}
