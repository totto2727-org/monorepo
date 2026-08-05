///|
/// A completed OpenCode turn.
pub struct Turn {
  events : ReadOnlyArray[ThreadEvent]
  final_response : String
} derive(Debug, Eq)

///|
/// Alias describing the result returned by `Thread::run`.
pub type RunResult = Turn

///|
/// The result type returned after a streamed callback completes.
pub type StreamedTurn = Unit

///|
/// Alias describing the result returned by `Thread::run_streamed`.
pub type RunStreamedResult = StreamedTurn

///|
/// One structured input entry sent to OpenCode.
pub(all) enum UserInput {
  Text(String)
  LocalFile(@path.Path)
} derive(Eq)

///|
/// Input accepted by an OpenCode turn.
pub(all) enum Input {
  Prompt(String)
  UserInputs(Array[UserInput])
} derive(Eq)

///|
/// One persisted OpenCode session.
pub struct Thread {
  priv exec : OpenCodeExec
  priv mut id_value : String?
  priv thread_options : ThreadOptions
}

///|
/// Return the persisted session identifier after the first event arrives.
pub fn Thread::id(self : Thread) -> String? {
  self.id_value
}

///|
fn Thread::Thread(
  exec : OpenCodeExec,
  thread_options : ThreadOptions,
  id? : String,
) -> Thread {
  { exec, id_value: id, thread_options }
}

///|
/// Run one turn and deliver typed OpenCode events as they arrive.
pub async fn Thread::run_streamed(
  self : Thread,
  input : Input,
  on_event : async (ThreadEvent) -> Unit,
) -> Unit {
  self.run_streamed_internal(input, async fn(event) {
    on_event(event)
    true
  })
}

///|
async fn Thread::run_streamed_internal(
  self : Thread,
  input : Input,
  on_event : async (ThreadEvent) -> Bool,
) -> Unit {
  let normalized = normalize_input(input)
  let options = self.thread_options
  let mut turn_failure : String? = None
  let result = Ok(
    self.exec.run(
      {
        input: normalized.prompt,
        session_id: self.id_value,
        files: normalized.files,
        model: options.model,
        agent: options.agent,
        working_directory: options.working_directory,
        variant: options.variant,
        title: options.title,
        thinking: options.thinking,
      },
      async fn(event) {
        if self.id_value is None && event.session_id() is Some(session_id) {
          self.id_value = Some(session_id)
        }
        let should_continue = on_event(event)
        if event is StreamError(error) {
          turn_failure = Some(error.message)
          false
        } else {
          should_continue
        }
      },
    ),
  ) catch {
    error => Err(error)
  }
  if turn_failure is Some(message) {
    raise TurnFailed(message~)
  }
  match result {
    Ok(_) => ()
    Err(error) => raise error
  }
}

///|
/// Run one turn and buffer its typed events and final text response.
pub async fn Thread::run(self : Thread, input : Input) -> Turn {
  let events : Array[ThreadEvent] = []
  let texts : Array[String] = []
  self.run_streamed_internal(input, fn(event) {
    events.push(event)
    if event is Text(text) {
      texts.push(text.text)
    }
    true
  })
  { events: ReadOnlyArray::from_array(events), final_response: texts.join("") }
}

///|
priv struct MoonBitInternalNormalizedInput {
  prompt : String
  files : Array[@path.Path]
}

///|
fn normalize_input(input : Input) -> MoonBitInternalNormalizedInput {
  match input {
    Prompt(prompt) => { prompt, files: [] }
    UserInputs(items) => {
      let prompt = items
        .iter()
        .filter_map(item => {
          match item {
            Text(text) => Some(text)
            LocalFile(_) => None
          }
        })
        .join("\n\n")
      let files = items
        .iter()
        .filter_map(item => {
          match item {
            Text(_) => None
            LocalFile(path) => Some(path)
          }
        })
        .collect()
      { prompt, files }
    }
  }
}
