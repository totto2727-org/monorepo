///|
pub(all) struct CodingAgentNodeSpec[S, P] {
  agent : @core.CodingAgent
  resource_key : @core.ResourceKey
  resource_scope : @core.ResourceScope
  open_context : (@core.NodeContext, S) -> @core.CodingAgentOpenContext raise
  build_request : (@core.NodeContext, S) -> @core.CodingAgentRequest raise
  decode_response : (S, @core.CodingAgentResponse) -> @core.NodeOutput[P] raise
}

///|
/// Create a graph node that acquires a coding-agent session, executes a request, and decodes its response.
pub fn[S, P] coding_agent_node(
  id : @core.NodeId,
  metadata : @core.NodeMetadata,
  spec : CodingAgentNodeSpec[S, P],
) -> @core.Node[S, P] {
  @core.function_node(id, metadata, async fn(context, state) {
    let open_context = (spec.open_context)(context, state)
    let session = match spec.resource_scope {
      @core.Node =>
        context.resources.acquire_agent_session(
          spec.resource_key,
          @core.Node,
          async fn() { (spec.agent.open)(open_context) },
          owner=context.node_id,
        )
      @core.Run =>
        context.resources.acquire_agent_session(spec.resource_key, @core.Run, async fn() {
          (spec.agent.open)(open_context)
        })
    }
    let request = (spec.build_request)(context, state)
    let response = session.execute(request)
    (spec.decode_response)(state, response)
  })
}
