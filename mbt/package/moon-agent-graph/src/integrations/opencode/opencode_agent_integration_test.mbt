// OpenCode CLI and JSONL contracts:
// https://opencode.ai/docs/cli/
// https://github.com/anomalyco/opencode/blob/1e17856ba4b5b052650c8115060852f3f023844e/packages/opencode/src/cli/cmd/run.ts#L416-L428

///|
struct OpenCodeCliFixture {
  root : String
  executable : @path.Path
  record_directory : String
}

///|
async fn create_opencode_cli_fixture() -> OpenCodeCliFixture {
  let root = @fs.tmpdir(prefix="moon-agent-opencode-cli-")
  let executable = @path.Path(root).join(@path.Path("opencode"))
  let record_directory = @path.Path(root)
    .join(@path.Path("records"))
    .to_string()
  @fs.mkdir(record_directory, recursive=true)
  @fs.write_file(
    executable.to_string(),
    opencode_cli_fixture_script(),
    create_mode=CreateOrTruncate,
  )
  @fs.chmod(executable.to_string(), 0o755)
  { root, executable, record_directory }
}

///|
async fn with_opencode_cli_fixture(
  run : async (OpenCodeCliFixture) -> Unit,
) -> Unit {
  let fixture = create_opencode_cli_fixture()
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
fn OpenCodeCliFixture::environment(
  self : OpenCodeCliFixture,
  events_by_call : Array[String],
) -> Map[String, String] {
  let environment : Map[String, String] = {
    "FAKE_OPENCODE_RECORD_DIR": self.record_directory,
    "SHARED": "adapter",
  }
  for index, events in events_by_call {
    environment["FAKE_OPENCODE_EVENTS_\{index + 1}"] = events
  }
  environment
}

///|
async fn OpenCodeCliFixture::recorded_lines(
  self : OpenCodeCliFixture,
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
async fn OpenCodeCliFixture::recorded_text(
  self : OpenCodeCliFixture,
  name : String,
  call : Int,
) -> String {
  @fs.read_file("\{self.record_directory}/\{name}.\{call}").text()
}

///|
fn opencode_cli_completed_events(session_id : String, text : String) -> String {
  [
    "{\"type\":\"step_start\",\"timestamp\":1,\"sessionID\":\"\{session_id}\",\"part\":{\"type\":\"step-start\"}}",
    "{\"type\":\"text\",\"timestamp\":2,\"sessionID\":\"\{session_id}\",\"part\":{\"type\":\"text\",\"text\":\{Json::string(text).stringify()}}}",
    "{\"type\":\"step_finish\",\"timestamp\":3,\"sessionID\":\"\{session_id}\",\"part\":{\"type\":\"step-finish\",\"reason\":\"stop\",\"cost\":0,\"tokens\":{\"total\":0,\"input\":0,\"output\":0,\"reasoning\":0,\"cache\":{\"read\":0,\"write\":0}}}}",
  ].join("\n")
}

///|
fn opencode_cli_fixture_script() -> String {
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
fn opencode_cli_contains_pair(
  args : Array[String],
  key : String,
  value : String,
) -> Bool {
  args
  .iter2()
  .iter()
  .any(fn(entry) {
    let (index, item) = entry
    item == key && args.get(index + 1) == Some(value)
  })
}

///|
fn opencode_cli_context(
  fixture : OpenCodeCliFixture,
  group : @async.TaskGroup[Unit],
  environment? : Map[String, String] = Map([]),
) -> @core.CodingAgentOpenContext {
  @core.CodingAgentOpenContext::{
    run_id: @core.RunId::parse("opencode-cli-integration") catch {
      _ => abort("fixture run ID must be valid")
    },
    task_group: group,
    workspace: @core.WorkspaceRef::{
      root: @path.Path(fixture.root),
      additional_writable_roots: [],
    },
    approval: @core.Never,
    network: @core.Disabled,
    environment: @immut_hashmap.HashMap(environment.to_array()),
    events: @core.EventSink::discard(),
  }
}

///|
fn opencode_cli_agent(
  fixture : OpenCodeCliFixture,
  environment : Map[String, String],
  resume_thread_id? : String,
) -> @core.CodingAgent {
  opencode_agent(
    @core.CodingAgentId::parse("opencode-cli") catch {
      _ => abort("fixture agent ID must be valid")
    },
    OpenCodeAgentOptions::OpenCodeAgentOptions(
      opencode_path_override=fixture.executable,
      resume_thread_id?,
      model="test/model",
      agent="build",
      variant="high",
      title="graph run",
      thinking=true,
      extra_env=environment,
    ),
  )
}

///|
async fn opencode_cli_wait_for_file(path : String) -> Unit {
  @async.with_timeout(2000, async fn() {
    while !@fs.exists(path) {
      @async.pause()
    }
  })
}

///|
async fn opencode_cli_process_is_running(pid : Int) -> Bool {
  let (code, _, _) = @process.collect_output("kill", ["-0", pid.to_string()])
  code == 0
}

///|
async test "opencode_agent CLI integration 1 - maps requests and reuses the session ID" {
  with_opencode_cli_fixture(async fn(fixture) {
    @async.with_task_group(async fn(group) {
      let environment = fixture.environment([
        opencode_cli_completed_events("session-1", "First"),
        opencode_cli_completed_events("session-1", "Second"),
      ])
      let session = (opencode_cli_agent(fixture, environment).open)(
        opencode_cli_context(fixture, group, environment={
          "CALLER": "active",
          "SHARED": "caller",
        }),
      )
      assert_eq(session.id(), None)
      let first = session.execute(@core.CodingAgentRequest::{
        instruction: "first",
        context_files: [@path.Path("README.md"), @path.Path("/shared/guide.md")],
      })
      assert_eq(first.summary, Some("First"))
      assert_eq(first.continuation_id, Some("session-1"))
      assert_eq(first.changed_files, [])
      assert_eq(first.artifacts.length(), 0)
      assert_eq(first.raw_output, None)
      let second = session.execute(@core.CodingAgentRequest::{
        instruction: "second",
        context_files: [],
      })
      assert_eq(second.summary, Some("Second"))
      assert_eq(session.id().map(id => id.to_string()), Some("session-1"))

      let first_args = fixture.recorded_lines("args", 1)
      assert_eq(first_args[0], "run")
      assert_true(opencode_cli_contains_pair(first_args, "--format", "json"))
      assert_true(
        opencode_cli_contains_pair(first_args, "--model", "test/model"),
      )
      assert_true(opencode_cli_contains_pair(first_args, "--agent", "build"))
      assert_true(opencode_cli_contains_pair(first_args, "--dir", fixture.root))
      assert_true(opencode_cli_contains_pair(first_args, "--variant", "high"))
      assert_true(
        opencode_cli_contains_pair(first_args, "--title", "graph run"),
      )
      assert_true(first_args.contains("--thinking"))
      assert_true(
        opencode_cli_contains_pair(
          first_args,
          "--file",
          @path.Path(fixture.root).join(@path.Path("README.md")).to_string(),
        ),
      )
      assert_true(
        opencode_cli_contains_pair(first_args, "--file", "/shared/guide.md"),
      )
      assert_eq(fixture.recorded_text("input", 1), "first")
      assert_true(
        opencode_cli_contains_pair(
          fixture.recorded_lines("args", 2),
          "--session",
          "session-1",
        ),
      )
      let recorded_env = fixture.recorded_lines("env", 1)
      assert_true(recorded_env.contains("CALLER=active"))
      assert_true(recorded_env.contains("SHARED=caller"))

      session.close()
      session.close()
      let closed = try {
        session.execute(@core.CodingAgentRequest::{
          instruction: "after close",
          context_files: [],
        })
        |> ignore
        false
      } catch {
        OpenCodeAdapterError::SessionClosed => true
        _ => false
      }
      assert_true(closed)
    })
  })
}

///|
async test "opencode_agent CLI integration 2 - resumes a configured session" {
  with_opencode_cli_fixture(async fn(fixture) {
    @async.with_task_group(async fn(group) {
      let environment = fixture.environment([
        opencode_cli_completed_events("session-7", "Resumed"),
      ])
      let session = (opencode_cli_agent(
        fixture,
        environment,
        resume_thread_id="session-7",
      ).open)(opencode_cli_context(fixture, group))
      assert_eq(session.id().map(id => id.to_string()), Some("session-7"))
      let response = session.execute(@core.CodingAgentRequest::{
        instruction: "continue",
        context_files: [],
      })
      assert_eq(response.summary, Some("Resumed"))
      assert_true(
        opencode_cli_contains_pair(
          fixture.recorded_lines("args", 1),
          "--session",
          "session-7",
        ),
      )
      session.close()
    })
  })
}

///|
async test "opencode_agent CLI integration 3 - preserves process failure" {
  with_opencode_cli_fixture(async fn(fixture) {
    @async.with_task_group(async fn(group) {
      let environment = fixture.environment([])
      environment["FAKE_OPENCODE_EXIT_CODE"] = "17"
      environment["FAKE_OPENCODE_STDERR"] = "cli failed"
      let session = (opencode_cli_agent(fixture, environment).open)(
        opencode_cli_context(fixture, group),
      )
      let message = try {
        session.execute(@core.CodingAgentRequest::{
          instruction: "fail",
          context_files: [],
        })
        |> ignore
        "no error"
      } catch {
        @sdk.OpenCodeSdkError::ExecFailed(code~, stderr~) => "\{code}:\{stderr}"
        error => "unexpected: \{error}"
      }
      assert_eq(message, "17:cli failed")
      session.close()
    })
  })
}

///|
async test "opencode_agent CLI integration 4 - cancellation stops the child process" {
  with_opencode_cli_fixture(async fn(fixture) {
    @async.with_task_group(async fn(group) {
      let environment = fixture.environment([])
      environment["FAKE_OPENCODE_PAUSE"] = "1"
      let session = (opencode_cli_agent(fixture, environment).open)(
        opencode_cli_context(fixture, group),
      )
      let task = group.spawn(
        async fn() {
          session.execute(@core.CodingAgentRequest::{
            instruction: "pause",
            context_files: [],
          })
          |> ignore
        },
        allow_failure=true,
      )
      let pid_path = "\{fixture.record_directory}/pid.1"
      opencode_cli_wait_for_file(pid_path)
      let pid = @string.parse_int(
        @fs.read_file(pid_path).text().trim(),
        base=10,
      )
      assert_true(opencode_cli_process_is_running(pid))
      task.cancel()
      let cancelled = try {
        task.wait()
        false
      } catch {
        error => @async.is_cancellation_error(error)
      }
      assert_true(cancelled)
      assert_false(opencode_cli_process_is_running(pid))
      session.close()
    })
  })
}
