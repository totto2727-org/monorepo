///|
struct LlmExampleState {
  prompt : String
  answer : String
  total_tokens : Int
}

///|
struct LlmExamplePatch {
  answer : String
  total_tokens : Int
}

///|
fn collect_result(
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
    Some(message) => fail(message)
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
async fn main {
  let provider = @llm.MockProvider::new([
    [
      @llm.MessageStart,
      @llm.TextDelta("WORKGRAPH_LLM_OK"),
      @llm.MessageEnd(
        finish_reason=@llm.Stop,
        usage=Some(@llm.Usage::{ input_tokens: 4, output_tokens: 2 }),
      ),
    ],
  ]).boxed()
  let entry = @core.NodeId::parse("llm") catch {
    _ => abort("static LLM node ID must be valid")
  }
  let node = @workgraph_llm.llm_node(
    entry,
    @core.NodeMetadata::NodeMetadata(
      name="llm",
      description=Some("Deterministic mizchi/llm example"),
      kind=@core.Llm,
      tags=["example"],
    ),
    @workgraph_llm.LlmNodeSpec::LlmNodeSpec(
      fn(_context, state : LlmExampleState) {
        @workgraph_llm.LlmRequest::LlmRequest([
          @llm.Message::system("Return the configured response."),
          @llm.Message::user(state.prompt),
        ])
      },
      async fn(request) {
        @async.pause()
        collect_result(provider, request)
      },
      fn(_state, response) {
        let total_tokens = match response.usage {
          Some(usage) => usage.input_tokens + usage.output_tokens
          None => 0
        }
        @core.NodeOutput::NodeOutput(
          Some(LlmExamplePatch::{ answer: response.text, total_tokens }),
          None,
        )
      },
    ),
  )
  let definition = @core.GraphDefinition::GraphDefinition(
    @core.Reducer::Reducer(fn(
      state : LlmExampleState,
      patch : LlmExamplePatch,
    ) {
      LlmExampleState::{
        prompt: state.prompt,
        answer: patch.answer,
        total_tokens: patch.total_tokens,
      }
    }),
  )
  definition.add_node(node)
  definition.set_router(
    entry,
    @core.router([], fn(_state, _completion) { @core.End }),
  )
  definition.set_entry(entry)
  let result = @core.GraphRuntime::GraphRuntime(definition.compile()).invoke(LlmExampleState::{
    prompt: "Run the example",
    answer: "",
    total_tokens: 0,
  })
  println("answer=\{result.final_state.answer}")
  println("tokens=\{result.final_state.total_tokens}")
  println("steps=\{result.steps}")
}
