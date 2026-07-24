///| A completed agent turn.
pub(all) struct Turn {
  items : Array[ThreadItem]
  final_response : String
  usage : Usage?
} derive(Eq)

///| Alias describing the result returned by `Thread::run`.
pub type RunResult = Turn

///| Represents one persisted conversation with the Codex agent.
pub struct Thread {
  priv exec : CodexExec
  priv options : CodexOptions
  priv mut id_value : String?
  priv thread_options : ThreadOptions
}

///| Returns the persisted thread identifier after the first turn starts.
pub fn Thread::id(self : Thread) -> String? {
  self.id_value
}

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
pub async fn Thread::run_streamed(
  self : Thread,
  input : Input,
  on_event : async (ThreadEvent) -> Unit,
  turn_options? : TurnOptions = TurnOptions::TurnOptions(),
) -> Unit raise {
  self.run_streamed_internal(input, turn_options, on_event)
}

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
      let event = ThreadEvent::from_json(@json.parse(line)) catch {
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
