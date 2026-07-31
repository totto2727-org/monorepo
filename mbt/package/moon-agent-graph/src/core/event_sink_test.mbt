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
