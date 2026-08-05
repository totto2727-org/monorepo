///|
suberror CodingAgentNodeTestError {
  OpenContextFailed
  OpenFailed
  RequestBuildFailed
  ExecuteFailed
  DecodeFailed
} derive(Debug)

///|
enum CodingAgentNodeFailurePhase {
  OpenContext
  Open
  Request
  Execute
  Decode
} derive(Eq)

///|
struct CodingAgentNodeFakeSession {
  executions : Array[String]
  closed : Array[String]
  fail_execute : Bool
}

///|
fn coding_agent_node_test_run_id(value : String) -> @core.RunId {
  @core.RunId::parse(value) catch {
    _ => abort("test run ID must be valid")
  }
}

///|
fn coding_agent_node_test_session_id() -> @core.SessionId {
  @core.SessionId::parse("coding-agent-node-session") catch {
    _ => abort("test session ID must be valid")
  }
}

///|
impl @core.CodingAgentSession for CodingAgentNodeFakeSession with fn id(_self) {
  Some(coding_agent_node_test_session_id())
}

///|
impl @core.CodingAgentSession for CodingAgentNodeFakeSession with fn execute(
  self,
  request,
) {
  self.executions.push(request.instruction)
  @async.pause()
  if self.fail_execute {
    raise ExecuteFailed
  }
  @core.CodingAgentResponse::{
    status: @core.Succeeded,
    summary: Some("completed"),
    continuation_id: Some("continue-42"),
    changed_files: [@path.Path("src/changed.mbt")],
    artifacts: [
      @core.Artifact::{
        kind: @core.Text,
        name: "agent-output",
        uri: None,
        metadata: Some(Json::string("recorded")),
      },
    ],
    raw_output: Some(Json::string("raw")),
  }
}

///|
impl @core.CodingAgentSession for CodingAgentNodeFakeSession with fn close(self) {
  @async.pause()
  self.closed.push("closed")
}

///|
fn coding_agent_node_metadata(name : String) -> @core.NodeMetadata {
  @core.NodeMetadata::{
    name,
    description: None,
    kind: @core.CodingAgent,
    tags: ["coding-agent-node-test"],
  }
}

///|
fn coding_agent_node_context(
  group : @async.TaskGroup[Unit],
  node_id : @core.NodeId,
  resources : @core.ResourceStore,
) -> @core.NodeContext {
  @core.NodeContext::NodeContext(
    coding_agent_node_test_run_id("coding-agent-node-run"),
    node_id,
    1,
    group,
    resources~,
  )
}

///|
fn coding_agent_open_context(
  group : @async.TaskGroup[Unit],
) -> @core.CodingAgentOpenContext {
  @core.CodingAgentOpenContext::{
    run_id: coding_agent_node_test_run_id("coding-agent-open-run"),
    task_group: group,
    workspace: @core.WorkspaceRef::{
      root: @path.Path("/workspace"),
      additional_writable_roots: [],
    },
    approval: @core.Never,
    network: @core.Disabled,
    environment: @immut_hashmap.new(),
    events: @core.EventSink::discard(),
  }
}

///|
async test "coding_agent_node 1 - executes and decodes continuation and changed files" {
  @async.with_task_group() <| group => {
    let node_id = @core.NodeId::parse("coding-agent-success")
    let resources = @core.ResourceStore::ResourceStore()
    let opens : Array[String] = []
    let executions : Array[String] = []
    let closed : Array[String] = []
    let decoded : Array[String] = []
    let node : @core.Node[Int, Int] = coding_agent_node(
      node_id,
      coding_agent_node_metadata("coding-agent-success"),
      CodingAgentNodeSpec::{
        agent: @core.CodingAgent::{
          id: @core.CodingAgentId::parse("fake"),
          open: async fn(_context) {
            @async.pause()
            opens.push("open")
            let session = CodingAgentNodeFakeSession::{
              executions,
              closed,
              fail_execute: false,
            }
            (session : &@core.CodingAgentSession)
          },
        },
        resource_key: @core.ResourceKey::parse("coding-agent-success"),
        resource_scope: @core.Node,
        open_context: fn(_context, _state) { coding_agent_open_context(group) },
        build_request: fn(_context, state) {
          @core.CodingAgentRequest::{
            instruction: "apply-\{state}",
            context_files: [@path.Path("README.md")],
          }
        },
        decode_response: fn(_state, response) {
          let continuation = response.continuation_id.unwrap_or("missing")
          decoded.push(
            "\{continuation}:\{response.changed_files[0].to_string()}:\{response.artifacts[0].name}",
          )
          @core.NodeOutput::{
            patch: Some(3),
            value: response.raw_output,
            artifacts: response.artifacts,
          }
        },
      },
    )
    let output = (node.execute)(
      coding_agent_node_context(group, node_id, resources),
      7,
    )
    resources.release_node(node_id)
    inspect(opens.join(","), content="open")
    inspect(executions.join(","), content="apply-7")
    inspect(
      decoded.join(","),
      content="continue-42:src/changed.mbt:agent-output",
    )
    debug_inspect(output.patch, content="Some(3)")
    inspect(closed.join(","), content="closed")
  }
}

///|
async test "coding_agent_node 2 - reuses a run session through two GraphRuntime attempts" {
  let node_id = @core.NodeId::parse("coding-agent-run")
  let opens : Array[String] = []
  let executions : Array[String] = []
  let closed : Array[String] = []
  let node : @core.Node[Int, Int] = coding_agent_node(
    node_id,
    coding_agent_node_metadata("coding-agent-run"),
    CodingAgentNodeSpec::{
      agent: @core.CodingAgent::{
        id: @core.CodingAgentId::parse("fake-run"),
        open: async fn(_context) {
          @async.pause()
          opens.push("open")
          let session = CodingAgentNodeFakeSession::{
            executions,
            closed,
            fail_execute: false,
          }
          (session : &@core.CodingAgentSession)
        },
      },
      resource_key: @core.ResourceKey::parse("coding-agent-run"),
      resource_scope: @core.Run,
      open_context: fn(context, _state) {
        coding_agent_open_context(context.task_group)
      },
      build_request: fn(_context, state) {
        @core.CodingAgentRequest::{
          instruction: "step-\{state}",
          context_files: [],
        }
      },
      decode_response: fn(_state, _response) {
        @core.NodeOutput::{ patch: Some(1), value: None, artifacts: [] }
      },
    },
  )
  let definition = @core.GraphDefinition::GraphDefinition(@core.Reducer::{
    apply: fn(state : Int, patch : Int) { state + patch },
  })
  definition.add_node(node)
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
  let result = @core.GraphRuntime::GraphRuntime(definition.compile()).invoke(0)
  inspect(result.final_state, content="2")
  inspect(result.steps, content="2")
  inspect(opens.join(","), content="open")
  inspect(executions.join(","), content="step-0,step-1")
  inspect(closed.join(","), content="closed")
}

///|
async fn coding_agent_node_assert_phase(
  phase : CodingAgentNodeFailurePhase,
) -> Unit {
  @async.with_task_group() <| group => {
    let node_id = @core.NodeId::parse("coding-agent-phase")
    let resources = @core.ResourceStore::ResourceStore()
    let calls : Array[String] = []
    let node : @core.Node[Int, Int] = coding_agent_node(
      node_id,
      coding_agent_node_metadata("coding-agent-phase"),
      CodingAgentNodeSpec::{
        agent: @core.CodingAgent::{
          id: @core.CodingAgentId::parse("fake-phase"),
          open: async fn(_context) {
            @async.pause()
            calls.push("open")
            if phase == Open {
              raise OpenFailed
            }
            let session = CodingAgentNodeFakeSession::{
              executions: calls,
              closed: calls,
              fail_execute: phase == Execute,
            }
            (session : &@core.CodingAgentSession)
          },
        },
        resource_key: @core.ResourceKey::parse("coding-agent-phase"),
        resource_scope: @core.Node,
        open_context: (_context, _state) => {
          calls.push("open-context")
          if phase == OpenContext {
            raise OpenContextFailed
          }
          coding_agent_open_context(group)
        },
        build_request: (_context, _state) => {
          calls.push("request")
          if phase == Request {
            raise RequestBuildFailed
          }
          @core.CodingAgentRequest::{ instruction: "phase", context_files: [] }
        },
        decode_response: (_state, _response) => {
          calls.push("decode")
          if phase == Decode {
            raise DecodeFailed
          }
          @core.NodeOutput::{ patch: None, value: None, artifacts: [] }
        },
      },
    )
    let observed = try {
      (node.execute)(coding_agent_node_context(group, node_id, resources), 0)
      |> ignore
      false
    } catch {
      OpenContextFailed => phase == OpenContext
      OpenFailed => phase == Open
      RequestBuildFailed => phase == Request
      ExecuteFailed => phase == Execute
      DecodeFailed => phase == Decode
      _ => false
    }
    resources.release_node(node_id) catch {
      _ => ()
    }
    inspect(observed, content="true")
    let expected_calls = match phase {
      OpenContext => "open-context"
      Open => "open-context,open"
      Request => "open-context,open,request,closed"
      Execute => "open-context,open,request,phase,closed"
      Decode => "open-context,open,request,phase,decode,closed"
    }
    inspect(calls.join(","), content=expected_calls)
  }
}

///|
async test "coding_agent_node 3 - preserves every phase failure and stops later phases" {
  coding_agent_node_assert_phase(OpenContext)
  coding_agent_node_assert_phase(Open)
  coding_agent_node_assert_phase(Request)
  coding_agent_node_assert_phase(Execute)
  coding_agent_node_assert_phase(Decode)
}

///|
async test "coding_agent_node 4 - retries an open failure without caching it" {
  @async.with_task_group() <| group => {
    let node_id = @core.NodeId::parse("coding-agent-open-retry")
    let resources = @core.ResourceStore::ResourceStore()
    let mut opens = 0
    let executions : Array[String] = []
    let closed : Array[String] = []
    let node : @core.Node[Int, Int] = coding_agent_node(
      node_id,
      coding_agent_node_metadata("coding-agent-open-retry"),
      CodingAgentNodeSpec::{
        agent: @core.CodingAgent::{
          id: @core.CodingAgentId::parse("fake-retry"),
          open: async fn(_context) {
            @async.pause()
            opens = opens + 1
            if opens == 1 {
              raise OpenFailed
            }
            let session = CodingAgentNodeFakeSession::{
              executions,
              closed,
              fail_execute: false,
            }
            (session : &@core.CodingAgentSession)
          },
        },
        resource_key: @core.ResourceKey::parse("coding-agent-open-retry"),
        resource_scope: @core.Run,
        open_context: fn(_context, _state) { coding_agent_open_context(group) },
        build_request: fn(_context, _state) {
          @core.CodingAgentRequest::{ instruction: "retry", context_files: [] }
        },
        decode_response: fn(_state, _response) {
          @core.NodeOutput::{ patch: Some(1), value: None, artifacts: [] }
        },
      },
    )
    let first = try {
      (node.execute)(coding_agent_node_context(group, node_id, resources), 0)
      |> ignore
      false
    } catch {
      OpenFailed => true
      _ => false
    }
    let second = (node.execute)(
      coding_agent_node_context(group, node_id, resources),
      0,
    )
    resources.close_all()
    inspect(first, content="true")
    inspect(opens, content="2")
    inspect(executions.join(","), content="retry")
    inspect(closed.join(","), content="closed")
    debug_inspect(second.patch, content="Some(1)")
  }
}

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
