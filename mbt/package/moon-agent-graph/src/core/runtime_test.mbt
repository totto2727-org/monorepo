///|
fn success_runtime_metadata(name : String) -> NodeMetadata {
  NodeMetadata::{
    name,
    description: None,
    kind: Function,
    tags: ["runtime-test"],
  }
}

///|
fn success_end_router() -> Router[Int] {
  router([], fn(_state, _completion) { End })
}

///|
struct RuntimeTestSession {
  label : String
  closed : Array[String]
}

///|
impl CodingAgentSession for RuntimeTestSession with fn id(_self) {
  None
}

///|
impl CodingAgentSession for RuntimeTestSession with fn execute(_self, _request) {
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
impl CodingAgentSession for RuntimeTestSession with fn close(self) {
  @async.pause()
  self.closed.push(self.label)
}

///|
async test "GraphRuntime invoke 1 - runs one entry node through End" {
  let entry = NodeId::parse("entry")
  let definition = GraphDefinition::GraphDefinition(Reducer::{
    apply: fn(state : Int, patch : Int) { state + patch },
  })
  definition.add_node(
    function_node(entry, success_runtime_metadata("entry"), async fn(
      _context,
      _state : Int,
    ) {
      @async.pause()
      NodeOutput::{ patch: None, value: None, artifacts: [] }
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
  let definition = GraphDefinition::GraphDefinition(Reducer::{
    apply: fn(state : Int, patch : Int) { state + patch },
  })
  definition.add_node(
    function_node(first, success_runtime_metadata("first"), async fn(
      _context,
      state : Int,
    ) {
      calls.push("first:\{state}")
      @async.pause()
      NodeOutput::{ patch: None, value: None, artifacts: [] }
    }),
  )
  definition.add_node(
    function_node(second, success_runtime_metadata("second"), async fn(
      _context,
      state : Int,
    ) {
      calls.push("second:\{state}")
      @async.pause()
      NodeOutput::{ patch: None, value: None, artifacts: [] }
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
  let definition = GraphDefinition::GraphDefinition(Reducer::{
    apply: fn(state : Int, patch : Int) {
      observations.push("reduce:\{state}+\{patch}")
      state + patch
    },
  })
  definition.add_node(
    function_node(entry, success_runtime_metadata("entry"), async fn(
      _context,
      _state : Int,
    ) {
      @async.pause()
      NodeOutput::{ patch: Some(2), value: None, artifacts: [] }
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
  let definition = GraphDefinition::GraphDefinition(Reducer::{
    apply: fn(state : Int, patch : Int) {
      reductions.push(patch)
      state + patch
    },
  })
  definition.add_node(
    function_node(entry, success_runtime_metadata("entry"), async fn(
      _context,
      _state : Int,
    ) {
      @async.pause()
      NodeOutput::{ patch: None, value: None, artifacts: [] }
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
  let definition = GraphDefinition::GraphDefinition(Reducer::{
    apply: fn(state : Int, patch : Int) { state + patch },
  })
  definition.add_node(
    function_node(entry, success_runtime_metadata("entry"), async fn(
      _context,
      _state : Int,
    ) {
      @async.pause()
      NodeOutput::{ patch: Some(1), value: None, artifacts: [] }
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
  let definition = GraphDefinition::GraphDefinition(Reducer::{
    apply: fn(state : Int, patch : Int) { state + patch },
  })
  definition.add_node(
    function_node(entry, success_runtime_metadata("loop"), async fn(
      _context,
      state : Int,
    ) {
      states.push(state)
      @async.pause()
      NodeOutput::{ patch: Some(1), value: None, artifacts: [] }
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
  let definition = GraphDefinition::GraphDefinition(Reducer::{
    apply: fn(state : Int, patch : Int) { state + patch },
  })
  definition.add_node(
    function_node(entry, success_runtime_metadata("entry"), async fn(
      context,
      _state : Int,
    ) {
      let label = "session-\{opened.length()}"
      context.resources.acquire_agent_session(resource_key, Run, async fn() {
        @async.pause()
        opened.push(label)
        let session = RuntimeTestSession::{ label, closed }
        (session : &CodingAgentSession)
      })
      |> ignore
      run_ids.push(context.run_id.to_string())
      @async.pause()
      NodeOutput::{ patch: Some(1), value: None, artifacts: [] }
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
