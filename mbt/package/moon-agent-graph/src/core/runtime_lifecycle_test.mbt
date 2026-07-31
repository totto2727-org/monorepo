///|
suberror W4LifecycleTestError {
  W4NodeFailed(String)
  W4ReduceFailed(String)
  W4RouteFailed(String)
  W4CloseFailed(String)
} derive(Debug)

///|
enum W4ClosePlan {
  W4CloseSucceeds
  W4CloseFails(String)
}

///|
struct W4LifecycleSession {
  closed : Array[String]
  plan : W4ClosePlan
}

///|
impl CodingAgentSession for W4LifecycleSession with fn id(_self) {
  None
}

///|
impl CodingAgentSession for W4LifecycleSession with fn execute(_self, _request) {
  @async.pause()
  CodingAgentResponse::{
    status: Succeeded,
    summary: None,
    continuation_id: None,
    changed_files: [],
    artifacts: [],
    raw_output: None,
  }
}

///|
impl CodingAgentSession for W4LifecycleSession with fn close(self) {
  match self.plan {
    W4CloseSucceeds => self.closed.push("closed")
    W4CloseFails(message) => {
      self.closed.push("closed")
      raise W4CloseFailed(message)
    }
  }
}

///|
fn w4_lifecycle_session(
  closed : Array[String],
  plan : W4ClosePlan,
) -> &CodingAgentSession {
  let session = W4LifecycleSession::{ closed, plan }
  (session : &CodingAgentSession)
}

///|
fn w4_lifecycle_graph(
  execute : async (NodeContext, Int) -> NodeOutput[Int],
  reduce : (Int, Int) -> Int raise,
  route : (Int, NodeCompletion) -> Route raise,
) -> CompiledGraph[Int, Int] raise {
  let node_id = NodeId::parse("lifecycle")
  let definition = GraphDefinition::GraphDefinition(Reducer::{ apply: reduce })
  definition.add_node(
    function_node(
      node_id,
      NodeMetadata::{
        name: "lifecycle",
        description: None,
        kind: Function,
        tags: [],
      },
      execute,
    ),
  )
  definition.set_router(node_id, router([], route))
  definition.set_entry(node_id)
  definition.compile()
}

///|
fn w4_terminal_counts(events : Array[GraphEvent]) -> (Int, Int, Int) {
  let mut completed = 0
  let mut failed = 0
  let mut cancelled = 0
  for event in events {
    match event {
      RunCompleted(_) => completed = completed + 1
      RunFailed(_) => failed = failed + 1
      RunCancelled(_) => cancelled = cancelled + 1
      _ => ()
    }
  }
  (completed, failed, cancelled)
}

///|
async test "GraphRuntime lifecycle 1 - cancellation closes resources and stops children before re-raising" {
  @async.with_task_group() <| caller_group => {
    let closed : Array[String] = []
    let child_tokens : Array[String] = []
    let node_ready : Array[String] = []
    let events : Array[GraphEvent] = []
    let graph = w4_lifecycle_graph(
      async fn(context, _state) {
        context.resources.acquire_agent_session(
          ResourceKey::parse("cancelled-session"),
          Node,
          async fn() {
            @async.pause()
            w4_lifecycle_session(closed, W4CloseSucceeds)
          },
          owner=context.node_id,
        )
        |> ignore
        context.task_group.spawn(async fn() {
          child_tokens.push("started")
          while true {
            @async.pause()
          } nobreak {
            child_tokens.push("finished")
          }
        })
        |> ignore
        node_ready.push("acquired")
        while true {
          @async.pause()
        } nobreak {
          NodeOutput::{ patch: None, value: None, artifacts: [] }
        }
      },
      fn(state, patch) { state + patch },
      fn(_state, _completion) { End },
    )
    let runtime = GraphRuntime::GraphRuntime(
      graph,
      events=EventSink::EventSink(fn(event) { events.push(event) }),
    )
    let task = caller_group.spawn(
      async fn() { runtime.invoke(0) |> ignore },
      allow_failure=true,
    )
    let mut wait_attempts = 0
    while (node_ready.is_empty() || child_tokens.is_empty()) &&
          wait_attempts < 20 {
      @async.pause()
      wait_attempts = wait_attempts + 1
    }
    inspect(node_ready.join(","), content="acquired")
    inspect(child_tokens.join(","), content="started")
    task.cancel()
    let cancellation = try {
      task.wait()
      false
    } catch {
      error => @async.is_cancellation_error(error)
    }
    inspect(closed.join(","), content="closed")
    inspect(child_tokens.join(","), content="started")
    let (completed, failed, cancelled) = w4_terminal_counts(events)
    inspect(completed, content="0")
    inspect(failed, content="0")
    inspect(cancelled, content="1")
    inspect(cancellation, content="true")
  }
}

///|
async fn w4_assert_one_failed_terminal(
  graph : CompiledGraph[Int, Int],
  expected : String,
) -> Unit {
  let events : Array[GraphEvent] = []
  let runtime = GraphRuntime::GraphRuntime(
    graph,
    events=EventSink::EventSink(fn(event) { events.push(event) }),
  )
  let detail = try {
    runtime.invoke(0) |> ignore
    ""
  } catch {
    error => @debug.to_string(error)
  }
  inspect(detail.contains(expected), content="true")
  let (completed, failed, cancelled) = w4_terminal_counts(events)
  inspect(completed, content="0")
  inspect(failed, content="1")
  inspect(cancelled, content="0")
}

///|
async test "GraphRuntime lifecycle 2 - node reducer and router failures each emit one RunFailed" {
  w4_assert_one_failed_terminal(
    w4_lifecycle_graph(
      async fn(_context, _state) {
        @async.pause()
        raise W4NodeFailed("node")
      },
      fn(state, patch) { state + patch },
      fn(_state, _completion) { End },
    ),
    "NodeFailed",
  )
  w4_assert_one_failed_terminal(
    w4_lifecycle_graph(
      async fn(_context, _state) {
        @async.pause()
        NodeOutput::{ patch: Some(1), value: None, artifacts: [] }
      },
      fn(_state, _patch) raise { raise W4ReduceFailed("reducer") },
      fn(_state, _completion) { End },
    ),
    "ReduceFailed",
  )
  w4_assert_one_failed_terminal(
    w4_lifecycle_graph(
      async fn(_context, _state) {
        @async.pause()
        NodeOutput::{ patch: None, value: None, artifacts: [] }
      },
      fn(state, patch) { state + patch },
      fn(_state, _completion) raise { raise W4RouteFailed("router") },
    ),
    "RouteFailed",
  )
}

///|
async test "GraphRuntime lifecycle 3 - cleanup-only failure becomes ResourceCleanupFailed" {
  let closed : Array[String] = []
  let events : Array[GraphEvent] = []
  let graph = w4_lifecycle_graph(
    async fn(context, _state) {
      context.resources.acquire_agent_session(
        ResourceKey::parse("cleanup-only"),
        Run,
        async fn() {
          @async.pause()
          w4_lifecycle_session(closed, W4CloseFails("cleanup-only"))
        },
      )
      |> ignore
      NodeOutput::{ patch: None, value: None, artifacts: [] }
    },
    fn(state, patch) { state + patch },
    fn(_state, _completion) { End },
  )
  let runtime = GraphRuntime::GraphRuntime(
    graph,
    events=EventSink::EventSink(fn(event) { events.push(event) }),
  )
  let detail = try {
    runtime.invoke(0) |> ignore
    ""
  } catch {
    error => @debug.to_string(error)
  }
  inspect(detail.contains("ResourceCleanupFailed"), content="true")
  inspect(detail.contains("W4CloseFailed(\"cleanup-only\")"), content="true")
  inspect(closed.join(","), content="closed")
  let (completed, failed, cancelled) = w4_terminal_counts(events)
  inspect(completed, content="0")
  inspect(failed, content="1")
  inspect(cancelled, content="0")
}

///|
async test "GraphRuntime lifecycle 4 - primary and cleanup failures remain distinguishable" {
  let closed : Array[String] = []
  let events : Array[GraphEvent] = []
  let graph = w4_lifecycle_graph(
    async fn(context, _state) {
      context.resources.acquire_agent_session(
        ResourceKey::parse("primary-and-cleanup"),
        Run,
        async fn() {
          @async.pause()
          w4_lifecycle_session(closed, W4CloseFails("secondary"))
        },
      )
      |> ignore
      raise W4NodeFailed("primary")
    },
    fn(state, patch) { state + patch },
    fn(_state, _completion) { End },
  )
  let runtime = GraphRuntime::GraphRuntime(
    graph,
    events=EventSink::EventSink(fn(event) { events.push(event) }),
  )
  let detail = try {
    runtime.invoke(0) |> ignore
    ""
  } catch {
    error => @debug.to_string(error)
  }
  inspect(detail.contains("ResourceCleanupFailed"), content="true")
  inspect(detail.contains("W4NodeFailed(\"primary\")"), content="true")
  inspect(detail.contains("W4CloseFailed(\"secondary\")"), content="true")
  inspect(closed.join(","), content="closed")
  let (completed, failed, cancelled) = w4_terminal_counts(events)
  inspect(completed, content="0")
  inspect(failed, content="1")
  inspect(cancelled, content="0")
}

///|
async test "GraphRuntime lifecycle 5 - success emits exactly one RunCompleted" {
  let events : Array[GraphEvent] = []
  let graph = w4_lifecycle_graph(
    async fn(_context, _state) {
      @async.pause()
      NodeOutput::{ patch: None, value: None, artifacts: [] }
    },
    fn(state, patch) { state + patch },
    fn(_state, _completion) { End },
  )
  let result = GraphRuntime::GraphRuntime(
    graph,
    events=EventSink::EventSink(fn(event) { events.push(event) }),
  ).invoke(7)
  inspect(result.final_state, content="7")
  inspect(result.steps, content="1")
  let (completed, failed, cancelled) = w4_terminal_counts(events)
  inspect(completed, content="1")
  inspect(failed, content="0")
  inspect(cancelled, content="0")
}
