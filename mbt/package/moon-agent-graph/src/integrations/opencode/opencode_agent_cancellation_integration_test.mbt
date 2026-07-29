// Pinned OpenCode server lifecycle contract:
// https://github.com/anomalyco/opencode/blob/66495a2a22cd0a57efcc4f721e65532f0987b4e8/packages/sdk/js/src/server.ts

///|
struct OpenCodeCancellationFixture {
  root : String
  executable : String
  records : String
}

///|
async fn create_opencode_cancellation_fixture() -> OpenCodeCancellationFixture {
  let root = @fs.tmpdir(prefix="moon-agent-opencode-cancellation-")
  let executable = "\{root}/opencode"
  let records = "\{root}/records"
  @fs.mkdir(records, recursive=true)
  @fs.write_file(
    executable,
    (
      #|#!/bin/sh
      #|set -eu
      #|records="${FAKE_OPENCODE_RECORDS:?}"
      #|exec /usr/bin/python3 -u - "$records" <<'PY'
      #|import http.server, json, os, pathlib, sys
      #|records = pathlib.Path(sys.argv[1])
      #|(records / "pid").write_text(str(os.getpid()))
      #|fifo = records / "release"
      #|os.mkfifo(fifo)
      #|class Handler(http.server.BaseHTTPRequestHandler):
      #|    def log_message(self, *_): pass
      #|    def send_json(self, value):
      #|        data = json.dumps(value, separators=(",", ":")).encode()
      #|        self.send_response(200)
      #|        self.send_header("Content-Type", "application/json")
      #|        self.send_header("Content-Length", str(len(data)))
      #|        self.end_headers()
      #|        self.wfile.write(data)
      #|    def read_body(self):
      #|        if self.headers.get("Transfer-Encoding", "").lower() == "chunked":
      #|            chunks = []
      #|            while True:
      #|                size = int(self.rfile.readline().strip(), 16)
      #|                if size == 0:
      #|                    self.rfile.readline()
      #|                    break
      #|                chunks.append(self.rfile.read(size))
      #|                self.rfile.read(2)
      #|            return b"".join(chunks)
      #|        return self.rfile.read(int(self.headers.get("Content-Length", "0")))
      #|    def do_POST(self):
      #|        self.read_body()
      #|        if self.path == "/session":
      #|            self.send_json({"id": "ses-" + str(os.getpid())})
      #|        elif self.path.startswith("/session/") and self.path.endswith("/message"):
      #|            (records / "message-started").write_text("started")
      #|            with fifo.open("rb") as stream:
      #|                stream.read(1)
      #|            (records / "response-finished").write_text("finished")
      #|            self.send_json({"info": {}, "parts": []})
      #|        else:
      #|            self.send_response(404)
      #|            self.end_headers()
      #|server = http.server.HTTPServer(("127.0.0.1", 0), Handler)
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
fn opencode_cancellation_context(
  fixture : OpenCodeCancellationFixture,
  group : @async.TaskGroup[Unit],
) -> @core.CodingAgentOpenContext {
  @core.CodingAgentOpenContext::{
    run_id: @core.RunId::parse("opencode-cancellation") catch {
      _ => abort("integration run ID must be valid")
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
      "FAKE_OPENCODE_RECORDS": fixture.records,
    },
    events: @core.EventSink::discard(),
  }
}

///|
async fn opencode_cancellation_process_running(pid : String) -> Bool {
  @process.collect_output("/bin/kill", ["-0", pid.trim().to_owned()]).0 == 0
}

///|
async fn opencode_cancellation_listener_closed(port : String) -> Bool {
  @process.collect_output("/usr/bin/python3", [
    "-c", "import socket,sys;s=socket.socket();code=s.connect_ex(('127.0.0.1',int(sys.argv[1])));s.close();sys.exit(0 if code != 0 else 1)",
    port,
  ]).0 ==
  0
}

///|
fn opencode_cancellation_agent(
  fixture : OpenCodeCancellationFixture,
) -> @core.CodingAgent {
  opencode_agent(
    @core.CodingAgentId::parse("opencode-cancellation") catch {
      _ => abort("integration agent ID must be valid")
    },
    OpenCodeAgentOptions::OpenCodeAgentOptions(
      server_options=@sdk.ServerOptions::ServerOptions(port=0, timeout_ms=2000),
      command=fixture.executable,
      extra_env=Map([]),
      request_timeout_ms=10000,
    ),
  )
}

///|
async test "opencode_agent cancellation integration 1 - cancellation stops execution before close removes the server" {
  let fixture = create_opencode_cancellation_fixture()
  @async.with_task_group() <| group => {
    group.add_defer(() => @fs.rmdir(fixture.root, recursive=true))
    let agent = opencode_cancellation_agent(fixture)
    let session = (agent.open)(opencode_cancellation_context(fixture, group))
    let pid = @fs.read_file("\{fixture.records}/pid").text()
    let port = @fs.read_file("\{fixture.records}/port").text().trim().to_owned()
    let execute = group.spawn(
      async fn() {
        session.execute(@core.CodingAgentRequest::{
          instruction: "block until cancelled",
          context_files: [],
        })
        |> ignore
      },
      allow_failure=true,
    )
    let mut attempts = 0
    while !@fs.exists("\{fixture.records}/message-started") && attempts < 50 {
      @async.pause()
      attempts = attempts + 1
    }
    assert_true(@fs.exists("\{fixture.records}/message-started"))
    execute.cancel()
    let cancelled = try {
      execute.wait()
      false
    } catch {
      error => @async.is_cancellation_error(error)
    }
    assert_true(cancelled)
    assert_false(@fs.exists("\{fixture.records}/response-finished"))
    assert_true(opencode_cancellation_process_running(pid))
    session.close()
    assert_false(opencode_cancellation_process_running(pid))
    assert_true(opencode_cancellation_listener_closed(port))
  }
  assert_false(@fs.exists(fixture.root))
}

///|
async test "opencode_agent cancellation integration 2 - independent opens own distinct servers and close independently" {
  let first_fixture = create_opencode_cancellation_fixture()
  let second_fixture = create_opencode_cancellation_fixture()
  @async.with_task_group() <| first_group => {
    first_group.add_defer(() => @fs.rmdir(first_fixture.root, recursive=true))
    let first = (opencode_cancellation_agent(first_fixture).open)(
      opencode_cancellation_context(first_fixture, first_group),
    )
    let first_pid = @fs.read_file("\{first_fixture.records}/pid").text()
    let first_port = @fs.read_file("\{first_fixture.records}/port")
      .text()
      .trim()
      .to_owned()
    let first_id = match first.id() {
      Some(id) => id.to_string()
      None => abort("first integration session must expose its ID")
    }
    @async.with_task_group() <| second_group => {
      second_group.add_defer(() => {
        @fs.rmdir(second_fixture.root, recursive=true)
      })
      let second = (opencode_cancellation_agent(second_fixture).open)(
        opencode_cancellation_context(second_fixture, second_group),
      )
      let second_pid = @fs.read_file("\{second_fixture.records}/pid").text()
      let second_port = @fs.read_file("\{second_fixture.records}/port")
        .text()
        .trim()
        .to_owned()
      let second_id = match second.id() {
        Some(id) => id.to_string()
        None => abort("second integration session must expose its ID")
      }
      assert_true(opencode_cancellation_process_running(first_pid))
      assert_true(opencode_cancellation_process_running(second_pid))
      assert_true(first_pid != second_pid)
      assert_true(first_port != second_port)
      assert_true(first_id != second_id)
      first.close()
      assert_false(opencode_cancellation_process_running(first_pid))
      assert_true(opencode_cancellation_listener_closed(first_port))
      assert_true(opencode_cancellation_process_running(second_pid))
      second.close()
      assert_false(opencode_cancellation_process_running(second_pid))
      assert_true(opencode_cancellation_listener_closed(second_port))
    }
    assert_false(@fs.exists(second_fixture.root))
  }
  assert_false(@fs.exists(first_fixture.root))
}
