///|
suberror LlmNodeTestError {
  RequestBuildFailed
  ResponseDecodeFailed
} derive(Debug)

///|
struct LlmNodeTestProvider {
  events : Array[@llm.StreamEvent]
  requests : Array[String]
  tool_counts : Array[Int]
  mut calls : Int
}

///|
fn LlmNodeTestProvider::LlmNodeTestProvider(
  events : Array[@llm.StreamEvent],
) -> LlmNodeTestProvider {
  { events, requests: [], tool_counts: [], calls: 0 }
}

///|
impl @llm.Provider for LlmNodeTestProvider with fn stream(
  self,
  messages,
  tools,
  handler,
) {
  self.calls = self.calls + 1
  let message_texts : Array[String] = []
  for message in messages {
    message_texts.push(message.get_text())
  }
  self.requests.push(message_texts.join("|"))
  self.tool_counts.push(tools.length())
  for event in self.events {
    (handler.on_event)(event)
  }
}

///|
impl @llm.Provider for LlmNodeTestProvider with fn name(_self) {
  "workgraph-llm-test"
}

///|
fn llm_node_metadata() -> @core.NodeMetadata {
  @core.NodeMetadata::NodeMetadata(
    name="plan",
    description=None,
    kind=@core.Llm,
    tags=["llm-node-test"],
  )
}

///|
fn llm_node_test_provider(text : String) -> LlmNodeTestProvider {
  LlmNodeTestProvider::LlmNodeTestProvider([
    @llm.TextDelta(text),
    @llm.MessageEnd(
      finish_reason=@llm.Stop,
      usage=Some(@llm.Usage::{ input_tokens: 3, output_tokens: 2 }),
    ),
  ])
}

///|
fn test_context(
  group : @async.TaskGroup[Unit],
  node_id : @core.NodeId,
) -> @core.NodeContext {
  @core.NodeContext::NodeContext(
    @core.RunId::RunId("llm-run") catch {
      _ => abort("test run ID must be valid")
    },
    node_id,
    1,
    group,
  )
}

///|
async test "llm_node 1 - builds a typed request and decodes its response" {
  @async.with_task_group() <| group => {
    let node_id = @core.NodeId::NodeId("plan")
    let provider = llm_node_test_provider("apply-2")
    let node : @core.Node[Int, Int] = llm_node(
      node_id,
      llm_node_metadata(),
      LlmNodeSpec::LlmNodeSpec(
        @llm.BoxedProvider::new(provider),
        fn(_context, state : Int) {
          LlmRequest::LlmRequest([@llm.Message::user("state=\{state}")])
        },
        fn(_state, response) {
          @core.NodeOutput::NodeOutput(
            Some(2),
            Some(Json::string(response.text)),
          )
        },
      ),
    )
    let output = (node.execute)(test_context(group, node_id), 7)
    inspect(provider.requests.join(","), content="state=7")
    debug_inspect(output.patch, content="Some(2)")
    match output.value {
      Some(value) => json_inspect(value, content="apply-2")
      None => abort("decoded response must include a value")
    }
  }
}

///|
async test "llm_node 2 - applies a decoded patch through GraphRuntime" {
  let node_id = @core.NodeId::NodeId("plan")
  let provider = llm_node_test_provider("increment")
  let definition = @core.GraphDefinition::GraphDefinition(
    @core.Reducer::Reducer(fn(state : Int, patch : Int) { state + patch }),
  )
  definition.add_node(
    llm_node(
      node_id,
      llm_node_metadata(),
      LlmNodeSpec::LlmNodeSpec(
        @llm.BoxedProvider::new(provider),
        fn(_context, state : Int) {
          LlmRequest::LlmRequest([@llm.Message::user("state=\{state}")])
        },
        fn(_state, _response) { @core.NodeOutput::NodeOutput(Some(3), None) },
      ),
    ),
  )
  definition.set_router(
    node_id,
    @core.router([], fn(_state, _completion) { @core.End }),
  )
  definition.set_entry(node_id)
  let result = @core.GraphRuntime::GraphRuntime(definition.compile()).invoke(4)
  inspect(provider.calls, content="1")
  inspect(result.final_state, content="7")
  inspect(result.steps, content="1")
}

///|
async test "llm_node 3 - stops before invocation when request building fails" {
  @async.with_task_group() <| group => {
    let node_id = @core.NodeId::NodeId("build-failure")
    let provider = llm_node_test_provider("unreachable")
    let mut decodes = 0
    let node : @core.Node[Int, Int] = llm_node(
      node_id,
      llm_node_metadata(),
      LlmNodeSpec::LlmNodeSpec(
        @llm.BoxedProvider::new(provider),
        fn(_context, _state : Int) raise { raise RequestBuildFailed },
        fn(_state, _response) {
          decodes = decodes + 1
          @core.NodeOutput::NodeOutput(None, None)
        },
      ),
    )
    let observed = try {
      (node.execute)(test_context(group, node_id), 0) |> ignore
      "no error"
    } catch {
      RequestBuildFailed => "RequestBuildFailed"
      _ => "wrong error"
    }
    inspect(observed, content="RequestBuildFailed")
    inspect(provider.calls, content="0")
    inspect(decodes, content="0")
  }
}

///|
async test "llm_node 4 - preserves provider errors without decoding" {
  @async.with_task_group() <| group => {
    let node_id = @core.NodeId::NodeId("provider-failure")
    let provider = LlmNodeTestProvider::LlmNodeTestProvider([
      @llm.Error("offline"),
    ])
    let mut decodes = 0
    let node : @core.Node[Int, Int] = llm_node(
      node_id,
      llm_node_metadata(),
      LlmNodeSpec::LlmNodeSpec(
        @llm.BoxedProvider::new(provider),
        fn(_context, _state : Int) {
          LlmRequest::LlmRequest([@llm.Message::user("go")])
        },
        fn(_state, _response) {
          decodes = decodes + 1
          @core.NodeOutput::NodeOutput(None, None)
        },
      ),
    )
    let observed = try {
      (node.execute)(test_context(group, node_id), 0) |> ignore
      "no error"
    } catch {
      LlmNodeError::ProviderFailed(message) => "ProviderFailed:\{message}"
      _ => "wrong error"
    }
    inspect(observed, content="ProviderFailed:offline")
    inspect(provider.calls, content="1")
    inspect(decodes, content="0")
  }
}

///|
async test "llm_node 5 - decoder failure leaves runtime state unchanged" {
  let node_id = @core.NodeId::NodeId("decode-failure")
  let provider = llm_node_test_provider("invalid")
  let mut reductions = 0
  let definition = @core.GraphDefinition::GraphDefinition(
    @core.Reducer::Reducer(fn(state : Int, patch : Int) {
      reductions = reductions + 1
      state + patch
    }),
  )
  definition.add_node(
    llm_node(
      node_id,
      llm_node_metadata(),
      LlmNodeSpec::LlmNodeSpec(
        @llm.BoxedProvider::new(provider),
        fn(_context, _state : Int) {
          LlmRequest::LlmRequest([@llm.Message::user("go")])
        },
        fn(_state, _response) raise { raise ResponseDecodeFailed },
      ),
    ),
  )
  definition.set_router(
    node_id,
    @core.router([], fn(_state, _completion) { @core.End }),
  )
  definition.set_entry(node_id)
  let observed = try {
    @core.GraphRuntime::GraphRuntime(definition.compile()).invoke(10) |> ignore
    "no error"
  } catch {
    @core.NodeFailed(cause=ResponseDecodeFailed, ..) =>
      "NodeFailed:ResponseDecodeFailed"
    _ => "wrong error"
  }
  inspect(observed, content="NodeFailed:ResponseDecodeFailed")
  inspect(reductions, content="0")
}

///|
async test "llm_node 6 - collects tools, finish reason, and missing usage" {
  @async.with_task_group() <| group => {
    let node_id = @core.NodeId::NodeId("tool-result")
    let provider = LlmNodeTestProvider::LlmNodeTestProvider([
      @llm.TextDelta("tool response"),
      @llm.ToolCallEnd(
        id="call-1",
        name="lookup",
        input=Json::string("payload"),
      ),
      @llm.MessageEnd(finish_reason=@llm.ToolUse, usage=None),
    ])
    let node : @core.Node[Int, Int] = llm_node(
      node_id,
      llm_node_metadata(),
      LlmNodeSpec::LlmNodeSpec(
        @llm.BoxedProvider::new(provider),
        fn(_context, _state : Int) {
          LlmRequest::LlmRequest([@llm.Message::user("use a tool")], tools=[
            @llm.ToolDef::{
              name: "lookup",
              description: "Look up a value",
              input_schema: Json::empty_object(),
            },
          ])
        },
        fn(_state, response) raise {
          inspect(response.text, content="tool response")
          inspect(response.tool_calls.length(), content="1")
          inspect(response.tool_calls[0].id, content="call-1")
          inspect(response.tool_calls[0].name, content="lookup")
          json_inspect(response.tool_calls[0].input, content="payload")
          inspect(
            match response.finish_reason {
              @llm.ToolUse => "ToolUse"
              _ => "wrong finish reason"
            },
            content="ToolUse",
          )
          inspect(response.usage is None, content="true")
          @core.NodeOutput::NodeOutput(None, None)
        },
      ),
    )
    (node.execute)(test_context(group, node_id), 0) |> ignore
    inspect(provider.calls, content="1")
    inspect(provider.requests.join(","), content="use a tool")
    inspect(provider.tool_counts[0], content="1")
  }
}
