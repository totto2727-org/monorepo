fn usage_from_json(json : Json) -> Usage raise CodexSdkError {
  let object = json_object(json, "usage")
  {
    input_tokens: required_int(object, "input_tokens", "usage"),
    cached_input_tokens: required_int(object, "cached_input_tokens", "usage"),
    cache_write_input_tokens: match object.get("cache_write_input_tokens") {
      Some(Json::Number(value, ..)) => value.to_int()
      None => 0
      Some(_) =>
        raise InvalidEvent(message="usage.cache_write_input_tokens must be a number")
    },
    output_tokens: required_int(object, "output_tokens", "usage"),
    reasoning_output_tokens: required_int(
      object,
      "reasoning_output_tokens",
      "usage",
    ),
  }
}

fn thread_error_from_json(json : Json) -> ThreadError raise CodexSdkError {
  let object = json_object(json, "thread error")
  { message: required_string(object, "message", "thread error") }
}

///| Decodes one top-level JSONL event emitted by `codex exec`.
pub fn ThreadEvent::from_json(json : Json) -> ThreadEvent raise CodexSdkError {
  let object = json_object(json, "thread event")
  let event_type = required_string(object, "type", "thread event")
  match event_type {
    "thread.started" =>
      ThreadStarted({
        thread_id: required_string(object, "thread_id", event_type),
      })
    "turn.started" => TurnStarted(TurnStartedEvent::{})
    "turn.completed" =>
      TurnCompleted({
        usage: usage_from_json(required_json(object, "usage", event_type)),
      })
    "turn.failed" =>
      TurnFailed({
        error: thread_error_from_json(required_json(object, "error", event_type)),
      })
    "item.started" =>
      ItemStarted({
        item: ThreadItem::from_json(required_json(object, "item", event_type)),
      })
    "item.updated" =>
      ItemUpdated({
        item: ThreadItem::from_json(required_json(object, "item", event_type)),
      })
    "item.completed" =>
      ItemCompleted({
        item: ThreadItem::from_json(required_json(object, "item", event_type)),
      })
    "error" =>
      StreamError({ message: required_string(object, "message", event_type) })
    _ => raise InvalidEvent(message="unsupported thread event type: \{event_type}")
  }
}
