///|
struct W6LifecycleSession {
  number : Int
  group : @async.TaskGroup[Unit]
  lifecycle : Array[String]
  execute_started : Array[String]
  child_tokens : Array[String]
  suspend_execute : Bool
}

///|
impl @core.CodingAgentSession for W6LifecycleSession with fn id(self) {
  Some(
    @core.SessionId::parse("session-\{self.number}") catch {
      _ => abort("test session ID must be valid")
    },
  )
}

///|
impl @core.CodingAgentSession for W6LifecycleSession with fn execute(
  self,
  _request,
) {
  self.lifecycle.push("execute-\{self.number}")
  self.execute_started.push("started")
  if self.suspend_execute {
    self.group.spawn(async fn() {
      self.child_tokens.push("started")
      while true {
        @async.pause()
      } nobreak {
        self.child_tokens.push("finished")
      }
    })
    |> ignore
    while true {
      @async.pause()
    } nobreak {
      self.execute_started.push("finished")
    }
  }
  @core.CodingAgentResponse::{
    status: @core.Succeeded,
    summary: None,
    continuation_id: Some("session-\{self.number}"),
    changed_files: [],
    artifacts: [],
    raw_output: None,
  }
}

///|
impl @core.CodingAgentSession for W6LifecycleSession with fn close(self) {
  self.lifecycle.push("close-\{self.number}")
}

///|
fn w6_lifecycle_metadata() -> @core.NodeMetadata {
  @core.NodeMetadata::{
    name: "coding-agent-lifecycle",
    description: None,
    kind: @core.CodingAgent,
    tags: [],
  }
}

///|
fn w6_open_context(
  context : @core.NodeContext,
  _state : Int,
) -> @core.CodingAgentOpenContext raise {
  @core.CodingAgentOpenContext::{
    run_id: @core.RunId::parse(context.run_id.to_string()),
    task_group: context.task_group,
    workspace: @core.WorkspaceRef::{
      root: @path.Path("."),
      additional_writable_roots: [],
    },
    approval: @core.Never,
    network: @core.Disabled,
    environment: @immut_hashmap.new(),
    events: context.events,
  }
}

///|
fn w6_lifecycle_runtime(
  scope : @core.ResourceScope,
  lifecycle : Array[String],
  execute_started : Array[String],
  child_tokens : Array[String],
  suspend_execute : Bool,
  events? : @core.EventSink = @core.EventSink::discard(),
) -> @core.GraphRuntime[Int, Int] raise {
  let node_id = @core.NodeId::parse("coding-agent-lifecycle")
  let mut opened = 0
  let agent = @core.CodingAgent::{
    id: @core.CodingAgentId::parse("fake-agent"),
    open: async fn(context) {
      @async.pause()
      opened = opened + 1
      lifecycle.push("open-\{opened}")
      let session = W6LifecycleSession::{
        number: opened,
        group: context.task_group,
        lifecycle,
        execute_started,
        child_tokens,
        suspend_execute,
      }
      (session : &@core.CodingAgentSession)
    },
  }
  let definition = @core.GraphDefinition::GraphDefinition(@core.Reducer::{
    apply: fn(state : Int, patch : Int) { state + patch },
  })
  definition.add_node(
    coding_agent_node(node_id, w6_lifecycle_metadata(), CodingAgentNodeSpec::{
      agent,
      resource_key: @core.ResourceKey::parse("lifecycle-session"),
      resource_scope: scope,
      open_context: w6_open_context,
      build_request: fn(_context, state : Int) {
        @core.CodingAgentRequest::{
          instruction: "state=\{state}",
          context_files: [],
        }
      },
      decode_response: fn(_state, _response) {
        @core.NodeOutput::{ patch: Some(1), value: None, artifacts: [] }
      },
    }),
  )
  definition.set_router(
    node_id,
    @core.router([@core.DeclaredRoute::DeclaredRoute(node_id)], fn(
      state,
      _completion,
    ) {
      if state < 2 {
        @core.To(node_id)
      } else {
        @core.End
      }
    }),
  )
  definition.set_entry(node_id)
  @core.GraphRuntime::GraphRuntime(definition.compile(), events~)
}

///|
async test "coding_agent_node lifecycle 1 - node scope opens and closes for every loop attempt" {
  let lifecycle : Array[String] = []
  let runtime = w6_lifecycle_runtime(@core.Node, lifecycle, [], [], false)
  let result = runtime.invoke(0)
  inspect(result.final_state, content="2")
  inspect(result.steps, content="2")
  inspect(
    lifecycle.join(","),
    content="open-1,execute-1,close-1,open-2,execute-2,close-2",
  )
}

///|
async test "coding_agent_node lifecycle 2 - run scope is isolated between invocations" {
  let lifecycle : Array[String] = []
  let runtime = w6_lifecycle_runtime(@core.Run, lifecycle, [], [], false)
  runtime.invoke(0) |> ignore
  runtime.invoke(0) |> ignore
  inspect(
    lifecycle.join(","),
    content="open-1,execute-1,execute-1,close-1,open-2,execute-2,execute-2,close-2",
  )
}

///|
async test "coding_agent_node lifecycle 3 - cancellation closes the session and stops owned work before rethrowing" {
  @async.with_task_group() <| caller_group => {
    let lifecycle : Array[String] = []
    let execute_started : Array[String] = []
    let child_tokens : Array[String] = []
    let events : Array[@core.GraphEvent] = []
    let runtime = w6_lifecycle_runtime(
      @core.Run,
      lifecycle,
      execute_started,
      child_tokens,
      true,
      events=@core.EventSink::EventSink(fn(event) { events.push(event) }),
    )
    let task = caller_group.spawn(
      async fn() { runtime.invoke(0) |> ignore },
      allow_failure=true,
    )
    let mut attempts = 0
    while (execute_started.is_empty() || child_tokens.is_empty()) &&
          attempts < 20 {
      @async.pause()
      attempts = attempts + 1
    }
    inspect(execute_started.join(","), content="started")
    inspect(child_tokens.join(","), content="started")
    task.cancel()
    let cancelled = try {
      task.wait()
      false
    } catch {
      error => @async.is_cancellation_error(error)
    }
    let mut run_cancelled = 0
    for event in events {
      match event {
        @core.RunCancelled(_) => run_cancelled = run_cancelled + 1
        _ => ()
      }
    }
    inspect(cancelled, content="true")
    inspect(lifecycle.join(","), content="open-1,execute-1,close-1")
    inspect(execute_started.join(","), content="started")
    inspect(child_tokens.join(","), content="started")
    inspect(run_cancelled, content="1")
  }
}
