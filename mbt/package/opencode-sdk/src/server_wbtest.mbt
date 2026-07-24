///|
async fn write_fake_opencode(root : String) -> String {
  let path = "\{root}/opencode"
  let script =
    #|#!/bin/sh
    #|printf '%s\n' "$$" > "$OPENCODE_TEST_PID_FILE"
    #|printf '%s\n' "$@" > "$OPENCODE_TEST_ARGS_FILE"
    #|printf '%s' "$OPENCODE_CONFIG_CONTENT" > "$OPENCODE_TEST_CONFIG_FILE"
    #|case "$OPENCODE_TEST_MODE" in
    #|  ready)
    #|    printf 'noise before readiness\n'
    #|    printf 'opencode server listening on http://127.0.0.1:43210\n'
    #|    while :; do sleep 1; done
    #|    ;;
    #|  malformed)
    #|    printf 'opencode server listening without a url\n'
    #|    while :; do sleep 1; done
    #|    ;;
    #|  timeout)
    #|    while :; do sleep 1; done
    #|    ;;
    #|  exit)
    #|    printf 'fake startup failure\n' >&2
    #|    exit 23
    #|    ;;
    #|esac
  @fs.write_file(path, script, create_mode=CreateOrTruncate, permission=0o755)
  @fs.chmod(path, 0o755)
  path
}

///|
fn fixture_env(root : String, mode : String) -> Map[String, String] {
  {
    "OPENCODE_TEST_MODE": mode,
    "OPENCODE_TEST_PID_FILE": "\{root}/pid",
    "OPENCODE_TEST_ARGS_FILE": "\{root}/args",
    "OPENCODE_TEST_CONFIG_FILE": "\{root}/config",
  }
}

///|
async fn fixture_pid(root : String) -> Int {
  @string.parse_int(@fs.read_file("\{root}/pid").text().trim(), base=10)
}

///|
async fn process_is_running(pid : Int) -> Bool {
  let (code, _, _) = @process.collect_output(
    "kill",
    ["-0", pid.to_string()],
  )
  code == 0
}

///|
// Upstream contract:
// https://github.com/anomalyco/opencode/blob/66495a2a22cd0a57efcc4f721e65532f0987b4e8/packages/sdk/js/src/server.ts#L22-L99
test "ServerOptions ServerOptions 1 - applies TypeScript SDK defaults" {
  debug_inspect(
    ServerOptions::ServerOptions(),
    content=(
      #|{
      #|  hostname: "127.0.0.1",
      #|  port: 4096,
      #|  timeout_ms: 5000,
      #|  config: Object({}),
      #|}
    ),
  )
}

///|
test "Server server_args 1 - forwards config log level" {
  let options = ServerOptions::ServerOptions(
    hostname="0.0.0.0",
    port=8080,
    config=Json::object({ "logLevel": "debug".to_json() }),
  )
  json_inspect(server_args(options), content=[
    "serve", "--hostname=0.0.0.0", "--port=8080", "--log-level=debug",
  ])
}

///|
test "Server parse_server_url 1 - accepts accumulated readiness output" {
  debug_inspect(
    parse_server_url(
      "noise\nopencode server listening on http://127.0.0.1:43210\n",
    ),
    content="Some(\"http://127.0.0.1:43210\")",
  )
}

///|
test "panic_Server parse_server_url 2 - rejects malformed readiness output" {
  try! (
    parse_server_url("opencode server listening without a url") |> ignore
  )
}

///|
async test "Server create 1 - starts from readiness and closes idempotently" {
  let root = @fs.tmpdir(prefix="opencode-sdk-ready-")
  @async.with_task_group() <| group => {
    group.add_defer(() => @fs.rmdir(root, recursive=true))
    let command = write_fake_opencode(root)
    let config = Json::object({
      "logLevel": "debug".to_json(),
      "model": "test/model".to_json(),
    })
    let server = create_opencode_server_with_command(
      group,
      ServerOptions::ServerOptions(timeout_ms=1000, config~),
      command,
      fixture_env(root, "ready"),
    )
    inspect(server.url(), content="http://127.0.0.1:43210")
    let moonllm_config : @moonllm.ClientBuilder = server.moonllm_config()
    moonllm_config.build() |> ignore
    inspect(
      @fs.read_file("\{root}/args").text(),
      content=(
        #|serve
        #|--hostname=127.0.0.1
        #|--port=4096
        #|--log-level=debug
        #|
      ),
    )
    json_inspect(
      @json.parse(@fs.read_file("\{root}/config").text()),
      content={ "logLevel": "debug", "model": "test/model" },
    )
    let pid = fixture_pid(root)
    assert_true(process_is_running(pid))
    server.close()
    server.close()
    assert_false(process_is_running(pid))
  }
}

///|
async test "Server create 2 - rejects malformed readiness and stops child" {
  let root = @fs.tmpdir(prefix="opencode-sdk-malformed-")
  @async.with_task_group() <| group => {
    group.add_defer(() => @fs.rmdir(root, recursive=true))
    let command = write_fake_opencode(root)
    let result = try {
      create_opencode_server_with_command(
        group,
        ServerOptions::ServerOptions(timeout_ms=1000),
        command,
        fixture_env(root, "malformed"),
      )
      |> ignore
      "missing error"
    } catch {
      MalformedOutput(line~) => "malformed: \{line}"
      err => "unexpected: \{@debug.to_string(err)}"
    }
    inspect(
      result,
      content="malformed: opencode server listening without a url",
    )
    assert_false(process_is_running(fixture_pid(root)))
  }
}

///|
async test "Server create 3 - times out and stops child" {
  let root = @fs.tmpdir(prefix="opencode-sdk-timeout-")
  @async.with_task_group() <| group => {
    group.add_defer(() => @fs.rmdir(root, recursive=true))
    let command = write_fake_opencode(root)
    let result = try {
      create_opencode_server_with_command(
        group,
        ServerOptions::ServerOptions(timeout_ms=1000),
        command,
        fixture_env(root, "timeout"),
      )
      |> ignore
      "missing error"
    } catch {
      StartTimeout(timeout_ms~, ..) => "timeout: \{timeout_ms}"
      err => "unexpected: \{@debug.to_string(err)}"
    }
    inspect(result, content="timeout: 1000")
    assert_false(process_is_running(fixture_pid(root)))
  }
}

///|
async test "Server create 4 - reports early exit and leaves no child" {
  let root = @fs.tmpdir(prefix="opencode-sdk-exit-")
  @async.with_task_group() <| group => {
    group.add_defer(() => @fs.rmdir(root, recursive=true))
    let command = write_fake_opencode(root)
    let result = try {
      create_opencode_server_with_command(
        group,
        ServerOptions::ServerOptions(timeout_ms=1000),
        command,
        fixture_env(root, "exit"),
      )
      |> ignore
      "missing error"
    } catch {
      ServerExited(code~, output~) => "exit \{code}: \{output.trim()}"
      err => "unexpected: \{@debug.to_string(err)}"
    }
    inspect(result, content="exit 23: fake startup failure")
    assert_false(process_is_running(fixture_pid(root)))
  }
}
