///|
struct CodexExampleState {
  instruction : String
  summary : String
}

///|
struct CodexExamplePatch {
  summary : String
}

///|
async fn main {
  let entry = @core.NodeId::parse("codex") catch {
    _ => abort("static Codex node ID must be valid")
  }
  let agent = @codex.codex_agent(
    @core.CodingAgentId::parse("codex-cli") catch {
      _ => abort("static Codex agent ID must be valid")
    },
    @codex.CodexAgentOptions::CodexAgentOptions(
      sandbox=@codex_sdk.ReadOnly,
      skip_git=true,
      web_search=@codex_sdk.Disabled,
    ),
  )
  let workspace = @path.Path(@env.current_dir().unwrap_or("."))
  let environment = @immut_hashmap.HashMap(@env.get_env_vars().to_array())
  let node = @coding.coding_agent_node(
    entry,
    @core.NodeMetadata::NodeMetadata(
      name="codex",
      description=Some("Read-only Codex CLI example"),
      kind=@core.CodingAgent,
      tags=["example", "codex"],
    ),
    @coding.CodingAgentNodeSpec::CodingAgentNodeSpec(
      agent,
      @core.ResourceKey::parse("codex-session") catch {
        _ => abort("static Codex resource key must be valid")
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
      fn(_context, state : CodexExampleState) {
        @core.CodingAgentRequest::CodingAgentRequest(state.instruction, [])
      },
      fn(_state, response) {
        let summary = response.summary.unwrap_or("")
        @core.NodeOutput::NodeOutput(
          Some(CodexExamplePatch::{ summary, }),
          Some(Json::string(summary)),
          response.artifacts,
        )
      },
    ),
  )
  let definition = @core.GraphDefinition::GraphDefinition(
    @core.Reducer::Reducer(fn(
      state : CodexExampleState,
      patch : CodexExamplePatch,
    ) {
      CodexExampleState::{
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
  let result = @core.GraphRuntime::GraphRuntime(definition.compile()).invoke(CodexExampleState::{
    instruction: "Reply with WORKGRAPH_CODEX_OK only. Do not modify files or use tools.",
    summary: "",
  })
  println(result.final_state.summary)
}
