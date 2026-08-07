///|
struct OpenCodeExampleState {
  instruction : String
  summary : String
}

///|
struct OpenCodeExamplePatch {
  summary : String
}

///|
async fn main {
  let entry = @core.NodeId::NodeId("opencode") catch {
    _ => abort("static OpenCode node ID must be valid")
  }
  let agent = @opencode.opencode_agent(
    @coding.CodingAgentId::CodingAgentId("opencode-cli") catch {
      _ => abort("static OpenCode agent ID must be valid")
    },
    @opencode.OpenCodeAgentOptions::OpenCodeAgentOptions(
      title="workgraph example",
    ),
  )
  let workspace = @path.Path(@env.current_dir().unwrap_or("."))
  let environment = @immut_hashmap.HashMap(@env.get_env_vars().to_array())
  let node = @coding.coding_agent_node(
    entry,
    @core.NodeMetadata::NodeMetadata(
      name="opencode",
      description=Some("Read-only OpenCode CLI example"),
      kind=@core.CodingAgent,
      tags=["example", "opencode"],
    ),
    @coding.CodingAgentNodeSpec::CodingAgentNodeSpec(
      agent~,
      resource_key=@core.ResourceKey::ResourceKey("opencode-session") catch {
        _ => abort("static OpenCode resource key must be valid")
      },
      resource_scope=@core.Run,
      open_context=fn(context, _state) {
        @coding.CodingAgentOpenContext::CodingAgentOpenContext(
          run_id=context.run_id,
          task_group=context.task_group,
          workspace=@coding.WorkspaceRef::WorkspaceRef(workspace, []),
          approval=@coding.Never,
          network=@coding.Disabled,
          environment~,
          events=context.events,
        )
      },
      build_request=fn(_context, state : OpenCodeExampleState) {
        @coding.CodingAgentRequest::CodingAgentRequest(state.instruction, [])
      },
      decode_response=fn(_state, response) {
        let summary = response.summary.unwrap_or("")
        @core.NodeOutput::NodeOutput(
          Some(OpenCodeExamplePatch::{ summary, }),
          Some(Json::string(summary)),
        )
      },
    ),
  )
  let definition = @core.GraphDefinition::GraphDefinition(
    @core.Reducer::Reducer(fn(
      state : OpenCodeExampleState,
      patch : OpenCodeExamplePatch,
    ) {
      OpenCodeExampleState::{
        instruction: state.instruction,
        summary: patch.summary,
      }
    }),
  )
  definition.add_node(node)
  definition.set_router(
    entry,
    @core.router([], fn(_state, _completion) { @core.End }),
  )
  definition.set_entry(entry)
  let result = @core.GraphRuntime::GraphRuntime(definition.compile()).invoke(OpenCodeExampleState::{
    instruction: "Reply with WORKGRAPH_OPENCODE_OK only. Do not modify files or use tools.",
    summary: "",
  })
  println(result.final_state.summary)
}
