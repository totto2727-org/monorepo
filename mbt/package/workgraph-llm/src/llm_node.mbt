///|
/// A provider-neutral request built from mizchi/llm message and tool types.
pub(all) struct LlmRequest {
  messages : Array[@llm.Message]
  tools : Array[@llm.ToolDef]
}

///|
/// Creates one LLM invocation request.
pub fn LlmRequest::LlmRequest(
  messages : Array[@llm.Message],
  tools? : Array[@llm.ToolDef] = [],
) -> LlmRequest {
  LlmRequest::{ messages, tools }
}

///|
pub struct LlmNodeSpec[S, P] {
  build_request : (@core.NodeContext, S) -> LlmRequest raise
  invoke : async (LlmRequest) -> @llm.CollectResult
  decode_response : (S, @llm.CollectResult) -> @core.NodeOutput[P] raise
}

///|
/// Creates the callbacks used by an LLM graph node.
pub fn[S, P] LlmNodeSpec::LlmNodeSpec(
  build_request : (@core.NodeContext, S) -> LlmRequest raise,
  invoke : async (LlmRequest) -> @llm.CollectResult,
  decode_response : (S, @llm.CollectResult) -> @core.NodeOutput[P] raise,
) -> LlmNodeSpec[S, P] {
  LlmNodeSpec::{ build_request, invoke, decode_response }
}

///|
/// Create a graph node that builds an LLM request, invokes a provider callback,
/// and decodes its result.
pub fn[S, P] llm_node(
  id : @core.NodeId,
  metadata : @core.NodeMetadata,
  spec : LlmNodeSpec[S, P],
) -> @core.Node[S, P] {
  @core.Node::Node(id, metadata, async fn(context, state) {
    let request = (spec.build_request)(context, state)
    let response = (spec.invoke)(request)
    (spec.decode_response)(state, response)
  })
}
