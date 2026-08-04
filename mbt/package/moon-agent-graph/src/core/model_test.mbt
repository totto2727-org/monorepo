///|
suberror NodeTestError {
  CallbackFailed(String)
} derive(Debug)

///|
fn node_metadata() -> NodeMetadata {
  NodeMetadata::{
    name: "increment",
    description: None,
    kind: Function,
    tags: ["test"],
  }
}

///|
fn node_context(
  group : @async.TaskGroup[Unit],
  run_id : RunId,
  node_id : NodeId,
) -> NodeContext {
  NodeContext::NodeContext(
    run_id,
    node_id,
    3,
    group,
    events=EventSink::discard(),
    resources=ResourceStore::ResourceStore(),
    deadline_ms=500,
  )
}

///|
async test "function_node 1 - receives state and complete context" {
  @async.with_task_group() <| group => {
    let run_id = RunId::parse("run-1")
    let node_id = NodeId::parse("increment")
    let context = node_context(group, run_id, node_id)
    let mut task_group_was_usable = false
    let node = function_node(node_id, node_metadata(), async fn(
      callback_context,
      state,
    ) {
      inspect(callback_context.run_id.to_string(), content="run-1")
      inspect(callback_context.node_id.to_string(), content="increment")
      inspect(callback_context.step, content="3")
      debug_inspect(callback_context.deadline_ms, content="Some(500)")
      callback_context.events.try_emit(RunStarted(callback_context.run_id))
      let task = callback_context.task_group.spawn(() => {
        task_group_was_usable = true
      })
      task.wait()
      @async.pause()
      NodeOutput::{ patch: Some(state + 1), value: None, artifacts: [] }
    })
    let output = (node.execute)(context, 41)
    debug_inspect(output.patch, content="Some(42)")
    debug_inspect(output.value, content="None")
    inspect(output.artifacts.length(), content="0")
    inspect(task_group_was_usable, content="true")
  }
}

///|
test "Reducer apply 1 - returns the updated state" {
  let reducer = Reducer::{
    apply: fn(state : Int, patch : Int) { state + patch },
  }
  inspect((reducer.apply)(10, 5), content="15")
}

///|
async test "function_node 2 - propagates the callback suberror unchanged" {
  @async.with_task_group() <| group => {
    let run_id = RunId::parse("run-2")
    let node_id = NodeId::parse("failure")
    let node : Node[Int, Unit] = function_node(node_id, node_metadata(), async fn(
      _context,
      _state : Int,
    ) {
      @async.pause()
      raise CallbackFailed("detail")
    })
    let detail = try {
      (node.execute)(node_context(group, run_id, node_id), 0) |> ignore
      "no error"
    } catch {
      CallbackFailed(message) => "CallbackFailed:\{message}"
      _ => "wrong error"
    }
    inspect(detail, content="CallbackFailed:detail")
  }
}

///|
async test "function_node 3 - cancellation preserves the cancellation error" {
  @async.with_task_group() <| group => {
    let run_id = RunId::parse("run-3")
    let node_id = NodeId::parse("pause")
    let mut tokens = 0
    let node : Node[Int, Unit] = function_node(node_id, node_metadata(), async fn(
      _context,
      _state : Int,
    ) {
      tokens = tokens + 1
      @async.pause()
      tokens = tokens + 1
      NodeOutput::{ patch: None, value: None, artifacts: [] }
    })
    let task = group.spawn(
      async fn() {
        (node.execute)(node_context(group, run_id, node_id), 0) |> ignore
      },
      allow_failure=true,
    )
    @async.pause()
    inspect(tokens, content="1")
    task.cancel()
    let cancellation = try {
      task.wait() |> ignore
      false
    } catch {
      error => @async.is_cancellation_error(error)
    }
    inspect(cancellation, content="true")
    inspect(tokens, content="1")
  }
}

///|
suberror TestObserverError {
  TestObserverError
}

///|
test "EventSink emits synchronous events in declaration order W2-C003" {
  let run_id = RunId::parse("run-events")
  let labels : Array[String] = []
  let sink = EventSink::EventSink(fn(event) {
    match event {
      RunStarted(_) => labels.push("run.started")
      RunCancelled(_) => labels.push("run.cancelled")
      RunCompleted(_) => labels.push("run.completed")
      _ => labels.push("unexpected")
    }
  })
  sink.try_emit(GraphEvent::RunStarted(run_id))
  sink.try_emit(GraphEvent::RunCancelled(run_id))
  sink.try_emit(GraphEvent::RunCompleted(run_id~, steps=3))
  inspect(labels.join(","), content="run.started,run.cancelled,run.completed")
}

///|
test "EventSink safely ignores a raising observer W2-C003" {
  let attempts : Array[Int] = []
  let sink = EventSink::EventSink(fn(_) raise {
    attempts.push(1)
    raise TestObserverError
  })
  sink.try_emit(GraphEvent::RunStarted(RunId::parse("run-error")))
  inspect(attempts.length(), content="1")
}

///|
test "EventSink discard is a no-op W2-C003" {
  EventSink::discard().try_emit(
    GraphEvent::RunStarted(RunId::parse("run-discard")),
  )
  inspect(true, content="true")
}

///|
test "NodeOutput contains patch value and artifacts W2-C003" {
  let artifact = Artifact::{
    kind: Text,
    name: "result.txt",
    uri: Some("file:///result.txt"),
    metadata: None,
  }
  let output : NodeOutput[Int] = NodeOutput::{
    patch: Some(42),
    value: Some(Json::string("done")),
    artifacts: [artifact],
  }
  guard output.patch is Some(42) else { fail("missing patch") }
  guard output.value is Some(Json::String("done")) else {
    fail("missing value")
  }
  inspect(output.artifacts.length(), content="1")
  inspect(output.artifacts[0].name, content="result.txt")
}
