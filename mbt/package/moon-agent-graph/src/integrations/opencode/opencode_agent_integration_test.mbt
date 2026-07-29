// Pinned OpenCode server contract:
// https://github.com/anomalyco/opencode/blob/66495a2a22cd0a57efcc4f721e65532f0987b4e8/packages/sdk/js/src/server.ts

///|
struct OpenCodeIntegrationFixture {
  root : String
  executable : String
  records : String
}

///|
async fn create_opencode_integration_fixture() -> OpenCodeIntegrationFixture {
  let root = @fs.tmpdir(prefix="moon-agent-opencode-integration-")
  let executable = "\{root}/opencode"
  let records = "\{root}/records"
  @fs.mkdir(records, recursive=true)
  @fs.write_file(
    executable,
    (
      #|#!/bin/sh
      #|set -eu
      #|records="${FAKE_OPENCODE_RECORDS:?}"
      #|printf '%s\n' "$@" > "$records/args"
      #|printf '%s' "$OPENCODE_CONFIG_CONTENT" > "$records/config"
      #|printf '%s|%s' "${OPTION_ENV-}" "${CONTEXT_ENV-}" > "$records/env"
      #|exec /usr/bin/python3 -u - "$records" <<'PY'
      #|import http.server, json, os, pathlib, sys
      #|records = pathlib.Path(sys.argv[1])
      #|(records / "pid").write_text(str(os.getpid()))
      #|class Handler(http.server.BaseHTTPRequestHandler):
      #|    messages = 0
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
      #|            return b"".join(chunks).decode()
      #|        return self.rfile.read(int(self.headers.get("Content-Length", "0"))).decode()
      #|    def do_POST(self):
      #|        body = self.read_body()
      #|        with (records / "requests").open("a") as stream:
      #|            stream.write(self.path + "\t" + body + "\n")
      #|        if self.path == "/session":
      #|            self.send_json({"id": "ses-local"})
      #|        elif self.path == "/session/ses-local/message":
      #|            Handler.messages += 1
      #|            self.send_json({"info": {}, "parts": [{"type": "text", "text": "summary-" + str(Handler.messages)}]})
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
async fn opencode_integration_process_running(pid : String) -> Bool {
  @process.collect_output("/bin/kill", ["-0", pid.trim().to_owned()]).0 == 0
}

///|
fn opencode_integration_context(
  fixture : OpenCodeIntegrationFixture,
  group : @async.TaskGroup[Unit],
) -> @core.CodingAgentOpenContext {
  @core.CodingAgentOpenContext::{
    run_id: @core.RunId::parse("opencode-integration") catch {
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
      "CONTEXT_ENV": "context",
    },
    events: @core.EventSink::discard(),
  }
}

///|
async test "opencode_agent integration 1 - reuses one local process and session for two messages" {
  let fixture = create_opencode_integration_fixture()
  @async.with_task_group() <| group => {
    group.add_defer(() => @fs.rmdir(fixture.root, recursive=true))
    let agent = opencode_agent(
      @core.CodingAgentId::parse("opencode-integration"),
      OpenCodeAgentOptions::OpenCodeAgentOptions(
        server_options=@sdk.ServerOptions::ServerOptions(
          port=0,
          timeout_ms=2000,
          config=Json::object({
            "logLevel": "debug".to_json(),
            "model": "local/test".to_json(),
          }),
        ),
        command=fixture.executable,
        extra_env={ "OPTION_ENV": "option" },
        request_timeout_ms=2000,
      ),
    )
    let session = (agent.open)(opencode_integration_context(fixture, group))
    let first = session.execute(@core.CodingAgentRequest::{
      instruction: "first instruction",
      context_files: [@path.Path("README.md")],
    })
    let second = session.execute(@core.CodingAgentRequest::{
      instruction: "second instruction",
      context_files: [],
    })
    debug_inspect(first.summary, content="Some(\"summary-1\")")
    debug_inspect(first.continuation_id, content="Some(\"ses-local\")")
    debug_inspect(second.summary, content="Some(\"summary-2\")")
    debug_inspect(second.continuation_id, content="Some(\"ses-local\")")
    guard first.raw_output is Some(raw) else { fail("missing raw response") }
    assert_true(raw.stringify().contains("summary-1"))
    let requests = @fs.read_file("\{fixture.records}/requests").text()
    inspect(
      requests.split("\n").filter(line => line != "").count(),
      content="3",
    )
    assert_true(requests.contains("/session\t"))
    assert_true(requests.contains("/session/ses-local/message\t"))
    assert_true(requests.contains("first instruction"))
    assert_true(requests.contains("\{fixture.root}/README.md"))
    assert_true(requests.contains("second instruction"))
    inspect(
      @fs.read_file("\{fixture.records}/env").text(),
      content="option|context",
    )
    assert_true(
      @fs.read_file("\{fixture.records}/config")
      .text()
      .contains("\"model\":\"local/test\""),
    )
    let args = @fs.read_file("\{fixture.records}/args").text()
    assert_true(args.contains("serve"))
    assert_true(args.contains("--hostname=127.0.0.1"))
    assert_true(args.contains("--port=0"))
    let pid = @fs.read_file("\{fixture.records}/pid").text()
    let port = @fs.read_file("\{fixture.records}/port").text().trim().to_owned()
    assert_true(opencode_integration_process_running(pid))
    session.close()
    assert_false(opencode_integration_process_running(pid))
    let (connect_code, _, _) = @process.collect_output("/usr/bin/python3", [
      "-c", "import socket,sys;s=socket.socket();code=s.connect_ex(('127.0.0.1',int(sys.argv[1])));s.close();sys.exit(0 if code != 0 else 1)",
      port,
    ])
    inspect(connect_code, content="0")
  }
  assert_false(@fs.exists(fixture.root))
}
