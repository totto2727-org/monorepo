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
async test "llm_node integration 1 - maps a mizchi/llm provider result into graph state" {
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
  let entry = @core.NodeId::NodeId("local-llm")
  let node = @workgraph_llm.llm_node(
    entry,
    @core.NodeMetadata::NodeMetadata(
      name="local-llm",
      description=Some("Deterministic mizchi/llm integration"),
      kind=@core.Llm,
      tags=["integration"],
    ),
    @workgraph_llm.LlmNodeSpec::LlmNodeSpec(
      provider,
      fn(_context, state : LocalLlmState) {
        @workgraph_llm.LlmRequest::LlmRequest([
          @llm.Message::system("Return the deterministic result."),
          @llm.Message::user(state.prompt),
        ])
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
  inspect(completion_values.join(","), content="completed")
}
