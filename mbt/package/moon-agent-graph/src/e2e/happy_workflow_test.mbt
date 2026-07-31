///|
fn fake_agent_response(label : String) -> @core.CodingAgentResponse {
  {
    status: @core.Succeeded,
    summary: Some("\{label} done"),
    continuation_id: Some("\{label}-continuation"),
    changed_files: [],
    artifacts: [],
    raw_output: None,
  }
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
  let graph = build_workflow(
    workflow_reducer(),
    [
      workflow_function_node(plan, "plan"),
      workflow_function_node(verify, "verify"),
    ],
    [
      (plan, @core.router([verify], fn(_, _) { @core.To(verify) })),
      (verify, @core.router([], fn(_, _) { @core.End })),
    ],
    plan,
  )
  let result = @core.GraphRuntime::GraphRuntime(
    graph,
    events=events.event_sink(),
  ).invoke(workflow_initial_state())
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
  let graph = build_workflow(
    workflow_reducer(),
    [
      @moonllm_node.llm_node(plan, workflow_metadata("plan", kind=@core.Llm), @moonllm_node.LlmNodeSpec::{
        build_request: fn(_context, _state) {
          @llm.ChatRequest::new("workflow-planner", [
            @llm.Message::user("plan deterministic verification"),
          ])
        },
        invoke: planner.callback(),
        decode_response: fn(_state, _response) {
          @core.NodeOutput::{
            patch: Some({ label: "plan", continuation: None }),
            value: None,
            artifacts: [],
          }
        },
      }),
      workflow_function_node(verify, "verify"),
    ],
    [
      (plan, @core.router([verify], fn(_, _) { @core.To(verify) })),
      (verify, @core.router([], fn(_, _) { @core.End })),
    ],
    plan,
  )
  let result = @core.GraphRuntime::GraphRuntime(
    graph,
    events=events.event_sink(),
  ).invoke(workflow_initial_state())
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
      [agent_id, verify]
    } else {
      [verify]
    },
    fn(state : WorkflowState, _) {
      if retry && state.order.filter(value => value == label).length() == 1 {
        @core.To(agent_id)
      } else {
        @core.To(verify)
      }
    },
  )
  let graph = build_workflow(
    workflow_reducer(),
    [
      @moonllm_node.llm_node(plan, workflow_metadata("plan", kind=@core.Llm), @moonllm_node.LlmNodeSpec::{
        build_request: fn(_context, _state) {
          @llm.ChatRequest::new("workflow-planner", [
            @llm.Message::user("\{label} plan"),
          ])
        },
        invoke: planner.callback(),
        decode_response: fn(_state, _response) {
          @core.NodeOutput::{
            patch: Some({ label: "plan", continuation: None }),
            value: None,
            artifacts: [],
          }
        },
      }),
      workflow_agent_node(agent_id, label, agent.agent()),
      workflow_function_node(verify, "verify"),
    ],
    [
      (plan, @core.router([agent_id], fn(_, _) { @core.To(agent_id) })),
      (agent_id, agent_router),
      (verify, @core.router([], fn(_, _) { @core.End })),
    ],
    plan,
  )
  let result = @core.GraphRuntime::GraphRuntime(
    graph,
    events=events.event_sink(),
  ).invoke(workflow_initial_state())
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
