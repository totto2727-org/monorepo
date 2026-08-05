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
async test "llm_node integration 1 - maps a local chat completion into graph state and usage artifact" {
  let server = @http.Server(@socket.Addr::parse("127.0.0.1:0"))
  let requests : Array[String] = []
  let usage_artifacts : Array[String] = []
  @async.with_task_group() <| group => {
    group.add_defer(() => server.close())
    group.spawn_bg(no_wait=true) <| () => {
      server.run_forever(max_connections=1) <| ((request, body, connection) => {
        let http_method = match request.meth {
          Post => "POST"
          _ => "unexpected"
        }
        requests.push(
          "\{http_method} \{request.path}\n\{body.read_all().text()}",
        )
        connection.send_response(200, "OK", extra_headers={
          "Content-Type": "application/json",
        })
        connection.write(
          (
            #|{"id":"chatcmpl-local","object":"chat.completion","created":1,"model":"local-test-model","choices":[{"index":0,"message":{"role":"assistant","content":"completed"},"finish_reason":"stop"}],"usage":{"prompt_tokens":4,"completion_tokens":2,"total_tokens":6}}
          ),
        )
        connection.end_response()
      })
    }
    let client = @llm.Client::new(
      "local-test-key",
      base_url="http://127.0.0.1:\{server.addr.port()}/v1",
      timeout_ms=1000,
    )
    let entry = @core.NodeId::parse("local-llm")
    let node = @moonllm_node.llm_node(
      entry,
      @core.NodeMetadata::NodeMetadata(
        "local-llm",
        Some("Deterministic local MoonLLM integration"),
        @core.Llm,
        ["integration"],
      ),
      @moonllm_node.LlmNodeSpec::LlmNodeSpec(
        fn(_context, state : LocalLlmState) {
          @llm.ChatRequest::new("local-test-model", [
            @llm.Message::system("Return the deterministic result."),
            @llm.Message::user(state.prompt),
          ])
          .temperature(0.0)
          .max_tokens(8)
        },
        async fn(request) { client.chat(request) },
        fn(_state, response) {
          let total_tokens = response.total_tokens()
          @core.NodeOutput::NodeOutput(
            Some(LocalLlmPatch::{ answer: response.text(), total_tokens }),
            Some(Json::string(response.text())),
            [
              @core.Artifact::Artifact(
                @core.Json,
                "moonllm-usage",
                None,
                response.usage.map(fn(usage) { usage.to_json() }),
              ),
            ],
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
        guard completion.artifacts[0].metadata is Some(metadata) else {
          fail("missing usage metadata")
        }
        usage_artifacts.push(metadata.stringify())
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
    let request = requests[0]
    assert_true(request.has_prefix("POST /v1/chat/completions\n"))
    assert_true(request.contains("\"model\":\"local-test-model\""))
    assert_true(request.contains("\"role\":\"system\""))
    assert_true(request.contains("\"content\":\"local prompt\""))
    assert_true(request.contains("\"temperature\":0"))
    assert_true(request.contains("\"max_tokens\":8"))
    assert_true(request.contains("\"stream\":false"))
    inspect(
      usage_artifacts.join(","),
      content="{\"prompt_tokens\":4,\"completion_tokens\":2,\"total_tokens\":6}",
    )
  }
}
