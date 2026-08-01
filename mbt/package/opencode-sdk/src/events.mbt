///|
/// A completed text part emitted by OpenCode.
pub(all) struct TextEvent {
  session_id : String
  text : String
} derive(Debug, Eq)

///|
fn moonbit_internal_json_field(
  lens : @lens.Lens[Json],
  json : Json,
  path : @json.JsonPath,
  message : String,
) -> Json raise @json.JsonDecodeError {
  lens.get(json) catch {
    @lens.LensError::LensError(_) =>
      raise @json.JsonDecodeError((path, message))
  }
}

///|
pub impl @json.FromJson for TextEvent with fn from_json(json, path) {
  let message = "TextEvent::from_json: expected text event"
  {
    session_id: @json.FromJson::from_json(
      moonbit_internal_json_field(
        @lens.root().json("sessionID"),
        json,
        path,
        message,
      ),
      path.add_key("sessionID"),
    ),
    text: @json.FromJson::from_json(
      moonbit_internal_json_field(
        @lens.root().object("part").json("text"),
        json,
        path,
        message,
      ),
      path.add_key("part").add_key("text"),
    ),
  }
}

///|
/// A completed reasoning part emitted when thinking output is enabled.
pub(all) struct ReasoningEvent {
  session_id : String
  text : String
} derive(Debug, Eq)

///|
pub impl @json.FromJson for ReasoningEvent with fn from_json(json, path) {
  let message = "ReasoningEvent::from_json: expected reasoning event"
  {
    session_id: @json.FromJson::from_json(
      moonbit_internal_json_field(
        @lens.root().json("sessionID"),
        json,
        path,
        message,
      ),
      path.add_key("sessionID"),
    ),
    text: @json.FromJson::from_json(
      moonbit_internal_json_field(
        @lens.root().object("part").json("text"),
        json,
        path,
        message,
      ),
      path.add_key("part").add_key("text"),
    ),
  }
}

///|
/// The terminal or active state of an OpenCode tool call.
pub(all) enum ToolUseStatus {
  Completed
  Failed
} derive(Debug, Eq)

///|
pub impl @json.FromJson for ToolUseStatus with fn from_json(json, path) {
  match @json.FromJson::from_json(json, path) {
    "completed" => Completed
    "error" => Failed
    status =>
      raise @json.JsonDecodeError(
        (path, "ToolUseStatus::from_json: unsupported status: \{status}"),
      )
  }
}

///|
/// A tool-use part emitted by OpenCode.
pub(all) struct ToolUseEvent {
  session_id : String
  call_id : String
  tool : String
  status : ToolUseStatus
} derive(Debug, Eq)

///|
pub impl @json.FromJson for ToolUseEvent with fn from_json(json, path) {
  let message = "ToolUseEvent::from_json: expected tool-use event"
  let part = @lens.root().object("part")
  {
    session_id: @json.FromJson::from_json(
      moonbit_internal_json_field(
        @lens.root().json("sessionID"),
        json,
        path,
        message,
      ),
      path.add_key("sessionID"),
    ),
    call_id: @json.FromJson::from_json(
      moonbit_internal_json_field(part.json("callID"), json, path, message),
      path.add_key("part").add_key("callID"),
    ),
    tool: @json.FromJson::from_json(
      moonbit_internal_json_field(part.json("tool"), json, path, message),
      path.add_key("part").add_key("tool"),
    ),
    status: @json.FromJson::from_json(
      moonbit_internal_json_field(
        part.object("state").json("status"),
        json,
        path,
        message,
      ),
      path.add_key("part").add_key("state").add_key("status"),
    ),
  }
}

///|
/// A marker emitted when OpenCode begins a model step.
pub(all) struct StepStartEvent {
  session_id : String
} derive(Debug, Eq)

///|
pub impl @json.FromJson for StepStartEvent with fn from_json(json, path) {
  let message = "StepStartEvent::from_json: expected step-start event"
  {
    session_id: @json.FromJson::from_json(
      moonbit_internal_json_field(
        @lens.root().json("sessionID"),
        json,
        path,
        message,
      ),
      path.add_key("sessionID"),
    ),
  }
}

///|
/// Token usage reported when OpenCode finishes a model step.
pub(all) struct Usage {
  input_tokens : Int
  output_tokens : Int
  reasoning_tokens : Int
  cache_read_tokens : Int
  cache_write_tokens : Int
} derive(Debug, Eq)

///|
pub impl @json.FromJson for Usage with fn from_json(json, path) {
  let message = "Usage::from_json: expected usage"
  let root = @lens.root()
  let cache = root.object("cache")
  {
    input_tokens: @json.FromJson::from_json(
      moonbit_internal_json_field(root.json("input"), json, path, message),
      path.add_key("input"),
    ),
    output_tokens: @json.FromJson::from_json(
      moonbit_internal_json_field(root.json("output"), json, path, message),
      path.add_key("output"),
    ),
    reasoning_tokens: @json.FromJson::from_json(
      moonbit_internal_json_field(root.json("reasoning"), json, path, message),
      path.add_key("reasoning"),
    ),
    cache_read_tokens: @json.FromJson::from_json(
      moonbit_internal_json_field(cache.json("read"), json, path, message),
      path.add_key("cache").add_key("read"),
    ),
    cache_write_tokens: @json.FromJson::from_json(
      moonbit_internal_json_field(cache.json("write"), json, path, message),
      path.add_key("cache").add_key("write"),
    ),
  }
}

///|
/// A marker and usage payload emitted when OpenCode finishes a model step.
pub(all) struct StepFinishEvent {
  session_id : String
  reason : String
  cost : Double
  usage : Usage
} derive(Debug, Eq)

///|
pub impl @json.FromJson for StepFinishEvent with fn from_json(json, path) {
  let message = "StepFinishEvent::from_json: expected step-finish event"
  let part = @lens.root().object("part")
  {
    session_id: @json.FromJson::from_json(
      moonbit_internal_json_field(
        @lens.root().json("sessionID"),
        json,
        path,
        message,
      ),
      path.add_key("sessionID"),
    ),
    reason: @json.FromJson::from_json(
      moonbit_internal_json_field(part.json("reason"), json, path, message),
      path.add_key("part").add_key("reason"),
    ),
    cost: @json.FromJson::from_json(
      moonbit_internal_json_field(part.json("cost"), json, path, message),
      path.add_key("part").add_key("cost"),
    ),
    usage: @json.FromJson::from_json(
      moonbit_internal_json_field(part.json("tokens"), json, path, message),
      path.add_key("part").add_key("tokens"),
    ),
  }
}

///|
/// A fatal error emitted by the OpenCode event stream.
pub(all) struct ThreadErrorEvent {
  session_id : String?
  message : String
} derive(Debug, Eq)

///|
pub impl @json.FromJson for ThreadErrorEvent with fn from_json(json, path) {
  let message = "ThreadErrorEvent::from_json: expected error event"
  let root = @lens.root()
  let error = root.object("error")
  let name = moonbit_internal_json_field(
    error.json("name"),
    json,
    path,
    message,
  )
  let data_message = error.object("data").json("message").get(json) catch {
      @lens.LensError::LensError(_) => name
    }
  {
    session_id: Some(
      @json.FromJson::from_json(
        moonbit_internal_json_field(root.json("sessionID"), json, path, message),
        path.add_key("sessionID"),
      ),
    ),
    message: match data_message {
      String(message) => message
      _ =>
        @json.FromJson::from_json(name, path.add_key("error").add_key("name"))
    },
  }
}

///|
/// One typed JSONL event emitted by `opencode run --format json`.
pub(all) enum ThreadEvent {
  Text(TextEvent)
  Reasoning(ReasoningEvent)
  ToolUse(ToolUseEvent)
  StepStart(StepStartEvent)
  StepFinish(StepFinishEvent)
  StreamError(ThreadErrorEvent)
} derive(Debug, Eq)

///|
pub impl @json.FromJson for ThreadEvent with fn from_json(json, path) {
  let event_type : String = @json.FromJson::from_json(
    moonbit_internal_json_field(
      @lens.root().json("type"),
      json,
      path,
      "ThreadEvent::from_json: expected thread event",
    ),
    path.add_key("type"),
  )
  match event_type {
    "text" => Text(@json.FromJson::from_json(json, path))
    "reasoning" => Reasoning(@json.FromJson::from_json(json, path))
    "tool_use" => ToolUse(@json.FromJson::from_json(json, path))
    "step_start" => StepStart(@json.FromJson::from_json(json, path))
    "step_finish" => StepFinish(@json.FromJson::from_json(json, path))
    "error" => StreamError(@json.FromJson::from_json(json, path))
    _ =>
      raise @json.JsonDecodeError(
        (path.add_key("type"), "unsupported thread event type: \{event_type}"),
      )
  }
}

///|
/// Return the session identifier carried by an event, when present.
fn ThreadEvent::session_id(self : ThreadEvent) -> String? {
  match self {
    Text(event) => Some(event.session_id)
    Reasoning(event) => Some(event.session_id)
    ToolUse(event) => Some(event.session_id)
    StepStart(event) => Some(event.session_id)
    StepFinish(event) => Some(event.session_id)
    StreamError(event) => event.session_id
  }
}
