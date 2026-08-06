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
  provider : @llm.BoxedProvider
  build_request : (@core.NodeContext, S) -> LlmRequest raise
  decode_response : (S, @llm.CollectResult) -> @core.NodeOutput[P] raise
}

///|
/// Raised when an LLM provider reports a stream failure.
pub suberror LlmNodeError {
  ProviderFailed(String)
} derive(Debug)

///|
fn collect_response(
  provider : @llm.BoxedProvider,
  request : LlmRequest,
) -> @llm.CollectResult raise LlmNodeError {
  let text = StringBuilder::new()
  let tool_calls : Array[@llm.ToolCall] = []
  let finish_reason : Ref[@llm.FinishReason] = Ref(@llm.Stop)
  let usage : Ref[@llm.Usage?] = Ref(None)
  let failure : Ref[String?] = Ref(None)
  provider.stream(request.messages, request.tools, @llm.StreamHandler::{
    on_event: event => {
      match event {
        @llm.TextDelta(value) => text.write_string(value)
        @llm.ToolCallEnd(id~, name~, input~) =>
          tool_calls.push(@llm.ToolCall::{ id, name, input })
        @llm.MessageEnd(finish_reason=reason, usage=reported_usage) => {
          finish_reason.val = reason
          usage.val = reported_usage
        }
        @llm.Error(message) => failure.val = Some(message)
        _ => ()
      }
    },
  })
  match failure.val {
    Some(message) => raise ProviderFailed(message)
    None =>
      @llm.CollectResult::{
        text: text.to_string(),
        tool_calls,
        finish_reason: finish_reason.val,
        usage: usage.val,
      }
  }
}

///|
/// Creates a provider-backed LLM graph-node specification.
pub fn[S, P] LlmNodeSpec::LlmNodeSpec(
  provider : @llm.BoxedProvider,
  build_request : (@core.NodeContext, S) -> LlmRequest raise,
  decode_response : (S, @llm.CollectResult) -> @core.NodeOutput[P] raise,
) -> LlmNodeSpec[S, P] {
  LlmNodeSpec::{ provider, build_request, decode_response }
}

///|
/// Creates a graph node that builds a request, invokes its provider, and
/// decodes the collected response.
pub fn[S, P] llm_node(
  id : @core.NodeId,
  metadata : @core.NodeMetadata,
  spec : LlmNodeSpec[S, P],
) -> @core.Node[S, P] {
  @core.Node::Node(id, metadata, fn(context, state) raise {
    let request = (spec.build_request)(context, state)
    let response = collect_response(spec.provider, request)
    (spec.decode_response)(state, response)
  })
}
