///|
suberror LlmNodeTestError {
  RequestBuildFailed
  InvocationFailed(String)
  ResponseDecodeFailed
} derive(Debug)

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
fn fake_response(text : String) -> @llm.CollectResult {
  @llm.CollectResult::{
    text,
    tool_calls: [],
    finish_reason: @llm.Stop,
    usage: Some(@llm.Usage::{ input_tokens: 3, output_tokens: 2 }),
  }
}

///|
fn test_context(
  group : @async.TaskGroup[Unit],
  node_id : @core.NodeId,
) -> @core.NodeContext {
  @core.NodeContext::NodeContext(
    @core.RunId::parse("llm-run") catch {
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
    let node_id = @core.NodeId::parse("plan")
    let requests : Array[String] = []
    let node : @core.Node[Int, Int] = llm_node(
      node_id,
      llm_node_metadata(),
      LlmNodeSpec::LlmNodeSpec(
        fn(_context, state : Int) {
          LlmRequest::LlmRequest([@llm.Message::user("state=\{state}")])
        },
        async fn(request) {
          requests.push(request.messages[0].get_text())
          @async.pause()
          fake_response("apply-2")
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
    inspect(requests.join(","), content="state=7")
    debug_inspect(output.patch, content="Some(2)")
    match output.value {
      Some(value) => json_inspect(value, content="apply-2")
      None => abort("decoded response must include a value")
    }
  }
}

///|
async test "llm_node 2 - applies a decoded patch through GraphRuntime" {
  let node_id = @core.NodeId::parse("plan")
  let mut invokes = 0
  let definition = @core.GraphDefinition::GraphDefinition(
    @core.Reducer::Reducer(fn(state : Int, patch : Int) { state + patch }),
  )
  definition.add_node(
    llm_node(
      node_id,
      llm_node_metadata(),
      LlmNodeSpec::LlmNodeSpec(
        fn(_context, state : Int) {
          LlmRequest::LlmRequest([@llm.Message::user("state=\{state}")])
        },
        async fn(_request) {
          invokes = invokes + 1
          @async.pause()
          fake_response("increment")
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
  inspect(invokes, content="1")
  inspect(result.final_state, content="7")
  inspect(result.steps, content="1")
}

///|
async test "llm_node 3 - stops before invocation when request building fails" {
  @async.with_task_group() <| group => {
    let node_id = @core.NodeId::parse("build-failure")
    let mut invokes = 0
    let mut decodes = 0
    let node : @core.Node[Int, Int] = llm_node(
      node_id,
      llm_node_metadata(),
      LlmNodeSpec::LlmNodeSpec(
        fn(_context, _state : Int) raise { raise RequestBuildFailed },
        async fn(_request) {
          invokes = invokes + 1
          @async.pause()
          fake_response("unreachable")
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
      RequestBuildFailed => "RequestBuildFailed"
      _ => "wrong error"
    }
    inspect(observed, content="RequestBuildFailed")
    inspect(invokes, content="0")
    inspect(decodes, content="0")
  }
}

///|
async test "llm_node 4 - preserves invocation errors without decoding" {
  @async.with_task_group() <| group => {
    let node_id = @core.NodeId::parse("invoke-failure")
    let mut decodes = 0
    let node : @core.Node[Int, Int] = llm_node(
      node_id,
      llm_node_metadata(),
      LlmNodeSpec::LlmNodeSpec(
        fn(_context, _state : Int) {
          LlmRequest::LlmRequest([@llm.Message::user("go")])
        },
        async fn(_request) {
          @async.pause()
          raise InvocationFailed("offline")
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
      InvocationFailed(message) => "InvocationFailed:\{message}"
      _ => "wrong error"
    }
    inspect(observed, content="InvocationFailed:offline")
    inspect(decodes, content="0")
  }
}

///|
async test "llm_node 5 - decoder failure leaves runtime state unchanged" {
  let node_id = @core.NodeId::parse("decode-failure")
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
        fn(_context, _state : Int) {
          LlmRequest::LlmRequest([@llm.Message::user("go")])
        },
        async fn(_request) {
          @async.pause()
          fake_response("invalid")
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
async test "llm_node 6 - cancellation stops the in-flight invoke callback" {
  @async.with_task_group() <| group => {
    let node_id = @core.NodeId::parse("cancel")
    let mut started = false
    let mut completed = false
    let node : @core.Node[Int, Int] = llm_node(
      node_id,
      llm_node_metadata(),
      LlmNodeSpec::LlmNodeSpec(
        fn(_context, _state : Int) {
          LlmRequest::LlmRequest([@llm.Message::user("go")])
        },
        async fn(_request) {
          started = true
          @async.pause()
          completed = true
          fake_response("unreachable")
        },
        fn(_state, _response) { @core.NodeOutput::NodeOutput(None, None) },
      ),
    )
    let task = group.spawn(
      async fn() { (node.execute)(test_context(group, node_id), 0) |> ignore },
      allow_failure=true,
    )
    @async.pause()
    inspect(started, content="true")
    task.cancel()
    let cancelled = try {
      task.wait() |> ignore
      false
    } catch {
      error => @async.is_cancellation_error(error)
    }
    inspect(cancelled, content="true")
    inspect(completed, content="false")
  }
}
