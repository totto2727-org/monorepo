///|
fn routing_fake_response(label : String) -> @core.CodingAgentResponse {
  @core.CodingAgentResponse::{
    status: @core.Succeeded,
    summary: Some(label),
    continuation_id: Some("\{label}-session"),
    changed_files: [],
    artifacts: [],
    raw_output: None,
  }
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
  let graph = build_workflow(
    workflow_reducer(),
    [
      @core.function_node(entry, workflow_metadata("branch-entry"), async fn(
        _context,
        _state,
      ) {
        @async.pause()
        @core.NodeOutput::{ patch: None, value: None, artifacts: [] }
      }),
      workflow_agent_node(left, "left", left_agent.agent()),
      workflow_agent_node(right, "right", right_agent.agent()),
    ],
    [
      (
        entry,
        @core.router([left, right], fn(state, _) {
          if state.order[0] == "left" {
            @core.To(left)
          } else {
            @core.To(right)
          }
        }),
      ),
      (left, @core.router([], fn(_, _) { @core.End })),
      (right, @core.router([], fn(_, _) { @core.End })),
    ],
    entry,
  )
  let result = @core.GraphRuntime::GraphRuntime(
    graph,
    events=events.event_sink(),
  ).invoke(WorkflowState::{ order: [selector], continuation: None })
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
  let graph = build_workflow(
    workflow_reducer(),
    [
      @core.function_node(retry, workflow_metadata("retry"), async fn(
        _context,
        _state,
      ) {
        attempts = attempts + 1
        @async.pause()
        @core.NodeOutput::{
          patch: Some(WorkflowPatch::{ label: "retry", continuation: None }),
          value: None,
          artifacts: [],
        }
      }),
    ],
    [(retry, @core.router([retry], fn(_, _) { @core.To(retry) }))],
    retry,
  )
  let outcome = try {
    @core.GraphRuntime::GraphRuntime(graph, events=events.event_sink()).invoke(
      workflow_initial_state(),
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
  let graph = build_workflow(
    workflow_reducer(),
    [
      @moonllm_node.llm_node(plan, workflow_metadata("plan", kind=@core.Llm), @moonllm_node.LlmNodeSpec::{
        build_request: fn(_context, _state) {
          @llm.ChatRequest::new("fake-model", [@llm.Message::user("plan")])
        },
        invoke: planner.callback(),
        decode_response: fn(_state, _response) {
          @core.NodeOutput::{
            patch: Some(WorkflowPatch::{ label: "planned", continuation: None }),
            value: None,
            artifacts: [],
          }
        },
      }),
      workflow_agent_node(agent_id, "agent", agent.agent()),
    ],
    [
      (plan, @core.router([agent_id], fn(_, _) { @core.To(agent_id) })),
      (agent_id, @core.router([], fn(_, _) { @core.End })),
    ],
    plan,
  )
  let initial = workflow_initial_state()
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
