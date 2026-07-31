///|
pub(all) struct LlmNodeSpec[S, P] {
  build_request : (@core.NodeContext, S) -> @llm.ChatRequest raise
  invoke : async (@llm.ChatRequest) -> @llm.ChatResponse
  decode_response : (S, @llm.ChatResponse) -> @core.NodeOutput[P] raise
}

///|
/// Create a graph node that builds a chat request, invokes MoonLLM, and decodes its response.
pub fn[S, P] llm_node(
  id : @core.NodeId,
  metadata : @core.NodeMetadata,
  spec : LlmNodeSpec[S, P],
) -> @core.Node[S, P] {
  @core.function_node(id, metadata, async fn(context, state) {
    let request = (spec.build_request)(context, state)
    let response = (spec.invoke)(request)
    (spec.decode_response)(state, response)
  })
}
