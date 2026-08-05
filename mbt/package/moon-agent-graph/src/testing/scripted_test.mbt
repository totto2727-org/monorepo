///|
fn testing_metadata() -> @core.NodeMetadata {
  @core.NodeMetadata::NodeMetadata(
    name="scripted",
    description=None,
    kind=@core.Function,
    tags=[],
  )
}

///|
async test "scripted_node records exact state and context order" {
  @async.with_task_group() <| group => {
    let node_id = @core.NodeId::parse("scripted")
    let run_id = @core.RunId::parse("run-scripted")
    let fixture = scripted_node(node_id, testing_metadata(), async fn(
      context,
      state : Int,
    ) {
      @async.pause()
      @core.NodeOutput::NodeOutput(Some(state + context.step), None, [])
    })
    let node = fixture.node()
    let first = (node.execute)(
      @core.NodeContext::NodeContext(run_id, node_id, 1, group),
      10,
    )
    let second = (node.execute)(
      @core.NodeContext::NodeContext(run_id, node_id, 2, group),
      20,
    )
    debug_inspect(first.patch, content="Some(11)")
    debug_inspect(second.patch, content="Some(22)")
    let calls = fixture.calls()
    inspect(calls.length(), content="2")
    debug_inspect(
      [
        calls[0].state,
        calls[0].context.step,
        calls[1].state,
        calls[1].context.step,
      ],
      content="[10, 1, 20, 2]",
    )
    inspect(calls[0].context.run_id.to_string(), content="run-scripted")
    inspect(calls[1].context.node_id.to_string(), content="scripted")
  }
}

///|
test "scripted_router records exact state and completion order" {
  let node_id = @core.NodeId::parse("router-source")
  let completion = @core.NodeCompletion::NodeCompletion(node_id, None, [])
  let fixture = scripted_router([], fn(state : Int, _completion) {
    if state == 1 {
      @core.End
    } else {
      @core.Fail("stop")
    }
  })
  let router = fixture.router()
  (router.evaluate)(1, completion) |> ignore
  (router.evaluate)(2, completion) |> ignore
  let calls = fixture.calls()
  debug_inspect([calls[0].state, calls[1].state], content="[1, 2]")
  inspect(calls[0].completion.node_id.to_string(), content="router-source")
}

///|
test "recording_reducer records exact state and patch order" {
  let fixture = recording_reducer(fn(state : Int, patch : Int) { state + patch })
  let reducer = fixture.reducer()
  inspect((reducer.apply)(1, 2), content="3")
  inspect((reducer.apply)(3, 4), content="7")
  let calls = fixture.calls()
  debug_inspect(
    [calls[0].state, calls[0].patch, calls[1].state, calls[1].patch],
    content="[1, 2, 3, 4]",
  )
}

///|
test "recording_event_sink records exact event order" {
  let fixture = recording_event_sink()
  let sink = fixture.event_sink()
  let run_id = @core.RunId::parse("run-events")
  (sink.emit)(@core.run_started_event(run_id))
  (sink.emit)(@core.run_completed_event(run_id, 2))
  let events = fixture.events()
  inspect(events.length(), content="2")
  match events[0] {
    @core.RunStarted(recorded) =>
      inspect(recorded.to_string(), content="run-events")
    _ => fail("expected RunStarted")
  }
  match events[1] {
    @core.RunCompleted(run_id=recorded, steps~) => {
      inspect(recorded.to_string(), content="run-events")
      inspect(steps, content="2")
    }
    _ => fail("expected RunCompleted")
  }
}
