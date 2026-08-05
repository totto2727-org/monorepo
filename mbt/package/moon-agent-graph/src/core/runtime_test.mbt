///|
fn success_runtime_metadata(name : String) -> NodeMetadata {
  NodeMetadata::NodeMetadata(name, None, Function, ["runtime-test"])
}

///|
fn success_end_router() -> Router[Int] {
  router([], fn(_state, _completion) { End })
}

///|
struct RuntimeTestResource {
  label : String
  closed : Array[String]
} derive(Debug)

///|
extenum @any.Payload += {
  RuntimeTestResource(RuntimeTestResource)
}

///|
impl @any.Anyable for RuntimeTestResource with fn iso() {
  {
    id: @any.TypeId::TypeId(
      "totto2727/moon-agent-graph/core/runtime-test",
      "RuntimeTestResource",
      [],
    ),
    box: resource => RuntimeTestResource(resource),
    unbox: payload => {
      guard payload is RuntimeTestResource(resource)
      resource
    },
  }
}

///|
fn runtime_test_resource_ref(
  key : ResourceKey,
) -> @any_collection.AnyRef[ResourceKey, RuntimeTestResource] {
  @any_collection.AnyRef::AnyRef(key)
}

///|
async fn close_runtime_test_resource(resource : RuntimeTestResource) -> Unit {
  @async.pause()
  resource.closed.push(resource.label)
}

///|
async test "GraphRuntime invoke 1 - runs one entry node through End" {
  let entry = NodeId::parse("entry")
  let definition = GraphDefinition::GraphDefinition(
    Reducer::Reducer(fn(state : Int, patch : Int) { state + patch }),
  )
  definition.add_node(
    function_node(entry, success_runtime_metadata("entry"), async fn(
      _context,
      _state : Int,
    ) {
      @async.pause()
      NodeOutput::NodeOutput(None, None, [])
    }),
  )
  definition.set_router(entry, success_end_router())
  definition.set_entry(entry)
  let result = GraphRuntime::GraphRuntime(definition.compile()).invoke(7)
  inspect(result.final_state, content="7")
  inspect(result.steps, content="1")
  assert_false(result.run_id.to_string().is_empty())
}

///|
async test "GraphRuntime invoke 2 - executes sequential routes in order" {
  let first = NodeId::parse("first")
  let second = NodeId::parse("second")
  let calls : Array[String] = []
  let definition = GraphDefinition::GraphDefinition(
    Reducer::Reducer(fn(state : Int, patch : Int) { state + patch }),
  )
  definition.add_node(
    function_node(first, success_runtime_metadata("first"), async fn(
      _context,
      state : Int,
    ) {
      calls.push("first:\{state}")
      @async.pause()
      NodeOutput::NodeOutput(None, None, [])
    }),
  )
  definition.add_node(
    function_node(second, success_runtime_metadata("second"), async fn(
      _context,
      state : Int,
    ) {
      calls.push("second:\{state}")
      @async.pause()
      NodeOutput::NodeOutput(None, None, [])
    }),
  )
  definition.set_router(
    first,
    router([DeclaredRoute::DeclaredRoute(second)], fn(_state, _completion) {
      To(second)
    }),
  )
  definition.set_router(second, success_end_router())
  definition.set_entry(first)
  let result = GraphRuntime::GraphRuntime(definition.compile()).invoke(4)
  inspect(calls.join(","), content="first:4,second:4")
  inspect(result.steps, content="2")
  inspect(result.final_state, content="4")
}

///|
async test "GraphRuntime invoke 3 - reduces a patch once before routing" {
  let entry = NodeId::parse("entry")
  let observations : Array[String] = []
  let definition = GraphDefinition::GraphDefinition(
    Reducer::Reducer(fn(state : Int, patch : Int) {
      observations.push("reduce:\{state}+\{patch}")
      state + patch
    }),
  )
  definition.add_node(
    function_node(entry, success_runtime_metadata("entry"), async fn(
      _context,
      _state : Int,
    ) {
      @async.pause()
      NodeOutput::NodeOutput(Some(2), None, [])
    }),
  )
  definition.set_router(
    entry,
    router([], fn(state, _completion) {
      observations.push("route:\{state}")
      End
    }),
  )
  definition.set_entry(entry)
  let result = GraphRuntime::GraphRuntime(definition.compile()).invoke(1)
  inspect(observations.join(","), content="reduce:1+2,route:3")
  inspect(result.final_state, content="3")
}

///|
async test "GraphRuntime invoke 4 - skips the reducer when a node has no patch" {
  let entry = NodeId::parse("entry")
  let reductions : Array[Int] = []
  let definition = GraphDefinition::GraphDefinition(
    Reducer::Reducer(fn(state : Int, patch : Int) {
      reductions.push(patch)
      state + patch
    }),
  )
  definition.add_node(
    function_node(entry, success_runtime_metadata("entry"), async fn(
      _context,
      _state : Int,
    ) {
      @async.pause()
      NodeOutput::NodeOutput(None, None, [])
    }),
  )
  definition.set_router(entry, success_end_router())
  definition.set_entry(entry)
  let result = GraphRuntime::GraphRuntime(definition.compile()).invoke(9)
  inspect(reductions.length(), content="0")
  inspect(result.final_state, content="9")
}

///|
async test "GraphRuntime invoke 5 - emits the successful lifecycle in order" {
  let entry = NodeId::parse("entry")
  let events : Array[String] = []
  let sink = EventSink::EventSink(fn(event) {
    match event {
      RunStarted(_) => events.push("RunStarted")
      NodeStarted(_) => events.push("NodeStarted")
      NodeCompleted(_) => events.push("NodeCompleted")
      StateUpdated(_) => events.push("StateUpdated")
      RouteSelected(_) => events.push("RouteSelected")
      RunCompleted(_) => events.push("RunCompleted")
      _ => events.push("unexpected")
    }
  })
  let definition = GraphDefinition::GraphDefinition(
    Reducer::Reducer(fn(state : Int, patch : Int) { state + patch }),
  )
  definition.add_node(
    function_node(entry, success_runtime_metadata("entry"), async fn(
      _context,
      _state : Int,
    ) {
      @async.pause()
      NodeOutput::NodeOutput(Some(1), None, [])
    }),
  )
  definition.set_router(entry, success_end_router())
  definition.set_entry(entry)
  GraphRuntime::GraphRuntime(definition.compile(), events=sink).invoke(0)
  |> ignore
  inspect(
    events.join(","),
    content="RunStarted,NodeStarted,NodeCompleted,StateUpdated,RouteSelected,RunCompleted",
  )
}

///|
async test "GraphRuntime invoke 6 - exits a self loop when the reduced state reaches its route condition" {
  let entry = NodeId::parse("loop")
  let states : Array[Int] = []
  let definition = GraphDefinition::GraphDefinition(
    Reducer::Reducer(fn(state : Int, patch : Int) { state + patch }),
  )
  definition.add_node(
    function_node(entry, success_runtime_metadata("loop"), async fn(
      _context,
      state : Int,
    ) {
      states.push(state)
      @async.pause()
      NodeOutput::NodeOutput(Some(1), None, [])
    }),
  )
  definition.set_router(
    entry,
    router([DeclaredRoute::DeclaredRoute(entry)], fn(state, _completion) {
      if state < 3 {
        To(entry)
      } else {
        End
      }
    }),
  )
  definition.set_entry(entry)
  let options = RunOptions::RunOptions(max_steps=4)
  let result = GraphRuntime::GraphRuntime(definition.compile()).invoke(
    0,
    options~,
  )
  inspect(
    states.map(fn(value) { value.to_string() }).join(","),
    content="0,1,2",
  )
  inspect(result.steps, content="3")
  inspect(result.final_state, content="3")
}

///|
async test "GraphRuntime invoke 7 - isolates state resources and run IDs across invocations" {
  let entry = NodeId::parse("entry")
  let resource_key = ResourceKey::parse("per-run")
  let opened : Array[String] = []
  let closed : Array[String] = []
  let run_ids : Array[String] = []
  let definition = GraphDefinition::GraphDefinition(
    Reducer::Reducer(fn(state : Int, patch : Int) { state + patch }),
  )
  definition.add_node(
    function_node(entry, success_runtime_metadata("entry"), async fn(
      context,
      _state : Int,
    ) {
      let label = "session-\{opened.length()}"
      context.resources.acquire_resource(
        runtime_test_resource_ref(resource_key),
        Run,
        async fn() {
          @async.pause()
          opened.push(label)
          RuntimeTestResource::{ label, closed }
        },
        close_runtime_test_resource,
      )
      |> ignore
      run_ids.push(context.run_id.to_string())
      @async.pause()
      NodeOutput::NodeOutput(Some(1), None, [])
    }),
  )
  definition.set_router(entry, success_end_router())
  definition.set_entry(entry)
  let runtime = GraphRuntime::GraphRuntime(definition.compile())
  let first = runtime.invoke(10)
  let second = runtime.invoke(20)
  inspect(first.final_state, content="11")
  inspect(second.final_state, content="21")
  inspect(opened.join(","), content="session-0,session-1")
  inspect(closed.join(","), content="session-0,session-1")
  assert_true(run_ids[0] != run_ids[1])
}

///|
suberror RuntimeErrorTestError {
  Failed(String)
} derive(Debug)

///|
fn w4_error_metadata(name : String) -> NodeMetadata {
  NodeMetadata::NodeMetadata(name, None, Function, [])
}

///|
fn w4_error_node(
  id : NodeId,
  execute : async (NodeContext, Int) -> NodeOutput[Int],
) -> Node[Int, Int] {
  function_node(id, w4_error_metadata(id.to_string()), execute)
}

///|
fn w4_error_runtime_for_single_node(
  reducer : Reducer[Int, Int],
  node : Node[Int, Int],
  value : Router[Int],
) -> GraphRuntime[Int, Int] raise {
  let definition = GraphDefinition::GraphDefinition(reducer)
  definition.add_node(node)
  definition.set_router(node.id, value)
  definition.set_entry(node.id)
  GraphRuntime::GraphRuntime(definition.compile())
}

///|
async test "GraphRuntime error 1 - preserves a node cause without routing afterward" {
  let a = NodeId::parse("node-failure")
  let mut router_calls = 0
  let runtime = w4_error_runtime_for_single_node(
    Reducer::Reducer(fn(state, patch) { state + patch }),
    w4_error_node(a, async fn(_context, _state) {
      @async.pause()
      raise Failed("node-detail")
    }),
    router([], fn(_state, _completion) {
      router_calls = router_calls + 1
      End
    }),
  )
  let detail = (runtime.invoke(0) |> @debug.to_string) catch {
    error => @debug.to_string(error)
  }
  inspect(detail.contains("NodeFailed("), content="true")
  inspect(detail.contains("node-failure"), content="true")
  inspect(detail.contains("node-detail"), content="true")
  inspect(router_calls, content="0")
}

///|
async test "GraphRuntime error 2 - stops before routing when reduction fails" {
  let a = NodeId::parse("reduce-failure")
  let mut router_calls = 0
  let runtime = w4_error_runtime_for_single_node(
    Reducer::Reducer((_state, _patch) => raise Failed("reduce-detail")),
    w4_error_node(a, async fn(_context, _state) {
      @async.pause()
      NodeOutput::NodeOutput(Some(1), None, [])
    }),
    router([], fn(_state, _completion) {
      router_calls = router_calls + 1
      End
    }),
  )
  let detail = (runtime.invoke(0) |> @debug.to_string) catch {
    error => @debug.to_string(error)
  }
  inspect(detail.contains("ReduceFailed("), content="true")
  inspect(detail.contains("reduce-failure"), content="true")
  inspect(detail.contains("reduce-detail"), content="true")
  inspect(router_calls, content="0")
}

///|
async test "GraphRuntime error 3 - stops before the next node when routing fails" {
  let a = NodeId::parse("route-failure")
  let b = NodeId::parse("next-node")
  let mut next_node_calls = 0
  let definition = GraphDefinition::GraphDefinition(
    Reducer::Reducer(fn(state, patch) { state + patch }),
  )
  definition.add_node(
    w4_error_node(a, async fn(_context, _state) {
      @async.pause()
      NodeOutput::NodeOutput(None, None, [])
    }),
  )
  definition.add_node(
    w4_error_node(b, async fn(_context, _state) {
      next_node_calls = next_node_calls + 1
      @async.pause()
      NodeOutput::NodeOutput(None, None, [])
    }),
  )
  definition.set_router(
    a,
    router([DeclaredRoute::DeclaredRoute(b)], (_state, _completion) => {
      raise Failed("route-detail")
    }),
  )
  definition.set_router(b, router([], fn(_state, _completion) { End }))
  definition.set_entry(a)
  let runtime = GraphRuntime::GraphRuntime(definition.compile())
  let detail = (runtime.invoke(0) |> @debug.to_string) catch {
    error => @debug.to_string(error)
  }
  inspect(detail.contains("RouteFailed("), content="true")
  inspect(detail.contains("route-failure"), content="true")
  inspect(detail.contains("route-detail"), content="true")
  inspect(next_node_calls, content="0")
}

///|
async test "GraphRuntime error 4 - rejects an undeclared existing route target" {
  let a = NodeId::parse("source")
  let b = NodeId::parse("declared")
  let c = NodeId::parse("undeclared")
  let definition = GraphDefinition::GraphDefinition(
    Reducer::Reducer(fn(state, patch) { state + patch }),
  )
  for id in [a, b, c] {
    definition.add_node(
      w4_error_node(id, async fn(_context, _state) {
        @async.pause()
        NodeOutput::NodeOutput(None, None, [])
      }),
    )
  }
  definition.set_router(
    a,
    router([DeclaredRoute::DeclaredRoute(b)], fn(_state, _completion) { To(c) }),
  )
  definition.set_router(
    b,
    router([DeclaredRoute::DeclaredRoute(c)], fn(_state, _completion) { To(c) }),
  )
  definition.set_router(c, router([], fn(_state, _completion) { End }))
  definition.set_entry(a)
  let runtime = GraphRuntime::GraphRuntime(definition.compile())
  let detail = (runtime.invoke(0) |> @debug.to_string) catch {
    error => @debug.to_string(error)
  }
  inspect(
    detail.contains(
      "RouteContractViolated(from=NodeId(\"source\"), to=NodeId(\"undeclared\"))",
    ),
    content="true",
  )
}

///|
async test "GraphRuntime error 5 - enforces the step limit after exactly that many attempts" {
  let a = NodeId::parse("self-loop")
  let mut attempts = 0
  let runtime = w4_error_runtime_for_single_node(
    Reducer::Reducer(fn(state, patch) { state + patch }),
    w4_error_node(a, async fn(_context, _state) {
      attempts = attempts + 1
      @async.pause()
      NodeOutput::NodeOutput(None, None, [])
    }),
    router([DeclaredRoute::DeclaredRoute(a)], fn(_state, _completion) { To(a) }),
  )
  let options = RunOptions::RunOptions(max_steps=3)
  let detail = (runtime.invoke(0, options~) |> @debug.to_string) catch {
    error => @debug.to_string(error)
  }
  inspect(detail.contains("StepLimitExceeded(limit=3)"), content="true")
  inspect(attempts, content="3")
}

///|
async test "GraphRuntime error 6 - exposes a route failure message" {
  let a = NodeId::parse("explicit-failure")
  let runtime = w4_error_runtime_for_single_node(
    Reducer::Reducer(fn(state, patch) { state + patch }),
    w4_error_node(a, async fn(_context, _state) {
      @async.pause()
      NodeOutput::NodeOutput(None, None, [])
    }),
    router([], fn(_state, _completion) { Fail("stop-now") }),
  )
  let detail = (runtime.invoke(0) |> @debug.to_string) catch {
    error => @debug.to_string(error)
  }
  inspect(detail.contains("ExplicitFailure("), content="true")
  inspect(detail.contains("explicit-failure"), content="true")
  inspect(detail.contains("stop-now"), content="true")
}

///|
async test "GraphRuntime error 7 - cancels a timed out node before its second token" {
  let a = NodeId::parse("timeout")
  let tokens : Array[String] = []
  let runtime = w4_error_runtime_for_single_node(
    Reducer::Reducer(fn(state, patch) { state + patch }),
    w4_error_node(a, async fn(_context, _state) {
      tokens.push("started")
      @async.sleep(100)
      tokens.push("finished")
      NodeOutput::NodeOutput(None, None, [])
    }),
    router([], fn(_state, _completion) { End }),
  )
  let options = RunOptions::RunOptions(node_timeout_ms=5)
  let detail = (runtime.invoke(0, options~) |> @debug.to_string) catch {
    error => @debug.to_string(error)
  }
  inspect(
    detail.contains(
      "NodeTimedOut(node_id=NodeId(\"timeout\"), step=1, timeout_ms=5)",
    ),
    content="true",
  )
  inspect(tokens.join(","), content="started")
}

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
} derive(Debug)

///|
trait W4ResourceLifecycle {
  async fn close(Self) -> Unit
}

///|
struct W4LifecycleResource {
  closed : Array[String]
  plan : W4ClosePlan
} derive(Debug)

///|
extenum @any.Payload += {
  W4LifecycleResource(W4LifecycleResource)
}

///|
impl @any.Anyable for W4LifecycleResource with fn iso() {
  {
    id: @any.TypeId::TypeId(
      "totto2727/moon-agent-graph/core/runtime-test",
      "W4LifecycleResource",
      [],
    ),
    box: resource => W4LifecycleResource(resource),
    unbox: payload => {
      guard payload is W4LifecycleResource(resource)
      resource
    },
  }
}

///|
impl W4ResourceLifecycle for W4LifecycleResource with fn close(self) {
  match self.plan {
    W4CloseSucceeds => self.closed.push("closed")
    W4CloseFails(message) => {
      self.closed.push("closed")
      raise W4CloseFailed(message)
    }
  }
}

///|
fn w4_lifecycle_resource(
  closed : Array[String],
  plan : W4ClosePlan,
) -> W4LifecycleResource {
  W4LifecycleResource::{ closed, plan }
}

///|
fn w4_lifecycle_resource_ref(
  key : ResourceKey,
) -> @any_collection.AnyRef[ResourceKey, W4LifecycleResource] {
  @any_collection.AnyRef::AnyRef(key)
}

///|
fn w4_lifecycle_graph(
  execute : async (NodeContext, Int) -> NodeOutput[Int],
  reduce : (Int, Int) -> Int raise,
  route : (Int, NodeCompletion) -> Route raise,
) -> CompiledGraph[Int, Int] raise {
  let node_id = NodeId::parse("lifecycle")
  let definition = GraphDefinition::GraphDefinition(Reducer::Reducer(reduce))
  definition.add_node(
    function_node(
      node_id,
      NodeMetadata::NodeMetadata("lifecycle", None, Function, []),
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
        context.resources.acquire_resource(
          w4_lifecycle_resource_ref(ResourceKey::parse("cancelled-resource")),
          Node,
          async fn() {
            @async.pause()
            w4_lifecycle_resource(closed, W4CloseSucceeds)
          },
          W4ResourceLifecycle::close,
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
          NodeOutput::NodeOutput(None, None, [])
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
        NodeOutput::NodeOutput(Some(1), None, [])
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
        NodeOutput::NodeOutput(None, None, [])
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
      context.resources.acquire_resource(
        w4_lifecycle_resource_ref(ResourceKey::parse("cleanup-only")),
        Run,
        async fn() {
          @async.pause()
          w4_lifecycle_resource(closed, W4CloseFails("cleanup-only"))
        },
        W4ResourceLifecycle::close,
      )
      |> ignore
      NodeOutput::NodeOutput(None, None, [])
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
      context.resources.acquire_resource(
        w4_lifecycle_resource_ref(ResourceKey::parse("primary-and-cleanup")),
        Run,
        async fn() {
          @async.pause()
          w4_lifecycle_resource(closed, W4CloseFails("secondary"))
        },
        W4ResourceLifecycle::close,
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
      NodeOutput::NodeOutput(None, None, [])
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
