// MoonBit-only FromJson implementations required because TypeScript casts parsed JSON to ThreadEvent.
// Corresponding upstream cast: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/thread.ts#L96-L109
// Event shapes being decoded: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/events.ts#L5-L84
// This file is intentionally prefixed moonbit_internal_ because no equivalent decoder module exists upstream.

///|
pub impl @json.FromJson for ThreadStartedEvent with fn from_json(json, path) {
  let object = moonbit_internal_json_object(json, path, "thread.started")
  {
    thread_id: moonbit_internal_required_string(
      object, "thread_id", path, "thread.started",
    ),
  }
}

///|
pub impl @json.FromJson for TurnStartedEvent with fn from_json(json, path) {
  moonbit_internal_json_object(json, path, "turn.started") |> ignore
  TurnStartedEvent::{  }
}

///|
pub impl @json.FromJson for Usage with fn from_json(json, path) {
  let object = moonbit_internal_json_object(json, path, "usage")
  {
    input_tokens: moonbit_internal_required_int(
      object, "input_tokens", path, "usage",
    ),
    cached_input_tokens: moonbit_internal_required_int(
      object, "cached_input_tokens", path, "usage",
    ),
    cache_write_input_tokens: moonbit_internal_int_or_missing_default(
      object, "cache_write_input_tokens", path, "usage", 0,
    ),
    output_tokens: moonbit_internal_required_int(
      object, "output_tokens", path, "usage",
    ),
    reasoning_output_tokens: moonbit_internal_required_int(
      object, "reasoning_output_tokens", path, "usage",
    ),
  }
}

///|
pub impl @json.FromJson for TurnCompletedEvent with fn from_json(json, path) {
  let object = moonbit_internal_json_object(json, path, "turn.completed")
  {
    usage: @json.from_json(
      moonbit_internal_required_json(object, "usage", path, "turn.completed"),
      path=path.add_key("usage"),
    ),
  }
}

///|
pub impl @json.FromJson for ThreadError with fn from_json(json, path) {
  let object = moonbit_internal_json_object(json, path, "thread error")
  {
    message: moonbit_internal_required_string(
      object, "message", path, "thread error",
    ),
  }
}

///|
pub impl @json.FromJson for TurnFailedEvent with fn from_json(json, path) {
  let object = moonbit_internal_json_object(json, path, "turn.failed")
  {
    error: @json.from_json(
      moonbit_internal_required_json(object, "error", path, "turn.failed"),
      path=path.add_key("error"),
    ),
  }
}

///|
pub impl @json.FromJson for ItemStartedEvent with fn from_json(json, path) {
  let object = moonbit_internal_json_object(json, path, "item.started")
  {
    item: @json.from_json(
      moonbit_internal_required_json(object, "item", path, "item.started"),
      path=path.add_key("item"),
    ),
  }
}

///|
pub impl @json.FromJson for ItemUpdatedEvent with fn from_json(json, path) {
  let object = moonbit_internal_json_object(json, path, "item.updated")
  {
    item: @json.from_json(
      moonbit_internal_required_json(object, "item", path, "item.updated"),
      path=path.add_key("item"),
    ),
  }
}

///|
pub impl @json.FromJson for ItemCompletedEvent with fn from_json(json, path) {
  let object = moonbit_internal_json_object(json, path, "item.completed")
  {
    item: @json.from_json(
      moonbit_internal_required_json(object, "item", path, "item.completed"),
      path=path.add_key("item"),
    ),
  }
}

///|
pub impl @json.FromJson for ThreadErrorEvent with fn from_json(json, path) {
  let object = moonbit_internal_json_object(json, path, "error")
  {
    message: moonbit_internal_required_string(object, "message", path, "error"),
  }
}

///|
pub impl @json.FromJson for ThreadEvent with fn from_json(json, path) {
  let object = moonbit_internal_json_object(json, path, "thread event")
  let event_type = moonbit_internal_required_string(
    object, "type", path, "thread event",
  )
  match event_type {
    "thread.started" => ThreadStarted(@json.from_json(json, path~))
    "turn.started" => TurnStarted(@json.from_json(json, path~))
    "turn.completed" => TurnCompleted(@json.from_json(json, path~))
    "turn.failed" => TurnFailed(@json.from_json(json, path~))
    "item.started" => ItemStarted(@json.from_json(json, path~))
    "item.updated" => ItemUpdated(@json.from_json(json, path~))
    "item.completed" => ItemCompleted(@json.from_json(json, path~))
    "error" => StreamError(@json.from_json(json, path~))
    _ =>
      moonbit_internal_decode_error(
        path.add_key("type"),
        "unsupported thread event type: \{event_type}",
      )
  }
}
