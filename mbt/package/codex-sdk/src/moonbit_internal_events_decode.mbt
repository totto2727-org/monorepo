// MoonBit-only implementation of the explicit event decoding required by the language type system.
// Corresponding upstream cast: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/thread.ts#L96-L109
// Event shapes being decoded: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/events.ts#L5-L84
// This file is intentionally prefixed moonbit_internal_ because no equivalent decoder module exists upstream.

fn moonbit_internal_usage_from_json(
  json : Json,
) -> Usage raise CodexSdkError {
  let object = moonbit_internal_json_object(json, "usage")
  {
    input_tokens: moonbit_internal_required_int(object, "input_tokens", "usage"),
    cached_input_tokens: moonbit_internal_required_int(
      object,
      "cached_input_tokens",
      "usage",
    ),
    cache_write_input_tokens: match object.get("cache_write_input_tokens") {
      Some(Json::Number(value, ..)) => value.to_int()
      None => 0
      Some(_) =>
        raise InvalidEvent(message="usage.cache_write_input_tokens must be a number")
    },
    output_tokens: moonbit_internal_required_int(
      object,
      "output_tokens",
      "usage",
    ),
    reasoning_output_tokens: moonbit_internal_required_int(
      object,
      "reasoning_output_tokens",
      "usage",
    ),
  }
}

fn moonbit_internal_thread_error_from_json(
  json : Json,
) -> ThreadError raise CodexSdkError {
  let object = moonbit_internal_json_object(json, "thread error")
  {
    message: moonbit_internal_required_string(
      object,
      "message",
      "thread error",
    ),
  }
}

fn moonbit_internal_thread_event_from_json(
  json : Json,
) -> ThreadEvent raise CodexSdkError {
  let object = moonbit_internal_json_object(json, "thread event")
  let event_type = moonbit_internal_required_string(
    object,
    "type",
    "thread event",
  )
  match event_type {
    "thread.started" =>
      ThreadStarted({
        thread_id: moonbit_internal_required_string(
          object,
          "thread_id",
          event_type,
        ),
      })
    "turn.started" => TurnStarted(TurnStartedEvent::{})
    "turn.completed" =>
      TurnCompleted({
        usage: moonbit_internal_usage_from_json(
          moonbit_internal_required_json(object, "usage", event_type),
        ),
      })
    "turn.failed" =>
      TurnFailed({
        error: moonbit_internal_thread_error_from_json(
          moonbit_internal_required_json(object, "error", event_type),
        ),
      })
    "item.started" =>
      ItemStarted({
        item: moonbit_internal_thread_item_from_json(
          moonbit_internal_required_json(object, "item", event_type),
        ),
      })
    "item.updated" =>
      ItemUpdated({
        item: moonbit_internal_thread_item_from_json(
          moonbit_internal_required_json(object, "item", event_type),
        ),
      })
    "item.completed" =>
      ItemCompleted({
        item: moonbit_internal_thread_item_from_json(
          moonbit_internal_required_json(object, "item", event_type),
        ),
      })
    "error" =>
      StreamError({
        message: moonbit_internal_required_string(object, "message", event_type),
      })
    _ => raise InvalidEvent(message="unsupported thread event type: \{event_type}")
  }
}
