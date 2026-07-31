///|
suberror RuntimeErrorTestError {
  Failed(String)
} derive(Debug)

///|
fn w4_error_metadata(name : String) -> NodeMetadata {
  NodeMetadata::{ name, description: None, kind: Function, tags: [] }
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
test "RunOptions 1 - rejects invalid limits before graph execution" {
  try RunOptions::RunOptions(max_steps=0) catch {
    MaxStepsMustBePositive(value) => inspect(value, content="0")
    _ => fail("expected MaxStepsMustBePositive")
  } noraise {
    _ => fail("expected MaxStepsMustBePositive")
  }
  try RunOptions::RunOptions(node_timeout_ms=0) catch {
    NodeTimeoutMustBePositive(value) => inspect(value, content="0")
    _ => fail("expected NodeTimeoutMustBePositive")
  } noraise {
    _ => fail("expected NodeTimeoutMustBePositive")
  }
  try RunOptions::RunOptions(cleanup_timeout_ms=0) catch {
    CleanupTimeoutMustBePositive(value) => inspect(value, content="0")
    _ => fail("expected CleanupTimeoutMustBePositive")
  } noraise {
    _ => fail("expected CleanupTimeoutMustBePositive")
  }
}

///|
async test "GraphRuntime invoke 1 - preserves a node cause without routing afterward" {
  let a = NodeId::parse("node-failure")
  let mut router_calls = 0
  let runtime = w4_error_runtime_for_single_node(
    Reducer::{ apply: fn(state, patch) { state + patch } },
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
async test "GraphRuntime invoke 2 - stops before routing when reduction fails" {
  let a = NodeId::parse("reduce-failure")
  let mut router_calls = 0
  let runtime = w4_error_runtime_for_single_node(
    Reducer::{ apply: (_state, _patch) => raise Failed("reduce-detail") },
    w4_error_node(a, async fn(_context, _state) {
      @async.pause()
      NodeOutput::{ patch: Some(1), value: None, artifacts: [] }
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
async test "GraphRuntime invoke 3 - stops before the next node when routing fails" {
  let a = NodeId::parse("route-failure")
  let b = NodeId::parse("next-node")
  let mut next_node_calls = 0
  let definition = GraphDefinition::GraphDefinition(Reducer::{
    apply: fn(state, patch) { state + patch },
  })
  definition.add_node(
    w4_error_node(a, async fn(_context, _state) {
      @async.pause()
      NodeOutput::{ patch: None, value: None, artifacts: [] }
    }),
  )
  definition.add_node(
    w4_error_node(b, async fn(_context, _state) {
      next_node_calls = next_node_calls + 1
      @async.pause()
      NodeOutput::{ patch: None, value: None, artifacts: [] }
    }),
  )
  definition.set_router(
    a,
    router([b], (_state, _completion) => raise Failed("route-detail")),
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
async test "GraphRuntime invoke 4 - rejects an undeclared existing route target" {
  let a = NodeId::parse("source")
  let b = NodeId::parse("declared")
  let c = NodeId::parse("undeclared")
  let definition = GraphDefinition::GraphDefinition(Reducer::{
    apply: fn(state, patch) { state + patch },
  })
  for id in [a, b, c] {
    definition.add_node(
      w4_error_node(id, async fn(_context, _state) {
        @async.pause()
        NodeOutput::{ patch: None, value: None, artifacts: [] }
      }),
    )
  }
  definition.set_router(a, router([b], fn(_state, _completion) { To(c) }))
  definition.set_router(b, router([c], fn(_state, _completion) { To(c) }))
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
async test "GraphRuntime invoke 5 - enforces the step limit after exactly that many attempts" {
  let a = NodeId::parse("self-loop")
  let mut attempts = 0
  let runtime = w4_error_runtime_for_single_node(
    Reducer::{ apply: fn(state, patch) { state + patch } },
    w4_error_node(a, async fn(_context, _state) {
      attempts = attempts + 1
      @async.pause()
      NodeOutput::{ patch: None, value: None, artifacts: [] }
    }),
    router([a], fn(_state, _completion) { To(a) }),
  )
  let options = RunOptions::RunOptions(max_steps=3)
  let detail = (runtime.invoke(0, options~) |> @debug.to_string) catch {
    error => @debug.to_string(error)
  }
  inspect(detail.contains("StepLimitExceeded(limit=3)"), content="true")
  inspect(attempts, content="3")
}

///|
async test "GraphRuntime invoke 6 - exposes a route failure message" {
  let a = NodeId::parse("explicit-failure")
  let runtime = w4_error_runtime_for_single_node(
    Reducer::{ apply: fn(state, patch) { state + patch } },
    w4_error_node(a, async fn(_context, _state) {
      @async.pause()
      NodeOutput::{ patch: None, value: None, artifacts: [] }
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
async test "GraphRuntime invoke 7 - cancels a timed out node before its second token" {
  let a = NodeId::parse("timeout")
  let tokens : Array[String] = []
  let runtime = w4_error_runtime_for_single_node(
    Reducer::{ apply: fn(state, patch) { state + patch } },
    w4_error_node(a, async fn(_context, _state) {
      tokens.push("started")
      @async.sleep(100)
      tokens.push("finished")
      NodeOutput::{ patch: None, value: None, artifacts: [] }
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
