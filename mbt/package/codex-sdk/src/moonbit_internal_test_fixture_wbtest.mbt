// MoonBit-only native fake replacing the upstream Jest child-process spy, HTTP responses proxy, test client, and CODEX_HOME hooks.
// Upstream child-process spy: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/tests/codexExecSpy.ts
// Upstream responses proxy: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/tests/responsesProxy.ts
// Upstream test client: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/tests/testCodex.ts
// Upstream CODEX_HOME hooks: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/tests/setupCodexHome.ts
// This file is intentionally prefixed moonbit_internal_ because MoonBit tests cannot use the upstream Node/Jest and HTTP proxy machinery.

priv struct FakeCodex {
  root : String
  executable : @path.Path
  record_directory : String
}

async fn create_fake_codex() -> FakeCodex {
  let root = @fs.tmpdir(prefix="codex-sdk-mbt-test-")
  let executable = @path.Path(root) |> @path.Path::join(@path.Path("codex"))
  let record_directory = (root
  |> @path.Path::join(@path.Path("records"))).to_string()
  @fs.mkdir(record_directory, recursive=true)
  @fs.write_file(
    executable.to_string(),
    fake_codex_script(),
    create_mode=CreateOrTruncate,
  )
  @fs.chmod(executable.to_string(), 0o755)
  { root, executable, record_directory }
}

async fn with_fake_codex(run : async (FakeCodex) -> Unit raise) -> Unit raise {
  let fixture = create_fake_codex()
  try run(fixture) catch {
    error => {
      @async.protect_from_cancel(async fn() {
        @fs.rmdir(fixture.root, recursive=true)
      })
      raise error
    }
  }
  @fs.rmdir(fixture.root, recursive=true)
}

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

async fn FakeCodex::recorded_text(
  self : FakeCodex,
  name : String,
  call : Int,
) -> String {
  @fs.read_file("\{self.record_directory}/\{name}.\{call}").text()
}

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

fn contains_pair(args : Array[String], key : String, value : String) -> Bool {
  args.iter2().iter().any(fn(entry) {
    let (index, item) = entry
    item == key && args.get(index + 1) == Some(value)
  })
}

fn values_after(args : Array[String], key : String) -> Array[String] {
  args
  .iter2()
  .iter()
  .filter_map(fn(entry) {
    let (index, item) = entry
    if item == key { args.get(index + 1) } else { None }
  })
  .collect()
}
