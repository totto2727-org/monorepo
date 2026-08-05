///|
fn fake_agent_response(label : String) -> @core.CodingAgentResponse {
  @core.CodingAgentResponse::CodingAgentResponse(
    status=@core.Succeeded,
    summary=Some("\{label} done"),
    continuation_id=Some("\{label}-continuation"),
    changed_files=[],
    artifacts=[],
    raw_output=None,
  )
}

///|
fn fake_plan_response(label : String) -> @llm.ChatResponse {
  {
    id: "\{label}-plan-response",
    object: "chat.completion",
    created: 0L,
    model: "workflow-planner",
    choices: [],
    usage: None,
    system_fingerprint: None,
  }
}

///|
fn event_names(events : ReadOnlyArray[@core.GraphEvent]) -> Array[String] {
  [
    ..events.map(event => {
      match event {
        @core.RunStarted(_) => "run-started"
        @core.NodeStarted(node_id~, ..) => "start:\{node_id.to_string()}"
        @core.NodeCompleted(node_id~, ..) => "complete:\{node_id.to_string()}"
        @core.StateUpdated(node_id~, ..) => "state:\{node_id.to_string()}"
        @core.RouteSelected(from~, ..) => "route:\{from.to_string()}"
        @core.RunCompleted(..) => "run-completed"
        @core.RunFailed(..) => "run-failed"
        @core.RunCancelled(_) => "run-cancelled"
        @core.NodeFailed(node_id~, ..) => "failed:\{node_id.to_string()}"
        @core.ResourceOpening(..) => "resource-opening"
        @core.ResourceOpened(..) => "resource-opened"
        @core.ResourceClosed(..) => "resource-closed"
      }
    }),
  ]
}

///|
async test "function-only workflow completes in exact order" {
  let plan = @core.NodeId::parse("plan")
  let verify = @core.NodeId::parse("verify")
  let events = @testing.recording_event_sink()
  let graph = @e2e.build_workflow(
    @e2e.workflow_reducer(),
    [
      @e2e.workflow_function_node(plan, "plan"),
      @e2e.workflow_function_node(verify, "verify"),
    ],
    [
      (
        plan,
        @core.router([@core.DeclaredRoute::DeclaredRoute(verify)], fn(_, _) {
          @core.To(verify)
        }),
      ),
      (verify, @core.router([], fn(_, _) { @core.End })),
    ],
    plan,
  )
  let result = @core.GraphRuntime::GraphRuntime(
    graph,
    events=events.event_sink(),
  ).invoke(@e2e.workflow_initial_state())
  debug_inspect(result.final_state.order, content="[\"plan\", \"verify\"]")
  inspect(result.steps, content="2")
  debug_inspect(
    event_names(events.events()),
    content=(
      #|[
      #|  "run-started",
      #|  "start:plan",
      #|  "complete:plan",
      #|  "state:plan",
      #|  "route:plan",
      #|  "start:verify",
      #|  "complete:verify",
      #|  "state:verify",
      #|  "route:verify",
      #|  "run-completed",
      #|]
    ),
  )
}

///|
async test "MoonLLM plan to function verify workflow records typed request" {
  let plan = @core.NodeId::parse("llm-plan")
  let verify = @core.NodeId::parse("llm-verify")
  let planner = @testing.fake_moonllm_invoke(fake_plan_response("llm"))
  let events = @testing.recording_event_sink()
  let graph = @e2e.build_workflow(
    @e2e.workflow_reducer(),
    [
      @moonllm_node.llm_node(
        plan,
        @e2e.workflow_metadata("plan", kind=@core.Llm),
        @moonllm_node.LlmNodeSpec::LlmNodeSpec(
          fn(_context, _state) {
            @llm.ChatRequest::new("workflow-planner", [
              @llm.Message::user("plan deterministic verification"),
            ])
          },
          planner.callback(),
          fn(_state, _response) {
            @core.NodeOutput::NodeOutput(
              Some(@e2e.WorkflowPatch::WorkflowPatch("plan", None)),
              None,
              [],
            )
          },
        ),
      ),
      @e2e.workflow_function_node(verify, "verify"),
    ],
    [
      (
        plan,
        @core.router([@core.DeclaredRoute::DeclaredRoute(verify)], fn(_, _) {
          @core.To(verify)
        }),
      ),
      (verify, @core.router([], fn(_, _) { @core.End })),
    ],
    plan,
  )
  let result = @core.GraphRuntime::GraphRuntime(
    graph,
    events=events.event_sink(),
  ).invoke(@e2e.workflow_initial_state())
  inspect(planner.requests().length(), content="1")
  inspect(planner.requests()[0].model, content="workflow-planner")
  inspect(
    planner.requests()[0].messages[0].content.to_text(),
    content="plan deterministic verification",
  )
  debug_inspect(result.final_state.order, content="[\"plan\", \"verify\"]")
  debug_inspect(result.final_state.continuation, content="None")
  inspect(result.steps, content="2")
  debug_inspect(
    event_names(events.events()),
    content=(
      #|[
      #|  "run-started",
      #|  "start:llm-plan",
      #|  "complete:llm-plan",
      #|  "state:llm-plan",
      #|  "route:llm-plan",
      #|  "start:llm-verify",
      #|  "complete:llm-verify",
      #|  "state:llm-verify",
      #|  "route:llm-verify",
      #|  "run-completed",
      #|]
    ),
  )
}

///|
async fn exercise_agent_workflow(label : String, retry : Bool) -> Unit {
  let plan = @core.NodeId::parse("\{label}-plan")
  let agent_id = @core.NodeId::parse("\{label}-agent")
  let verify = @core.NodeId::parse("\{label}-verify")
  let session_id = @core.SessionId::parse("\{label}-session")
  let agent = @testing.fake_coding_agent(
    fake_agent_response(label),
    session_id~,
  )
  let planner = @testing.fake_moonllm_invoke(fake_plan_response(label))
  let events = @testing.recording_event_sink()
  let agent_router = @core.router(
    if retry {
      [
        @core.DeclaredRoute::DeclaredRoute(agent_id),
        @core.DeclaredRoute::DeclaredRoute(verify),
      ]
    } else {
      [@core.DeclaredRoute::DeclaredRoute(verify)]
    },
    fn(state : @e2e.WorkflowState, _) {
      if retry && state.order.filter(value => value == label).length() == 1 {
        @core.To(agent_id)
      } else {
        @core.To(verify)
      }
    },
  )
  let graph = @e2e.build_workflow(
    @e2e.workflow_reducer(),
    [
      @moonllm_node.llm_node(
        plan,
        @e2e.workflow_metadata("plan", kind=@core.Llm),
        @moonllm_node.LlmNodeSpec::LlmNodeSpec(
          fn(_context, _state) {
            @llm.ChatRequest::new("workflow-planner", [
              @llm.Message::user("\{label} plan"),
            ])
          },
          planner.callback(),
          fn(_state, _response) {
            @core.NodeOutput::NodeOutput(
              Some(@e2e.WorkflowPatch::WorkflowPatch("plan", None)),
              None,
              [],
            )
          },
        ),
      ),
      @e2e.workflow_agent_node(agent_id, label, agent.agent()),
      @e2e.workflow_function_node(verify, "verify"),
    ],
    [
      (
        plan,
        @core.router([@core.DeclaredRoute::DeclaredRoute(agent_id)], fn(_, _) {
          @core.To(agent_id)
        }),
      ),
      (agent_id, agent_router),
      (verify, @core.router([], fn(_, _) { @core.End })),
    ],
    plan,
  )
  let result = @core.GraphRuntime::GraphRuntime(
    graph,
    events=events.event_sink(),
  ).invoke(@e2e.workflow_initial_state())
  let expected_steps = if retry { 4 } else { 3 }
  if retry {
    debug_inspect(
      result.final_state.order,
      content="[\"plan\", \"codex\", \"codex\", \"verify\"]",
    )
  } else {
    debug_inspect(
      result.final_state.order,
      content="[\"plan\", \"opencode\", \"verify\"]",
    )
  }
  inspect(result.steps, content=expected_steps.to_string())
  inspect(planner.requests().length(), content="1")
  inspect(planner.requests()[0].model, content="workflow-planner")
  inspect(
    planner.requests()[0].messages[0].content.to_text(),
    content="\{label} plan",
  )
  debug_inspect(
    result.final_state.continuation,
    content="Some(\"\{label}-continuation\")",
  )
  inspect(agent.open_calls().length(), content="1")
  inspect(agent.request_calls().length(), content=if retry { "2" } else { "1" })
  inspect(agent.close_order().length(), content="1")
  if retry {
    inspect(
      agent.request_calls()[0].request.instruction,
      content="\{label} request 2",
    )
    inspect(
      agent.request_calls()[1].request.instruction,
      content="\{label} request 3",
    )
  }
  let names = event_names(events.events())
  inspect(names[0], content="run-started")
  inspect(names[names.length() - 1], content="run-completed")
}

///|
async test "Codex-labelled plan-agent-test workflow reuses run session on retry" {
  exercise_agent_workflow("codex", true)
}

///|
async test "OpenCode-labelled plan-agent-test workflow completes once" {
  exercise_agent_workflow("opencode", false)
}

///|
fn routing_fake_response(label : String) -> @core.CodingAgentResponse {
  @core.CodingAgentResponse::CodingAgentResponse(
    status=@core.Succeeded,
    summary=Some(label),
    continuation_id=Some("\{label}-session"),
    changed_files=[],
    artifacts=[],
    raw_output=None,
  )
}

///|
fn routing_fake_chat_response() -> @llm.ChatResponse {
  @llm.ChatResponse::{
    id: "routing-plan",
    object: "chat.completion",
    created: 0L,
    model: "fake-model",
    choices: [],
    usage: None,
    system_fingerprint: None,
  }
}

///|
fn routing_event_names(
  events : ReadOnlyArray[@core.GraphEvent],
) -> Array[String] {
  let names : Array[String] = []
  for event in events {
    let name = match event {
      @core.RunStarted(_) => "run-started"
      @core.RunCompleted(..) => "run-completed"
      @core.RunFailed(..) => "run-failed"
      @core.NodeStarted(node_id~, ..) => "start:\{node_id.to_string()}"
      @core.NodeCompleted(node_id~, ..) => "complete:\{node_id.to_string()}"
      @core.RouteSelected(from~, ..) => "route:\{from.to_string()}"
      @core.StateUpdated(node_id~, ..) => "state:\{node_id.to_string()}"
      @core.ResourceOpening(..) => "resource-opening"
      @core.ResourceOpened(..) => "resource-opened"
      @core.ResourceClosed(..) => "resource-closed"
      @core.RunCancelled(_) => "run-cancelled"
      @core.NodeFailed(node_id~, ..) => "failed:\{node_id.to_string()}"
    }
    names.push(name)
  }
  names
}

///|
async fn routing_exercise_branch(selector : String) -> Unit {
  let entry = @core.NodeId::parse("branch-entry")
  let left = @core.NodeId::parse("branch-left")
  let right = @core.NodeId::parse("branch-right")
  let left_agent = @testing.fake_coding_agent(routing_fake_response("left"))
  let right_agent = @testing.fake_coding_agent(routing_fake_response("right"))
  let events = @testing.recording_event_sink()
  let graph = @e2e.build_workflow(
    @e2e.workflow_reducer(),
    [
      @core.Node::Node(entry, @e2e.workflow_metadata("branch-entry"), async fn(
        _context,
        _state,
      ) {
        @async.pause()
        @core.NodeOutput::NodeOutput(None, None, [])
      }),
      @e2e.workflow_agent_node(left, "left", left_agent.agent()),
      @e2e.workflow_agent_node(right, "right", right_agent.agent()),
    ],
    [
      (
        entry,
        @core.router(
          [
            @core.DeclaredRoute::DeclaredRoute(left),
            @core.DeclaredRoute::DeclaredRoute(right),
          ],
          fn(state, _) {
            if state.order[0] == "left" {
              @core.To(left)
            } else {
              @core.To(right)
            }
          },
        ),
      ),
      (left, @core.router([], fn(_, _) { @core.End })),
      (right, @core.router([], fn(_, _) { @core.End })),
    ],
    entry,
  )
  let result = @core.GraphRuntime::GraphRuntime(
    graph,
    events=events.event_sink(),
  ).invoke(@e2e.WorkflowState::WorkflowState([selector], None))
  let selected = if selector == "left" { "left" } else { "right" }
  let unselected = if selector == "left" { "right" } else { "left" }
  let selected_node = "branch-\{selected}"
  let unselected_node = "branch-\{unselected}"
  debug_inspect(
    result.final_state.order,
    content="[\"\{selector}\", \"\{selected}\"]",
  )
  inspect(result.steps, content="2")
  inspect(
    left_agent.open_calls().length(),
    content=if selector == "left" { "1" } else { "0" },
  )
  inspect(
    right_agent.open_calls().length(),
    content=if selector == "right" { "1" } else { "0" },
  )
  let names = routing_event_names(events.events())
  assert_true(names.contains("start:\{selected_node}"))
  assert_false(names.contains("start:\{unselected_node}"))
  inspect(names[names.length() - 1], content="run-completed")
}

///|
async test "routing failure 1 - both selector inputs open exactly one matching agent" {
  routing_exercise_branch("left")
  routing_exercise_branch("right")
}

///|
async test "routing failure 2 - retry loop has exact attempts before configured step limit" {
  let retry = @core.NodeId::parse("retry")
  let mut attempts = 0
  let events = @testing.recording_event_sink()
  let graph = @e2e.build_workflow(
    @e2e.workflow_reducer(),
    [
      @core.Node::Node(retry, @e2e.workflow_metadata("retry"), async fn(
        _context,
        _state,
      ) {
        attempts = attempts + 1
        @async.pause()
        @core.NodeOutput::NodeOutput(
          Some(@e2e.WorkflowPatch::WorkflowPatch("retry", None)),
          None,
          [],
        )
      }),
    ],
    [
      (
        retry,
        @core.router([@core.DeclaredRoute::DeclaredRoute(retry)], fn(_, _) {
          @core.To(retry)
        }),
      ),
    ],
    retry,
  )
  let outcome = try {
    @core.GraphRuntime::GraphRuntime(graph, events=events.event_sink()).invoke(
      @e2e.workflow_initial_state(),
      options=@core.RunOptions::RunOptions(max_steps=2),
    )
    |> ignore
    "no error"
  } catch {
    @core.StepLimitExceeded(limit~) => "StepLimitExceeded:\{limit}"
    error => "unexpected:\{error}"
  }
  inspect(outcome, content="StepLimitExceeded:2")
  inspect(attempts, content="2")
  debug_inspect(
    routing_event_names(events.events()),
    content=(
      #|[
      #|  "run-started",
      #|  "start:retry",
      #|  "complete:retry",
      #|  "state:retry",
      #|  "route:retry",
      #|  "start:retry",
      #|  "complete:retry",
      #|  "state:retry",
      #|  "route:retry",
      #|  "run-failed",
      #|]
    ),
  )
}

///|
async test "routing failure 3 - planning failure leaves agent and workflow state untouched" {
  let plan = @core.NodeId::parse("plan")
  let agent_id = @core.NodeId::parse("agent")
  let agent = @testing.fake_coding_agent(routing_fake_response("unopened"))
  let planner = @testing.fake_moonllm_invoke(
    routing_fake_chat_response(),
    error=@llm.Transport("planning offline"),
  )
  let events = @testing.recording_event_sink()
  let graph = @e2e.build_workflow(
    @e2e.workflow_reducer(),
    [
      @moonllm_node.llm_node(
        plan,
        @e2e.workflow_metadata("plan", kind=@core.Llm),
        @moonllm_node.LlmNodeSpec::LlmNodeSpec(
          fn(_context, _state) {
            @llm.ChatRequest::new("fake-model", [@llm.Message::user("plan")])
          },
          planner.callback(),
          fn(_state, _response) {
            @core.NodeOutput::NodeOutput(
              Some(@e2e.WorkflowPatch::WorkflowPatch("planned", None)),
              None,
              [],
            )
          },
        ),
      ),
      @e2e.workflow_agent_node(agent_id, "agent", agent.agent()),
    ],
    [
      (
        plan,
        @core.router([@core.DeclaredRoute::DeclaredRoute(agent_id)], fn(_, _) {
          @core.To(agent_id)
        }),
      ),
      (agent_id, @core.router([], fn(_, _) { @core.End })),
    ],
    plan,
  )
  let initial = @e2e.workflow_initial_state()
  let outcome = try {
    @core.GraphRuntime::GraphRuntime(graph, events=events.event_sink()).invoke(
      initial,
    )
    |> ignore
    "no error"
  } catch {
    @core.NodeFailed(node_id~, cause=@llm.Transport(message), ..) =>
      "NodeFailed:\{node_id.to_string()}:\{message}"
    error => "unexpected:\{error}"
  }
  inspect(outcome, content="NodeFailed:plan:planning offline")
  inspect(planner.requests().length(), content="1")
  inspect(agent.open_calls().length(), content="0")
  inspect(agent.request_calls().length(), content="0")
  debug_inspect(initial.order, content="[]")
  debug_inspect(initial.continuation, content="None")
  debug_inspect(
    routing_event_names(events.events()),
    content="[\"run-started\", \"start:plan\", \"failed:plan\", \"run-failed\"]",
  )
}

///|
struct CancellationWorkflowSession {
  started : Array[String]
  released : Ref[Bool]
  finished : Array[String]
  closes : Array[String]
}

///|
impl @core.CodingAgentSession for CancellationWorkflowSession with fn id(_self) {
  Some(
    @core.SessionId::parse("cancellation-workflow-session") catch {
      _ => abort("test session ID must be valid")
    },
  )
}

///|
impl @core.CodingAgentSession for CancellationWorkflowSession with fn execute(
  self,
  _request,
) {
  self.started.push("started")
  while !self.released.val {
    @async.pause()
  }
  self.finished.push("finished")
  @core.CodingAgentResponse::CodingAgentResponse(
    status=@core.Succeeded,
    summary=None,
    continuation_id=Some("cancellation-workflow-session"),
    changed_files=[],
    artifacts=[],
    raw_output=None,
  )
}

///|
impl @core.CodingAgentSession for CancellationWorkflowSession with fn close(
  self,
) {
  self.closes.push("closed")
}

///|
async test "coding-agent workflow cancellation stops before the later node and closes once" {
  @async.with_task_group() <| caller_group => {
    let agent_id = @core.NodeId::parse("cancel-agent")
    let later_id = @core.NodeId::parse("later-test")
    let started : Array[String] = []
    let released = Ref(false)
    let finished : Array[String] = []
    let closes : Array[String] = []
    let later_calls : Array[String] = []
    let events = @testing.recording_event_sink()
    let agent = @core.CodingAgent::CodingAgent(
      @core.CodingAgentId::parse("cancellation-workflow-agent"),
      async fn(_context) {
        @async.pause()
        let session = CancellationWorkflowSession::{
          started,
          released,
          finished,
          closes,
        }
        (session : &@core.CodingAgentSession)
      },
    )
    let later = @moonllm_node.llm_node(
      later_id,
      @e2e.workflow_metadata("later-test", kind=@core.Llm),
      @moonllm_node.LlmNodeSpec::LlmNodeSpec(
        fn(_context, _state : @e2e.WorkflowState) {
          later_calls.push("called")
          @llm.ChatRequest::new("unreachable", [
            @llm.Message::user("must not run"),
          ])
        },
        async fn(_request) {
          @async.pause()
          abort("later LLM node must not invoke")
        },
        fn(_state, _response) {
          @core.NodeOutput::NodeOutput(
            Some(@e2e.WorkflowPatch::WorkflowPatch("later-test", None)),
            None,
            [],
          )
        },
      ),
    )
    let graph = @e2e.build_workflow(
      @e2e.workflow_reducer(),
      [@e2e.workflow_agent_node(agent_id, "cancel-agent", agent), later],
      [
        (
          agent_id,
          @core.router([@core.DeclaredRoute::DeclaredRoute(later_id)], fn(
            _,
            _,
          ) {
            @core.To(later_id)
          }),
        ),
        (later_id, @core.router([], fn(_, _) { @core.End })),
      ],
      agent_id,
    )
    let runtime = @core.GraphRuntime::GraphRuntime(
      graph,
      events=events.event_sink(),
    )
    let invoke = caller_group.spawn(
      async fn() { runtime.invoke(@e2e.workflow_initial_state()) |> ignore },
      allow_failure=true,
    )
    let mut attempts = 0
    while started.is_empty() && attempts < 20 {
      @async.pause()
      attempts = attempts + 1
    }
    inspect(started.join(","), content="started")
    invoke.cancel()
    let cancelled = try {
      invoke.wait()
      false
    } catch {
      error => @async.is_cancellation_error(error)
    }
    let mut run_cancelled = 0
    for event in events.events() {
      if event is @core.RunCancelled(_) {
        run_cancelled = run_cancelled + 1
      }
    }
    inspect(cancelled, content="true")
    inspect(finished.join(","), content="")
    inspect(later_calls.join(","), content="")
    inspect(closes.join(","), content="closed")
    inspect(run_cancelled, content="1")
  }
}
