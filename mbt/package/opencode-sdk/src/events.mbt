///|
/// A completed text part emitted by OpenCode.
pub(all) struct TextEvent {
  session_id : String
  text : String
} derive(Debug, Eq)

///|
/// A completed reasoning part emitted when thinking output is enabled.
pub(all) struct ReasoningEvent {
  session_id : String
  text : String
} derive(Debug, Eq)

///|
/// The terminal or active state of an OpenCode tool call.
pub(all) enum ToolUseStatus {
  Completed
  Failed
} derive(Debug, Eq)

///|
/// A tool-use part emitted by OpenCode.
pub(all) struct ToolUseEvent {
  session_id : String
  call_id : String
  tool : String
  status : ToolUseStatus
} derive(Debug, Eq)

///|
/// A marker emitted when OpenCode begins a model step.
pub(all) struct StepStartEvent {
  session_id : String
} derive(Debug, Eq)

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
/// A marker and usage payload emitted when OpenCode finishes a model step.
pub(all) struct StepFinishEvent {
  session_id : String
  reason : String
  cost : Double
  usage : Usage
} derive(Debug, Eq)

///|
/// A fatal error emitted by the OpenCode event stream.
pub(all) struct ThreadErrorEvent {
  session_id : String?
  message : String
} derive(Debug, Eq)

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
