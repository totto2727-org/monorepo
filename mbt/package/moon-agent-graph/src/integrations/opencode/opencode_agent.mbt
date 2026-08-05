///|
/// Configuration shared by every OpenCode CLI session opened by this adapter.
pub struct OpenCodeAgentOptions {
  opencode_path_override : @path.Path?
  config : @sdk.OpenCodeConfigObject?
  resume_thread_id : String?
  model : String?
  agent : String?
  variant : String?
  title : String?
  thinking : Bool
  extra_env : Map[String, String]
}

///|
/// Creates OpenCode adapter options with the CLI SDK's defaults.
pub fn OpenCodeAgentOptions::OpenCodeAgentOptions(
  opencode_path_override? : @path.Path,
  config? : @sdk.OpenCodeConfigObject,
  resume_thread_id? : String,
  model? : String,
  agent? : String,
  variant? : String,
  title? : String,
  thinking? : Bool = false,
  extra_env? : Map[String, String] = Map([]),
) -> OpenCodeAgentOptions {
  {
    opencode_path_override,
    config,
    resume_thread_id,
    model,
    agent,
    variant,
    title,
    thinking,
    extra_env,
  }
}

///|
/// Raised when execution is requested after a session has closed.
pub suberror OpenCodeAdapterError {
  SessionClosed
} derive(Debug)

///|
priv struct OpenCodeAgentSession {
  thread : @sdk.Thread
  workspace_root : @path.Path
  mutex : @async.Mutex
  mut closed : Bool
}

///|
fn request_input(
  workspace_root : @path.Path,
  request : @core.CodingAgentRequest,
) -> @sdk.Input {
  if request.context_files.is_empty() {
    return @sdk.Prompt(request.instruction)
  }
  let inputs : Array[@sdk.UserInput] = [@sdk.Text(request.instruction)]
  for path in request.context_files {
    inputs.push(
      @sdk.LocalFile(
        if path.is_absolute() {
          path
        } else {
          workspace_root.join(path)
        },
      ),
    )
  }
  @sdk.UserInputs(inputs)
}

///|
fn merged_environment(
  options : OpenCodeAgentOptions,
  context : @core.CodingAgentOpenContext,
) -> Map[String, String] {
  let environment = @env.get_env_vars()
  for key, value in options.extra_env {
    environment[key] = value
  }
  // Run context is caller-owned, so it overrides adapter defaults.
  for key, value in context.environment {
    environment[key] = value
  }
  environment
}

///|
impl @core.CodingAgentSession for OpenCodeAgentSession with fn id(self) {
  match self.thread.id() {
    Some(id) => Some(@core.SessionId::parse(id) catch { _ => return None })
    None => None
  }
}

///|
impl @core.CodingAgentSession for OpenCodeAgentSession with fn execute(
  self,
  request,
) {
  self.mutex.acquire()
  if self.closed {
    self.mutex.release()
    raise OpenCodeAdapterError::SessionClosed
  }
  let result = Ok(self.thread.run(request_input(self.workspace_root, request))) catch {
    error => Err(error)
  }
  self.mutex.release()
  let turn = match result {
    Ok(turn) => turn
    Err(error) => raise error
  }
  @core.CodingAgentResponse::CodingAgentResponse(
    @core.Succeeded,
    Some(turn.final_response),
    self.thread.id(),
    [],
    [],
    None,
  )
}

///|
impl @core.CodingAgentSession for OpenCodeAgentSession with fn close(self) {
  self.mutex.acquire()
  self.closed = true
  self.mutex.release()
}

///|
/// Creates a coding agent backed by the OpenCode CLI SDK.
pub fn opencode_agent(
  id : @core.CodingAgentId,
  options : OpenCodeAgentOptions,
) -> @core.CodingAgent {
  @core.CodingAgent::CodingAgent(id, async fn(context) {
    @async.pause()
    let client = @sdk.OpenCode::OpenCode(
      options=@sdk.OpenCodeOptions::OpenCodeOptions(
        opencode_path_override?=options.opencode_path_override,
        config?=options.config,
        env=merged_environment(options, context),
      ),
    )
    let thread_options = @sdk.ThreadOptions::ThreadOptions(
      model?=options.model,
      agent?=options.agent,
      working_directory=context.workspace.root,
      variant?=options.variant,
      title?=options.title,
      thinking=options.thinking,
    )
    let thread = match options.resume_thread_id {
      Some(thread_id) => client.resume_thread(thread_id, options=thread_options)
      None => client.start_thread(options=thread_options)
    }
    let session = OpenCodeAgentSession::{
      thread,
      workspace_root: context.workspace.root,
      mutex: @async.Mutex::Mutex(),
      closed: false,
    }
    (session : &@core.CodingAgentSession)
  })
}
