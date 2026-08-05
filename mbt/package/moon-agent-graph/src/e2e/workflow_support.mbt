///|
/// Shared deterministic workflow state.
pub struct WorkflowState {
  order : Array[String]
  continuation : String?
}

///|
/// Creates deterministic workflow state for E2E scenarios.
pub fn WorkflowState::WorkflowState(
  order : Array[String],
  continuation : String?,
) -> WorkflowState {
  WorkflowState::{ order, continuation }
}

///|
/// Shared deterministic workflow patch.
pub struct WorkflowPatch {
  label : String
  continuation : String?
}

///|
/// Creates one deterministic workflow patch for E2E scenarios.
pub fn WorkflowPatch::WorkflowPatch(
  label : String,
  continuation : String?,
) -> WorkflowPatch {
  WorkflowPatch::{ label, continuation }
}

///|
/// Creates empty workflow state.
pub fn workflow_initial_state() -> WorkflowState {
  WorkflowState::WorkflowState([], None)
}

///|
/// Applies one observable workflow step.
pub fn workflow_reducer() -> @core.Reducer[WorkflowState, WorkflowPatch] {
  @core.Reducer::Reducer(fn(state, patch) {
    WorkflowState::WorkflowState(
      [..state.order, patch.label],
      match patch.continuation {
        Some(value) => Some(value)
        None => state.continuation
      },
    )
  })
}

///|
/// Creates metadata shared by E2E workflow nodes.
pub fn workflow_metadata(
  name : String,
  kind? : @core.NodeKind = @core.Function,
) -> @core.NodeMetadata {
  @core.NodeMetadata::NodeMetadata(name, None, kind, [])
}

///|
/// Creates a deterministic function step.
pub fn workflow_function_node(
  id : @core.NodeId,
  label : String,
) -> @core.Node[WorkflowState, WorkflowPatch] {
  @core.Node::Node(id, workflow_metadata(label), async fn(_context, _state) {
    @async.pause()
    @core.NodeOutput::NodeOutput(
      Some(WorkflowPatch::WorkflowPatch(label, None)),
      None,
      [],
    )
  })
}

///|
/// Creates a run-scoped deterministic coding-agent step.
pub fn workflow_agent_node(
  id : @core.NodeId,
  label : String,
  agent : @core.CodingAgent,
) -> @core.Node[WorkflowState, WorkflowPatch] {
  @coding_agent.coding_agent_node(
    id,
    workflow_metadata(label, kind=@core.CodingAgent),
    @coding_agent.CodingAgentNodeSpec::CodingAgentNodeSpec(
      agent,
      @core.ResourceKey::parse("workflow-\{label}") catch {
        _ => abort("workflow resource key must be valid")
      },
      @core.Run,
      fn(context, _state) {
        @core.CodingAgentOpenContext::CodingAgentOpenContext(
          context.run_id,
          context.task_group,
          @core.WorkspaceRef::WorkspaceRef(@path.Path("."), []),
          @core.Never,
          @core.Disabled,
          @immut_hashmap.new(),
          context.events,
        )
      },
      fn(_context, state) {
        @core.CodingAgentRequest::CodingAgentRequest(
          "\{label} request \{state.order.length() + 1}",
          [],
        )
      },
      fn(_state, response) {
        @core.NodeOutput::NodeOutput(
          Some(WorkflowPatch::WorkflowPatch(label, response.continuation_id)),
          None,
          [],
        )
      },
    ),
  )
}

///|
/// Adds nodes, routers, and entry, then compiles a workflow graph.
pub fn build_workflow(
  reducer : @core.Reducer[WorkflowState, WorkflowPatch],
  nodes : Array[@core.Node[WorkflowState, WorkflowPatch]],
  routers : Array[(@core.NodeId, @core.Router[WorkflowState])],
  entry : @core.NodeId,
) -> @core.CompiledGraph[WorkflowState, WorkflowPatch] raise {
  let definition = @core.GraphDefinition::GraphDefinition(reducer)
  for node in nodes {
    definition.add_node(node)
  }
  for pair in routers {
    let (source, router) = pair
    definition.set_router(source, router)
  }
  definition.set_entry(entry)
  definition.compile()
}
