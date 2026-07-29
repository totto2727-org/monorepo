///|
struct OpenCodeFailureFixture {
  root : String
  executable : String
  records : String
}

///|
async fn opencode_failure_fixture() -> OpenCodeFailureFixture {
  let root = @fs.tmpdir(prefix="moon-agent-opencode-failure-")
  let executable = "\{root}/opencode"
  let records = "\{root}/records"
  @fs.mkdir(records, recursive=true)
  @fs.write_file(
    executable,
    (
      #|#!/bin/sh
      #|set -eu
      #|records="${FAKE_OPENCODE_FAILURE_RECORDS:?}"
      #|mode="${FAKE_OPENCODE_FAILURE_MODE:?}"
      #|exec /usr/bin/python3 -u - "$records" "$mode" <<'PY'
      #|import http.server, pathlib, sys
      #|records = pathlib.Path(sys.argv[1])
      #|mode = sys.argv[2]
      #|class Handler(http.server.BaseHTTPRequestHandler):
      #|    def log_message(self, *_): pass
      #|    def record(self):
      #|        size = int(self.headers.get("Content-Length", "0"))
      #|        self.rfile.read(size)
      #|        with (records / "requests").open("a") as stream:
      #|            stream.write(self.path + "\n")
      #|    def respond(self, code, body):
      #|        data = body.encode()
      #|        self.send_response(code)
      #|        self.send_header("Content-Type", "application/json")
      #|        self.send_header("Content-Length", str(len(data)))
      #|        self.end_headers()
      #|        self.wfile.write(data)
      #|    def do_POST(self):
      #|        self.record()
      #|        if self.path == "/session" and mode == "create-503":
      #|            self.respond(503, "create unavailable")
      #|        elif self.path == "/session":
      #|            self.respond(200, '{"id":"ses-failure"}')
      #|        elif self.path == "/session/ses-failure/message":
      #|            self.respond(500, "message unavailable")
      #|        else:
      #|            self.respond(404, "not found")
      #|server = http.server.HTTPServer(("127.0.0.1", 0), Handler)
      #|(records / "pid").write_text(str(__import__("os").getpid()))
      #|(records / "port").write_text(str(server.server_address[1]))
      #|print("opencode server listening on http://127.0.0.1:" + str(server.server_address[1]), flush=True)
      #|server.serve_forever()
      #|PY
      #|
    ),
    create_mode=CreateOrTruncate,
  )
  @fs.chmod(executable, 0o755)
  { root, executable, records }
}

///|
async fn with_opencode_failure_fixture(
  run : async (OpenCodeFailureFixture) -> Unit,
) -> String {
  let fixture = opencode_failure_fixture()
  run(fixture) catch {
    error => {
      @async.protect_from_cancel(async fn() {
        @fs.rmdir(fixture.root, recursive=true)
      })
      raise error
    }
  }
  @fs.rmdir(fixture.root, recursive=true)
  fixture.root
}

///|
fn opencode_failure_context(
  fixture : OpenCodeFailureFixture,
  group : @async.TaskGroup[Unit],
  mode : String,
) -> @core.CodingAgentOpenContext {
  @core.CodingAgentOpenContext::{
    run_id: @core.RunId::parse("opencode-failure") catch {
      _ => abort("failure-test run ID must be valid")
    },
    task_group: group,
    workspace: @core.WorkspaceRef::{
      root: @path.Path(fixture.root),
      additional_writable_roots: [],
    },
    approval: @core.Never,
    network: @core.Disabled,
    environment: {
      "PATH": "/usr/bin:/bin",
      "FAKE_OPENCODE_FAILURE_RECORDS": fixture.records,
      "FAKE_OPENCODE_FAILURE_MODE": mode,
    },
    events: @core.EventSink::discard(),
  }
}

///|
fn opencode_failure_agent(
  fixture : OpenCodeFailureFixture,
) -> @core.CodingAgent {
  opencode_agent(
    @core.CodingAgentId::parse("opencode-failure") catch {
      _ => abort("failure-test agent ID must be valid")
    },
    OpenCodeAgentOptions::OpenCodeAgentOptions(
      server_options=@sdk.ServerOptions::ServerOptions(port=0, timeout_ms=2000),
      command=fixture.executable,
      request_timeout_ms=2000,
    ),
  )
}

///|
async fn opencode_failure_process_running(pid : String) -> Bool {
  @process.collect_output("/bin/kill", ["-0", pid.trim().to_owned()]).0 == 0
}

///|
async fn opencode_failure_listener_closed(port : String) -> Bool {
  let (code, _, _) = @process.collect_output("/usr/bin/python3", [
    "-c",
    "import socket,sys;s=socket.socket();code=s.connect_ex(('127.0.0.1',int(sys.argv[1])));s.close();sys.exit(0 if code != 0 else 1)",
    port.trim().to_owned(),
  ])
  code == 0
}

///|
async test "opencode_agent failure integration 1 - closes the server after a session 503 without sending a message" {
  let root = with_opencode_failure_fixture(async fn(fixture) {
    @async.with_task_group() <| group => {
      let result = try {
        (opencode_failure_agent(fixture).open)(
          opencode_failure_context(fixture, group, "create-503"),
        )
        |> ignore
        "no error"
      } catch {
        @moonllm.ApiError(code~, message~) => "\{code}:\{message}"
        error => "unexpected:\{error}"
      }
      inspect(result, content="503:create unavailable")
      let requests = @fs.read_file("\{fixture.records}/requests").text()
      inspect(requests, content="/session\n")
      assert_false(requests.contains("/message"))
      let pid = @fs.read_file("\{fixture.records}/pid").text()
      let port = @fs.read_file("\{fixture.records}/port").text()
      assert_false(opencode_failure_process_running(pid))
      assert_true(opencode_failure_listener_closed(port))
    }
  })
  assert_false(@fs.exists(root))
}

///|
async test "opencode_agent failure integration 2 - preserves message 500 then rejects execute after close" {
  let root = with_opencode_failure_fixture(async fn(fixture) {
    @async.with_task_group() <| group => {
      let session = (opencode_failure_agent(fixture).open)(
        opencode_failure_context(fixture, group, "message-500"),
      )
      let result = try {
        session.execute(@core.CodingAgentRequest::{
          instruction: "fail",
          context_files: [],
        })
        |> ignore
        "no error"
      } catch {
        @moonllm.ApiError(code~, message~) => "\{code}:\{message}"
        error => "unexpected:\{error}"
      }
      inspect(result, content="500:message unavailable")
      let requests = @fs.read_file("\{fixture.records}/requests").text()
      inspect(requests, content="/session\n/session/ses-failure/message\n")
      let pid = @fs.read_file("\{fixture.records}/pid").text()
      let port = @fs.read_file("\{fixture.records}/port").text()
      session.close()
      assert_false(opencode_failure_process_running(pid))
      assert_true(opencode_failure_listener_closed(port))
      let closed = try {
        session.execute(@core.CodingAgentRequest::{
          instruction: "after close",
          context_files: [],
        })
        |> ignore
        "no error"
      } catch {
        OpenCodeAdapterError::SessionClosed => "SessionClosed"
        error => "unexpected:\{error}"
      }
      inspect(closed, content="SessionClosed")
      inspect(
        @fs.read_file("\{fixture.records}/requests").text(),
        content=requests,
      )
    }
  })
  assert_false(@fs.exists(root))
}
