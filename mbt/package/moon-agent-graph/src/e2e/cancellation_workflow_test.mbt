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
  @core.CodingAgentResponse::{
    status: @core.Succeeded,
    summary: None,
    continuation_id: Some("cancellation-workflow-session"),
    changed_files: [],
    artifacts: [],
    raw_output: None,
  }
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
    let agent = @core.CodingAgent::{
      id: @core.CodingAgentId::parse("cancellation-workflow-agent"),
      open: async fn(_context) {
        @async.pause()
        let session = CancellationWorkflowSession::{
          started,
          released,
          finished,
          closes,
        }
        (session : &@core.CodingAgentSession)
      },
    }
    let later = @moonllm_node.llm_node(
      later_id,
      workflow_metadata("later-test", kind=@core.Llm),
      @moonllm_node.LlmNodeSpec::{
        build_request: fn(_context, _state : WorkflowState) {
          later_calls.push("called")
          @llm.ChatRequest::new("unreachable", [
            @llm.Message::user("must not run"),
          ])
        },
        invoke: async fn(_request) {
          @async.pause()
          abort("later LLM node must not invoke")
        },
        decode_response: fn(_state, _response) {
          @core.NodeOutput::{
            patch: Some(WorkflowPatch::{
              label: "later-test",
              continuation: None,
            }),
            value: None,
            artifacts: [],
          }
        },
      },
    )
    let graph = build_workflow(
      workflow_reducer(),
      [workflow_agent_node(agent_id, "cancel-agent", agent), later],
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
      async fn() { runtime.invoke(workflow_initial_state()) |> ignore },
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
