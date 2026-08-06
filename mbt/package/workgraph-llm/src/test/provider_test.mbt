///|
struct LocalLlmState {
  prompt : String
  answer : String
  total_tokens : Int
} derive(Debug)

///|
struct LocalLlmPatch {
  answer : String
  total_tokens : Int
} derive(Debug)

///|
suberror LocalLlmError {
  ProviderFailed(String)
} derive(Debug)

///|
fn collect_provider(
  provider : @llm.BoxedProvider,
  request : @workgraph_llm.LlmRequest,
) -> @llm.CollectResult raise {
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
async test "llm_node integration 1 - maps a mizchi/llm provider result into graph state" {
  let requests : Array[@workgraph_llm.LlmRequest] = []
  let completion_values : Array[String] = []
  let provider = @llm.MockProvider::new([
    [
      @llm.MessageStart,
      @llm.TextDelta("completed"),
      @llm.MessageEnd(
        finish_reason=@llm.Stop,
        usage=Some(@llm.Usage::{ input_tokens: 4, output_tokens: 2 }),
      ),
    ],
  ]).boxed()
  let entry = @core.NodeId::parse("local-llm")
  let node = @workgraph_llm.llm_node(
    entry,
    @core.NodeMetadata::NodeMetadata(
      name="local-llm",
      description=Some("Deterministic mizchi/llm integration"),
      kind=@core.Llm,
      tags=["integration"],
    ),
    @workgraph_llm.LlmNodeSpec::LlmNodeSpec(
      fn(_context, state : LocalLlmState) {
        @workgraph_llm.LlmRequest::LlmRequest([
          @llm.Message::system("Return the deterministic result."),
          @llm.Message::user(state.prompt),
        ])
      },
      async fn(request) {
        requests.push(request)
        @async.pause()
        collect_provider(provider, request)
      },
      fn(_state, response) {
        let total_tokens = match response.usage {
          Some(usage) => usage.input_tokens + usage.output_tokens
          None => 0
        }
        @core.NodeOutput::NodeOutput(
          Some(LocalLlmPatch::{ answer: response.text, total_tokens }),
          Some(Json::string(response.text)),
        )
      },
    ),
  )
  let definition = @core.GraphDefinition::GraphDefinition(
    @core.Reducer::Reducer(fn(state : LocalLlmState, patch : LocalLlmPatch) {
      LocalLlmState::{
        prompt: state.prompt,
        answer: patch.answer,
        total_tokens: patch.total_tokens,
      }
    }),
  )
  definition.add_node(node)
  definition.set_router(
    entry,
    @core.router([], fn(_state, completion) raise {
      guard completion.value is Some(Json::String(value)) else {
        fail("missing completion value")
      }
      completion_values.push(value)
      @core.End
    }),
  )
  definition.set_entry(entry)
  let result = @core.GraphRuntime::GraphRuntime(definition.compile()).invoke(
    LocalLlmState::{ prompt: "local prompt", answer: "", total_tokens: 0 },
    options=@core.RunOptions::RunOptions(
      max_steps=1,
      node_timeout_ms=1500,
      cleanup_timeout_ms=500,
    ),
  )
  inspect(result.final_state.prompt, content="local prompt")
  inspect(result.final_state.answer, content="completed")
  inspect(result.final_state.total_tokens, content="6")
  inspect(result.steps, content="1")
  inspect(requests.length(), content="1")
  inspect(requests[0].messages.length(), content="2")
  inspect(
    requests[0].messages[0].get_text(),
    content="Return the deterministic result.",
  )
  inspect(requests[0].messages[1].get_text(), content="local prompt")
  inspect(requests[0].tools.length(), content="0")
  inspect(completion_values.join(","), content="completed")
}
