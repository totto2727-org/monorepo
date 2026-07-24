// Direct port of https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/thread.ts

///| A completed agent turn.
///| Upstream: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/thread.ts#L9-L14
pub(all) struct Turn {
  items : Array[ThreadItem]
  final_response : String
  usage : Usage?
} derive(Eq)

///| Alias describing the result returned by `Thread::run`.
///| Upstream: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/thread.ts#L16-L17
pub type RunResult = Turn

///| The result type returned after a streamed callback completes.
///| Upstream: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/thread.ts#L19-L25
///| Async type difference: MoonBit has no AsyncGenerator, so streamed events are consumed by the callback and the result is Unit.
pub type StreamedTurn = Unit

///| Alias describing the result returned by `Thread::run_streamed`.
///| Upstream: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/thread.ts#L24-L25
pub type RunStreamedResult = StreamedTurn

///| One structured input entry sent to the agent.
///| Upstream: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/thread.ts#L27-L36
///| Type difference: MoonBit uses an enum instead of a discriminated object union, and Path replaces filesystem strings.
pub(all) enum UserInput {
  Text(String)
  LocalImage(@path.Path)
} derive(Eq)

///| Input accepted by a thread turn.
///| Upstream: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/thread.ts#L38
///| Type difference: MoonBit uses an enum instead of the TypeScript string-or-array union.
pub(all) enum Input {
  Prompt(String)
  UserInputs(Array[UserInput])
} derive(Eq)

///| Represents one persisted conversation with the Codex agent.
///| Upstream: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/thread.ts#L40-L45
pub struct Thread {
  priv exec : CodexExec
  priv options : CodexOptions
  priv mut id_value : String?
  priv thread_options : ThreadOptions
}

///| Returns the persisted thread identifier after the first turn starts.
///| Upstream: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/thread.ts#L47-L50
pub fn Thread::id(self : Thread) -> String? {
  self.id_value
}

///| Constructs the same internal thread state as the upstream constructor.
///| Upstream: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/thread.ts#L52-L63
fn Thread::Thread(
  exec : CodexExec,
  options : CodexOptions,
  thread_options : ThreadOptions,
  id? : String,
) -> Thread {
  { exec, options, id_value: id, thread_options }
}

///| Runs one turn and forwards each structured event as it is produced.
///
/// The callback is the MoonBit equivalent of consuming the TypeScript SDK's async event generator.
///| Upstream: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/thread.ts#L65-L68
///| Async type difference: the callback parameter replaces StreamedTurn.events because MoonBit has no AsyncGenerator.
pub async fn Thread::run_streamed(
  self : Thread,
  input : Input,
  on_event : async (ThreadEvent) -> Unit,
  turn_options? : TurnOptions = TurnOptions::TurnOptions(),
) -> Unit raise {
  self.run_streamed_internal(input, turn_options, on_event)
}

///| Implements the upstream runStreamedInternal process and cleanup order.
///| Upstream: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/thread.ts#L70-L114
///| Async type difference: event delivery uses a callback; explicit JSON decoding is isolated behind a moonbit_internal_ function.
async fn Thread::run_streamed_internal(
  self : Thread,
  input : Input,
  turn_options : TurnOptions,
  on_event : async (ThreadEvent) -> Unit,
) -> Unit raise {
  let schema_file = create_output_schema_file(turn_options.output_schema)
  let normalized = normalize_input(input)
  let options = self.thread_options
  let result = try? self.exec.run(
    {
      input: normalized.prompt,
      base_url: self.options.base_url,
      api_key: self.options.api_key,
      thread_id: self.id_value,
      images: normalized.images,
      model: options.model,
      sandbox_mode: options.sandbox_mode,
      working_directory: options.working_directory,
      additional_directories: options.additional_directories,
      skip_git_repo_check: options.skip_git_repo_check,
      output_schema_file: schema_file.schema_path,
      model_reasoning_effort: options.model_reasoning_effort,
      network_access_enabled: options.network_access_enabled,
      web_search_mode: options.web_search_mode,
      web_search_enabled: options.web_search_enabled,
      approval_policy: options.approval_policy,
    },
    async fn(line) {
      let event = moonbit_internal_thread_event_from_json(@json.parse(line)) catch {
        error =>
          raise InvalidEvent(
            message="Failed to parse item: \{line}; cause: \{error}",
          )
      }
      if event is ThreadStarted(started) {
        self.id_value = Some(started.thread_id)
      }
      on_event(event)
    },
  )
  @async.protect_from_cancel(fn() { schema_file.cleanup() })
  match result {
    Ok(_) => ()
    Err(error) => raise error
  }
}

///| Runs one turn and buffers completed items, the final response, and token usage.
///| Upstream: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/thread.ts#L116-L140
pub async fn Thread::run(
  self : Thread,
  input : Input,
  turn_options? : TurnOptions = TurnOptions::TurnOptions(),
) -> Turn raise {
  let items : Array[ThreadItem] = []
  let mut final_response = ""
  let mut usage : Usage? = None
  let mut turn_failure : ThreadError? = None
  self.run_streamed_internal(
    input,
    turn_options,
    async fn(event) {
      match event {
        ItemCompleted(completed) => {
          if completed.item is AgentMessage(message) {
            final_response = message.text
          }
          items.push(completed.item)
        }
        TurnCompleted(completed) => usage = Some(completed.usage)
        TurnFailed(failed) => turn_failure = Some(failed.error)
        ThreadStarted(_) |
        TurnStarted(_) |
        ItemStarted(_) |
        ItemUpdated(_) |
        StreamError(_) => ()
      }
    },
  )
  if turn_failure is Some(error) {
    raise CodexSdkError::TurnFailed(message=error.message)
  }
  { items, final_response, usage }
}

// Type difference: MoonBit requires a named type for the upstream normalizeInput return object.
// Upstream: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/thread.ts#L143-L157
priv struct MoonBitInternalNormalizedInput {
  prompt : String
  images : Array[@path.Path]
}

///| Separates prompt text and image paths with the same order and joining behavior as upstream normalizeInput.
///| Upstream: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/thread.ts#L143-L157
fn normalize_input(input : Input) -> MoonBitInternalNormalizedInput {
  match input {
    Prompt(prompt) => { prompt, images: [] }
    UserInputs(items) => {
      let prompt = items
        .iter()
        .filter_map(item =>
          match item {
            Text(text) => Some(text)
            LocalImage(_) => None
          })
        .join("\n\n")
      let images = items
        .iter()
        .filter_map(item =>
          match item {
            Text(_) => None
            LocalImage(path) => Some(path)
          })
        .collect()
      { prompt, images }
    }
  }
}
