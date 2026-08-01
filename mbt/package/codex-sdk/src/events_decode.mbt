// MoonBit FromJson implementations for wire formats that cannot use derive(FromJson).
// Corresponding upstream cast: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/thread.ts#L96-L109
// Event shapes being decoded: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/events.ts#L5-L84

///|
let usage_input_tokens_lens : @lens.Lens[Json] = @lens.root().json(
  "input_tokens",
)

///|
let usage_cached_input_tokens_lens : @lens.Lens[Json] = @lens.root().json(
  "cached_input_tokens",
)

///|
let usage_cache_write_input_tokens_lens : @lens.Lens[Json?] = @lens.root()
  .json("cache_write_input_tokens")
  .optional()

///|
let usage_output_tokens_lens : @lens.Lens[Json] = @lens.root().json(
  "output_tokens",
)

///|
let usage_reasoning_output_tokens_lens : @lens.Lens[Json] = @lens.root().json(
  "reasoning_output_tokens",
)

///|
let thread_event_type_lens : @lens.Lens[Json] = @lens.root().json("type")

///|
pub impl @json.FromJson for Usage with fn from_json(json, path) {
  guard json is Json::Object(_) else {
    raise @json.JsonDecodeError((path, "usage must be an object"))
  }
  let input_tokens : Int = @json.from_json(
    usage_input_tokens_lens.get(json) catch {
      _ =>
        raise @json.JsonDecodeError(
          (path.add_key("input_tokens"), "usage is missing input_tokens"),
        )
    },
    path=path.add_key("input_tokens"),
  )
  let cached_input_tokens : Int = @json.from_json(
    usage_cached_input_tokens_lens.get(json) catch {
      _ =>
        raise @json.JsonDecodeError(
          (
            path.add_key("cached_input_tokens"),
            "usage is missing cached_input_tokens",
          ),
        )
    },
    path=path.add_key("cached_input_tokens"),
  )
  let cache_write_value = usage_cache_write_input_tokens_lens.get(json) catch {
    _ =>
      raise @json.JsonDecodeError(
        (
          path.add_key("cache_write_input_tokens"),
          "usage.cache_write_input_tokens must be a number",
        ),
      )
  }
  let cache_write_input_tokens = match cache_write_value {
    Some(value) =>
      @json.from_json(value, path=path.add_key("cache_write_input_tokens"))
    None => 0
  }
  let output_tokens : Int = @json.from_json(
    usage_output_tokens_lens.get(json) catch {
      _ =>
        raise @json.JsonDecodeError(
          (path.add_key("output_tokens"), "usage is missing output_tokens"),
        )
    },
    path=path.add_key("output_tokens"),
  )
  let reasoning_output_tokens : Int = @json.from_json(
    usage_reasoning_output_tokens_lens.get(json) catch {
      _ =>
        raise @json.JsonDecodeError(
          (
            path.add_key("reasoning_output_tokens"),
            "usage is missing reasoning_output_tokens",
          ),
        )
    },
    path=path.add_key("reasoning_output_tokens"),
  )
  {
    input_tokens,
    cached_input_tokens,
    cache_write_input_tokens,
    output_tokens,
    reasoning_output_tokens,
  }
}

///|
pub impl @json.FromJson for ThreadEvent with fn from_json(json, path) {
  guard json is Json::Object(_) else {
    raise @json.JsonDecodeError((path, "thread event must be an object"))
  }
  let event_type : String = @json.from_json(
    thread_event_type_lens.get(json) catch {
      _ =>
        raise @json.JsonDecodeError(
          (path.add_key("type"), "thread event is missing type"),
        )
    },
    path=path.add_key("type"),
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
      raise @json.JsonDecodeError(
        (path.add_key("type"), "unsupported thread event type: \{event_type}"),
      )
  }
}
