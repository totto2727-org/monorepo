///|
/// Shared deterministic workflow state.
pub(all) struct WorkflowState {
  order : Array[String]
  continuation : String?
}

///|
/// Shared deterministic workflow patch.
pub(all) struct WorkflowPatch {
  label : String
  continuation : String?
}

///|
/// Creates empty workflow state.
pub fn workflow_initial_state() -> WorkflowState {
  { order: [], continuation: None }
}

///|
/// Applies one observable workflow step.
pub fn workflow_reducer() -> @core.Reducer[WorkflowState, WorkflowPatch] {
  {
    apply: fn(state, patch) {
      {
        order: [..state.order, patch.label],
        continuation: match patch.continuation {
          Some(value) => Some(value)
          None => state.continuation
        },
      }
    },
  }
}

///|
/// Creates metadata shared by E2E workflow nodes.
pub fn workflow_metadata(
  name : String,
  kind? : @core.NodeKind = @core.Function,
) -> @core.NodeMetadata {
  { name, description: None, kind, tags: [] }
}

///|
/// Creates a deterministic function step.
pub fn workflow_function_node(
  id : @core.NodeId,
  label : String,
) -> @core.Node[WorkflowState, WorkflowPatch] {
  @core.function_node(id, workflow_metadata(label), async fn(_context, _state) {
    @async.pause()
    @core.NodeOutput::{
      patch: Some({ label, continuation: None }),
      value: None,
      artifacts: [],
    }
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
    @coding_agent.CodingAgentNodeSpec::{
      agent,
      resource_key: @core.ResourceKey::parse("workflow-\{label}") catch {
        _ => abort("workflow resource key must be valid")
      },
      resource_scope: @core.Run,
      open_context: fn(context, _state) {
        @core.CodingAgentOpenContext::{
          run_id: context.run_id,
          task_group: context.task_group,
          workspace: @core.WorkspaceRef::{
            root: @path.Path("."),
            additional_writable_roots: [],
          },
          approval: @core.Never,
          network: @core.Disabled,
          environment: Map([]),
          events: context.events,
        }
      },
      build_request: fn(_context, state) {
        @core.CodingAgentRequest::{
          instruction: "\{label} request \{state.order.length() + 1}",
          context_files: [],
        }
      },
      decode_response: fn(_state, response) {
        @core.NodeOutput::{
          patch: Some({ label, continuation: response.continuation_id }),
          value: None,
          artifacts: [],
        }
      },
    },
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
