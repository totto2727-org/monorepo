///|
pub suberror NativeTestHelperError {
  EventuallyTimedOut(timeout_ms~ : Int)
  InvalidEventuallyInterval(timeout_ms~ : Int, poll_ms~ : Int)
} derive(Debug)

///|
pub struct TemporaryWorkspace {
  root_value : @path.Path
  mut closed : Bool
}

///|
pub fn TemporaryWorkspace::root(self : TemporaryWorkspace) -> @path.Path {
  self.root_value
}

///|
pub async fn temporary_workspace(
  prefix? : String = "moon-agent-graph-test-",
) -> TemporaryWorkspace {
  let root = @fs.tmpdir(prefix~)
  TemporaryWorkspace::{ root_value: @path.Path(root), closed: false }
}

///|
pub async fn TemporaryWorkspace::close(self : TemporaryWorkspace) -> Unit {
  guard !self.closed else { return }
  @fs.rmdir(self.root_value.to_string(), recursive=true)
  self.closed = true
}

///|
pub async fn eventually(
  timeout_ms : Int,
  predicate : async () -> Bool,
  poll_ms? : Int = 10,
) -> Unit {
  guard timeout_ms >= 0 && poll_ms > 0 else {
    raise InvalidEventuallyInterval(timeout_ms~, poll_ms~)
  }
  let mut elapsed_ms = 0
  for ;; {
    if predicate() {
      return
    }
    if elapsed_ms >= timeout_ms {
      raise EventuallyTimedOut(timeout_ms~)
    }
    let delay_ms = poll_ms.min(timeout_ms - elapsed_ms)
    @async.sleep(delay_ms)
    elapsed_ms = elapsed_ms + delay_ms
  }
}

///|
pub async fn process_is_running(pid : Int) -> Bool {
  @process.collect_output("/bin/kill", ["-0", pid.to_string()]).0 == 0
}

///|
pub async fn localhost_port_is_open(
  port : Int,
  timeout_ms? : Int = 250,
) -> Bool {
  try {
    let connection = @async.with_timeout(timeout_ms, async fn() {
      @socket.Tcp::connect(@socket.Addr::parse("127.0.0.1:\{port}"))
    })
    connection.close()
    true
  } catch {
    error if @async.is_being_cancelled() || @async.is_cancellation_error(error) =>
      raise error
    _ => false
  }
}
