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
    resources=RuntimeResourceStore::RuntimeResourceStore(),
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
