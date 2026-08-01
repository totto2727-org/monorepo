///|
/// A completed text part emitted by OpenCode.
pub(all) struct TextEvent {
  session_id : String
  text : String
} derive(Debug, Eq)

///|
pub impl @json.FromJson for TextEvent with fn from_json(json, path) {
  let message = "TextEvent::from_json: expected text event"
  let session_id_path = path.add_key("sessionID")
  let text_path = path.add_key("part").add_key("text")
  let root = @lens.root()
  let session_id_value = root.json("sessionID").get(json) catch {
      _ => raise @json.JsonDecodeError((session_id_path, message))
    }
  let text_value = root.object("part").json("text").get(json) catch {
      _ => raise @json.JsonDecodeError((text_path, message))
    }
  {
    session_id: @json.FromJson::from_json(session_id_value, session_id_path),
    text: @json.FromJson::from_json(text_value, text_path),
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
  let session_id_path = path.add_key("sessionID")
  let text_path = path.add_key("part").add_key("text")
  let root = @lens.root()
  let session_id_value = root.json("sessionID").get(json) catch {
      _ => raise @json.JsonDecodeError((session_id_path, message))
    }
  let text_value = root.object("part").json("text").get(json) catch {
      _ => raise @json.JsonDecodeError((text_path, message))
    }
  {
    session_id: @json.FromJson::from_json(session_id_value, session_id_path),
    text: @json.FromJson::from_json(text_value, text_path),
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
  let session_id_path = path.add_key("sessionID")
  let call_id_path = path.add_key("part").add_key("callID")
  let tool_path = path.add_key("part").add_key("tool")
  let status_path = path.add_key("part").add_key("state").add_key("status")
  let root = @lens.root()
  let part = root.object("part")
  let session_id_value = root.json("sessionID").get(json) catch {
      _ => raise @json.JsonDecodeError((session_id_path, message))
    }
  let call_id_value = part.json("callID").get(json) catch {
      _ => raise @json.JsonDecodeError((call_id_path, message))
    }
  let tool_value = part.json("tool").get(json) catch {
      _ => raise @json.JsonDecodeError((tool_path, message))
    }
  let status_value = part.object("state").json("status").get(json) catch {
      _ => raise @json.JsonDecodeError((status_path, message))
    }
  {
    session_id: @json.FromJson::from_json(session_id_value, session_id_path),
    call_id: @json.FromJson::from_json(call_id_value, call_id_path),
    tool: @json.FromJson::from_json(tool_value, tool_path),
    status: @json.FromJson::from_json(status_value, status_path),
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
  let session_id_path = path.add_key("sessionID")
  let session_id_value = @lens.root().json("sessionID").get(json) catch {
      _ => raise @json.JsonDecodeError((session_id_path, message))
    }
  { session_id: @json.FromJson::from_json(session_id_value, session_id_path) }
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
  let input_path = path.add_key("input")
  let output_path = path.add_key("output")
  let reasoning_path = path.add_key("reasoning")
  let cache_read_path = path.add_key("cache").add_key("read")
  let cache_write_path = path.add_key("cache").add_key("write")
  let input_value = root.json("input").get(json) catch {
      _ => raise @json.JsonDecodeError((input_path, message))
    }
  let output_value = root.json("output").get(json) catch {
      _ => raise @json.JsonDecodeError((output_path, message))
    }
  let reasoning_value = root.json("reasoning").get(json) catch {
      _ => raise @json.JsonDecodeError((reasoning_path, message))
    }
  let cache_read_value = cache.json("read").get(json) catch {
      _ => raise @json.JsonDecodeError((cache_read_path, message))
    }
  let cache_write_value = cache.json("write").get(json) catch {
      _ => raise @json.JsonDecodeError((cache_write_path, message))
    }
  {
    input_tokens: @json.FromJson::from_json(input_value, input_path),
    output_tokens: @json.FromJson::from_json(output_value, output_path),
    reasoning_tokens: @json.FromJson::from_json(reasoning_value, reasoning_path),
    cache_read_tokens: @json.FromJson::from_json(
      cache_read_value, cache_read_path,
    ),
    cache_write_tokens: @json.FromJson::from_json(
      cache_write_value, cache_write_path,
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
  let root = @lens.root()
  let part = root.object("part")
  let session_id_path = path.add_key("sessionID")
  let reason_path = path.add_key("part").add_key("reason")
  let cost_path = path.add_key("part").add_key("cost")
  let usage_path = path.add_key("part").add_key("tokens")
  let session_id_value = root.json("sessionID").get(json) catch {
      _ => raise @json.JsonDecodeError((session_id_path, message))
    }
  let reason_value = part.json("reason").get(json) catch {
      _ => raise @json.JsonDecodeError((reason_path, message))
    }
  let cost_value = part.json("cost").get(json) catch {
      _ => raise @json.JsonDecodeError((cost_path, message))
    }
  let usage_value = part.json("tokens").get(json) catch {
      _ => raise @json.JsonDecodeError((usage_path, message))
    }
  {
    session_id: @json.FromJson::from_json(session_id_value, session_id_path),
    reason: @json.FromJson::from_json(reason_value, reason_path),
    cost: @json.FromJson::from_json(cost_value, cost_path),
    usage: @json.FromJson::from_json(usage_value, usage_path),
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
  let name_path = path.add_key("error").add_key("name")
  let session_id_path = path.add_key("sessionID")
  let name = error.json("name").get(json) catch {
      _ => raise @json.JsonDecodeError((name_path, message))
    }
  let data_message = error.object("data").json("message").get(json) catch {
      @lens.LensError::LensError(_) => name
    }
  let session_id_value = root.json("sessionID").get(json) catch {
      _ => raise @json.JsonDecodeError((session_id_path, message))
    }
  {
    session_id: Some(
      @json.FromJson::from_json(session_id_value, session_id_path),
    ),
    message: match data_message {
      String(message) => message
      _ => @json.FromJson::from_json(name, name_path)
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
  let type_path = path.add_key("type")
  let type_value = @lens.root().json("type").get(json) catch {
      _ =>
        raise @json.JsonDecodeError(
          (type_path, "ThreadEvent::from_json: expected thread event"),
        )
    }
  let event_type : String = @json.FromJson::from_json(type_value, type_path)
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
