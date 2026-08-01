///|
suberror LifecycleTestError {
  LifecycleOpenFailed(String)
  LifecycleCloseFailed(String)
} derive(Debug)

///|
enum LifecycleClosePlan {
  Succeeds
  Fails(String)
  Sleeps(Int)
} derive(Debug)

///|
struct LifecycleSession {
  id : SessionId?
  label : String
  closed : Array[String]
  plan : LifecycleClosePlan
}

///|
impl CodingAgentSession for LifecycleSession with fn id(self) {
  self.id
}

///|
impl CodingAgentSession for LifecycleSession with fn execute(self, _request) {
  @async.pause()
  CodingAgentResponse::{
    status: Succeeded,
    summary: Some(self.label),
    continuation_id: None,
    changed_files: [],
    artifacts: [],
    raw_output: None,
  }
}

///|
impl CodingAgentSession for LifecycleSession with fn close(self) {
  match self.plan {
    Succeeds => self.closed.push(self.label)
    Fails(message) => {
      self.closed.push(self.label)
      raise LifecycleCloseFailed(message)
    }
    Sleeps(milliseconds) => {
      self.closed.push("\{self.label}:started")
      @async.sleep(milliseconds)
      self.closed.push("\{self.label}:finished")
    }
  }
}

///|
fn lifecycle_session(
  label : String,
  closed : Array[String],
  plan : LifecycleClosePlan,
) -> &CodingAgentSession {
  let session = LifecycleSession::{ id: None, label, closed, plan }
  (session : &CodingAgentSession)
}

///|
async test "RuntimeResourceStore lifecycle 1 - preserves an open error and retries a later acquisition" {
  let store = RuntimeResourceStore::RuntimeResourceStore()
  let closed : Array[String] = []
  let mut opens = 0
  let key = ResourceKey::parse("retry-open")
  let first_error = try {
    store.acquire_agent_session(key, Run, async fn() {
      @async.pause()
      opens = opens + 1
      raise LifecycleOpenFailed("first")
    })
    |> ignore
    false
  } catch {
    error => {
      let rendered = @debug.to_string(error)
      inspect(
        rendered.contains("LifecycleOpenFailed(\"first\")"),
        content="true",
      )
      true
    }
  }
  inspect(first_error, content="true")
  let session = store.acquire_agent_session(key, Run, async fn() {
    @async.pause()
    opens = opens + 1
    lifecycle_session("retry", closed, Succeeds)
  })
  debug_inspect(session.id(), content="None")
  inspect(opens, content="2")
}

///|
async test "RuntimeResourceStore lifecycle 2 - rejects a node session without its owner" {
  let store = RuntimeResourceStore::RuntimeResourceStore()
  let key = ResourceKey::parse("owner-required")
  let detail = try {
    store.acquire_agent_session(key, Node, async fn() {
      @async.pause()
      fail("node open must not run without an owner")
    })
    |> ignore
    false
  } catch {
    error => {
      let rendered = @debug.to_string(error)
      inspect(
        rendered.contains("NodeOwnerRequired(ResourceKey(\"owner-required\"))"),
        content="true",
      )
      true
    }
  }
  inspect(detail, content="true")
}

///|
async test "RuntimeResourceStore lifecycle 3 - aggregates one close error after reverse cleanup without double close" {
  let store = RuntimeResourceStore::RuntimeResourceStore()
  let closed : Array[String] = []
  let first = ResourceKey::parse("first")
  let failed = ResourceKey::parse("failed")
  let last = ResourceKey::parse("last")
  store.acquire_agent_session(first, Run, async fn() {
    @async.pause()
    lifecycle_session("first", closed, Succeeds)
  })
  |> ignore
  store.acquire_agent_session(failed, Run, async fn() {
    @async.pause()
    lifecycle_session("failed", closed, Fails("close-detail"))
  })
  |> ignore
  store.acquire_agent_session(last, Run, async fn() {
    @async.pause()
    lifecycle_session("last", closed, Succeeds)
  })
  |> ignore
  let detail = try {
    store.close_all()
    false
  } catch {
    error => {
      let rendered = @debug.to_string(error)
      inspect(
        rendered.contains(
          "CloseFailed(errors=<ReadOnlyArray: [LifecycleCloseFailed(\"close-detail\")]>)",
        ),
        content="true",
      )
      true
    }
  }
  inspect(detail, content="true")
  inspect(closed.join(","), content="last,failed,first")
  store.close_all()
  inspect(closed.join(","), content="last,failed,first")
}

///|
async test "RuntimeResourceStore finalize 1 - rejects a non-positive timeout" {
  let store = RuntimeResourceStore::RuntimeResourceStore()
  let detail = try {
    store.finalize(0)
    false
  } catch {
    error => {
      let rendered = @debug.to_string(error)
      inspect(rendered.contains("InvalidCleanupTimeout(0)"), content="true")
      true
    }
  }
  inspect(detail, content="true")
}

///|
async test "RuntimeResourceStore finalize 2 - completes a suspended close before caller cancellation propagates" {
  @async.with_task_group() <| group => {
    let store = RuntimeResourceStore::RuntimeResourceStore()
    let closed : Array[String] = []
    let key = ResourceKey::parse("cancel-close")
    store.acquire_agent_session(key, Run, async fn() {
      @async.pause()
      lifecycle_session("cancel-close", closed, Sleeps(50))
    })
    |> ignore
    let task = group.spawn(
      async fn() { store.finalize(500) },
      allow_failure=true,
    )
    @async.pause()
    task.cancel()
    let cancellation = try {
      task.wait()
      false
    } catch {
      error => @async.is_cancellation_error(error)
    }
    inspect(cancellation, content="true")
    inspect(
      closed.join(","),
      content="cancel-close:started,cancel-close:finished",
    )
  }
}

///|
async test "RuntimeResourceStore finalize 3 - raises the configured hard timeout" {
  let store = RuntimeResourceStore::RuntimeResourceStore()
  let closed : Array[String] = []
  let key = ResourceKey::parse("timeout-close")
  store.acquire_agent_session(key, Run, async fn() {
    @async.pause()
    lifecycle_session("timeout-close", closed, Sleeps(100))
  })
  |> ignore
  let detail = try {
    store.finalize(5)
    false
  } catch {
    error => {
      let rendered = @debug.to_string(error)
      inspect(rendered.contains("CleanupTimedOut(5)"), content="true")
      true
    }
  }
  inspect(detail, content="true")
  inspect(closed.join(","), content="timeout-close:started")
}
