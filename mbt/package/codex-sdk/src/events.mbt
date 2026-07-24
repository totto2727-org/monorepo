///| Emitted when a new thread is started.
pub(all) struct ThreadStartedEvent {
  thread_id : String
} derive(Debug, Eq)

///| Emitted when a turn starts.
pub(all) struct TurnStartedEvent {} derive(Debug, Eq)

///| Token usage reported for a completed turn.
pub(all) struct Usage {
  input_tokens : Int
  cached_input_tokens : Int
  cache_write_input_tokens : Int
  output_tokens : Int
  reasoning_output_tokens : Int
} derive(Debug, Eq)

///| Emitted when a turn completes.
pub(all) struct TurnCompletedEvent {
  usage : Usage
} derive(Debug, Eq)

///| A fatal error attached to a failed turn.
pub(all) struct ThreadError {
  message : String
} derive(Debug, Eq)

///| Emitted when a turn fails.
pub(all) struct TurnFailedEvent {
  error : ThreadError
} derive(Debug, Eq)

///| Emitted when a new item is added to a thread.
pub(all) struct ItemStartedEvent {
  item : ThreadItem
} derive(Eq)

///| Emitted when an existing item changes.
pub(all) struct ItemUpdatedEvent {
  item : ThreadItem
} derive(Eq)

///| Emitted when an item reaches a terminal state.
pub(all) struct ItemCompletedEvent {
  item : ThreadItem
} derive(Eq)

///| An unrecoverable error emitted directly by the event stream.
pub(all) struct ThreadErrorEvent {
  message : String
} derive(Debug, Eq)

///| Top-level JSONL event emitted by `codex exec`.
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
