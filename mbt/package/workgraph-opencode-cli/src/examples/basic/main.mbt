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
  let entry = @core.NodeId::parse("opencode") catch {
    _ => abort("static OpenCode node ID must be valid")
  }
  let agent = @opencode.opencode_agent(
    @core.CodingAgentId::parse("opencode-cli") catch {
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
      agent,
      @core.ResourceKey::parse("opencode-session") catch {
        _ => abort("static OpenCode resource key must be valid")
      },
      @core.Run,
      fn(context, _state) {
        @core.CodingAgentOpenContext::CodingAgentOpenContext(
          run_id=context.run_id,
          task_group=context.task_group,
          workspace=@core.WorkspaceRef::WorkspaceRef(workspace, []),
          approval=@core.Never,
          network=@core.Disabled,
          environment~,
          events=context.events,
        )
      },
      fn(_context, state : OpenCodeExampleState) {
        @core.CodingAgentRequest::CodingAgentRequest(state.instruction, [])
      },
      fn(_state, response) {
        let summary = response.summary.unwrap_or("")
        @core.NodeOutput::NodeOutput(
          Some(OpenCodeExamplePatch::{ summary, }),
          Some(Json::string(summary)),
          response.artifacts,
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
