///|
async test "temporary_workspace 1 - creates unique roots and closes idempotently" {
  let first = temporary_workspace(prefix="moon-agent-graph-first-")
  let second = temporary_workspace(prefix="moon-agent-graph-second-")
  let first_root = first.root().to_string()
  let second_root = second.root().to_string()
  assert_true(first_root != second_root)
  assert_true(@fs.exists(first_root))
  assert_true(@fs.exists(second_root))
  first.close()
  first.close()
  second.close()
  second.close()
  assert_false(@fs.exists(first_root))
  assert_false(@fs.exists(second_root))
}

///|
async test "eventually 1 - succeeds after polling and raises a bounded timeout" {
  let attempts = Ref(0)
  eventually(
    100,
    fn() {
      attempts.val = attempts.val + 1
      attempts.val == 3
    },
    poll_ms=1,
  )
  inspect(attempts.val, content="3")
  let timeout = try {
    eventually(5, fn() { false }, poll_ms=1)
    "missing error"
  } catch {
    NativeTestHelperError::EventuallyTimedOut(timeout_ms~) =>
      "timeout:\{timeout_ms}"
    error => "unexpected:\{error}"
  }
  inspect(timeout, content="timeout:5")
}

///|
async test "native state probes 1 - observe live and closed process and localhost port" {
  @async.with_task_group() <| group => {
    let process = @process.spawn(
      group,
      "/bin/sleep",
      ["30"],
      cancel_handler=@process.hard_cancel(),
    )
    assert_true(process_is_running(process.pid))
    process.cancel()
    (process.wait() |> ignore) catch {
      error if @async.is_cancellation_error(error) => ()
      error => raise error
    }
    eventually(500, async fn() { !process_is_running(process.pid) })
    assert_false(process_is_running(process.pid))
    let server = @socket.TcpServer(@socket.Addr::parse("127.0.0.1:0"))
    let port = server.addr.port()
    assert_true(localhost_port_is_open(port))
    server.close()
    eventually(500, async fn() { !localhost_port_is_open(port) })
    assert_false(localhost_port_is_open(port))
  }
}
