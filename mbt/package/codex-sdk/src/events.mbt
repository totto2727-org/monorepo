// Direct port of https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/events.ts

///| Emitted when a new thread is started.
///| Upstream: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/events.ts#L5-L10
pub(all) struct ThreadStartedEvent {
  thread_id : String
} derive(Debug, Eq)

///| Emitted when a turn starts.
///| Upstream: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/events.ts#L12-L18
pub(all) struct TurnStartedEvent {} derive(Debug, Eq)

///| Token usage reported for a completed turn.
///| Upstream: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/events.ts#L20-L32
pub(all) struct Usage {
  input_tokens : Int
  cached_input_tokens : Int
  cache_write_input_tokens : Int
  output_tokens : Int
  reasoning_output_tokens : Int
} derive(Debug, Eq)

///| Emitted when a turn completes.
///| Upstream: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/events.ts#L34-L38
pub(all) struct TurnCompletedEvent {
  usage : Usage
} derive(Debug, Eq)

///| A fatal error attached to a failed turn.
///| Upstream: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/events.ts#L64-L67
pub(all) struct ThreadError {
  message : String
} derive(Debug, Eq)

///| Emitted when a turn fails.
///| Upstream: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/events.ts#L40-L44
pub(all) struct TurnFailedEvent {
  error : ThreadError
} derive(Debug, Eq)

///| Emitted when a new item is added to a thread.
///| Upstream: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/events.ts#L46-L50
pub(all) struct ItemStartedEvent {
  item : ThreadItem
} derive(Eq)

///| Emitted when an existing item changes.
///| Upstream: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/events.ts#L52-L56
pub(all) struct ItemUpdatedEvent {
  item : ThreadItem
} derive(Eq)

///| Emitted when an item reaches a terminal state.
///| Upstream: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/events.ts#L58-L62
pub(all) struct ItemCompletedEvent {
  item : ThreadItem
} derive(Eq)

///| An unrecoverable error emitted directly by the event stream.
///| Upstream: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/events.ts#L69-L73
pub(all) struct ThreadErrorEvent {
  message : String
} derive(Debug, Eq)

///| Top-level JSONL event emitted by `codex exec`.
///| Upstream: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/events.ts#L75-L84
pub(all) enum ThreadEvent {
  ThreadStarted(ThreadStartedEvent)
  TurnStarted(TurnStartedEvent)
  TurnCompleted(TurnCompletedEvent)
  TurnFailed(TurnFailedEvent)
  ItemStarted(ItemStartedEvent)
  ItemUpdated(ItemUpdatedEvent)
  ItemCompleted(ItemCompletedEvent)
  StreamError(ThreadErrorEvent)
} derive(Eq)
