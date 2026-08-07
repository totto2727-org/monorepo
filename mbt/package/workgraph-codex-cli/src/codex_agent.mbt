///|
/// Configuration shared by every Codex session opened by this adapter.
pub struct CodexAgentOptions {
  codex_path_override : @path.Path?
  base_url : String?
  api_key : String?
  config : @sdk.CodexConfigObject?
  resume_thread_id : String?
  model : String?
  sandbox : @sdk.SandboxMode?
  skip_git : Bool?
  reasoning : @sdk.ModelReasoningEffort?
  web_search : @sdk.WebSearchMode?
}

///|
/// Creates Codex adapter options with the SDK's defaults.
pub fn CodexAgentOptions::CodexAgentOptions(
  codex_path_override? : @path.Path,
  base_url? : String,
  api_key? : String,
  config? : @sdk.CodexConfigObject,
  resume_thread_id? : String,
  model? : String,
  sandbox? : @sdk.SandboxMode,
  skip_git? : Bool,
  reasoning? : @sdk.ModelReasoningEffort,
  web_search? : @sdk.WebSearchMode,
) -> CodexAgentOptions {
  {
    codex_path_override,
    base_url,
    api_key,
    config,
    resume_thread_id,
    model,
    sandbox,
    skip_git,
    reasoning,
    web_search,
  }
}

///|
/// Raised when execution is requested after a session has closed.
pub suberror CodexAdapterError {
  SessionClosed
} derive(Debug)

///|
priv struct CodexAgentSession {
  thread : @sdk.Thread
  mutex : @async.Mutex
  mut closed : Bool
}

///|
fn approval_mode(policy : @coding.ApprovalPolicy) -> @sdk.ApprovalMode {
  match policy {
    @coding.Never => @sdk.Never
    @coding.OnRequest => @sdk.OnRequest
    @coding.OnFailure => @sdk.OnFailure
    @coding.Untrusted => @sdk.Untrusted
  }
}

///|
fn network_enabled(policy : @coding.NetworkPolicy) -> Bool {
  match policy {
    @coding.Disabled => false
    @coding.Enabled => true
  }
}

///|
fn request_input(request : @coding.CodingAgentRequest) -> @sdk.Input {
  if request.context_files.is_empty() {
    return @sdk.Prompt(request.instruction)
  }
  let files = request.context_files
    .iter()
    .map(path => path.to_string())
    .join("\n")
  @sdk.Prompt(
    "\{request.instruction}\n\nContext files supplied by the caller:\n\{files}",
  )
}

///|
fn changed_files(
  items : ReadOnlyArray[@sdk.ThreadItem],
) -> ReadOnlyArray[@path.Path] {
  let files : Array[@path.Path] = []
  for item in items {
    match item {
      @sdk.FileChange(change) =>
        match change.status {
          @sdk.PatchCompleted =>
            for update in change.changes {
              files.push(update.path)
            }
          _ => ()
        }
      _ => ()
    }
  }
  ReadOnlyArray::from_array(files)
}

///|
impl @coding.CodingAgentSession for CodexAgentSession with fn id(self) {
  match self.thread.id() {
    Some(id) =>
      Some(@coding.SessionId::SessionId(id) catch { _ => return None })
    None => None
  }
}

///|
impl @coding.CodingAgentSession for CodexAgentSession with fn execute(
  self,
  request,
) {
  self.mutex.acquire()
  if self.closed {
    self.mutex.release()
    raise CodexAdapterError::SessionClosed
  }
  let result = Ok(self.thread.run(request_input(request))) catch {
    error => Err(error)
  }
  self.mutex.release()
  let turn = match result {
    Ok(turn) => turn
    Err(error) => raise error
  }
  @coding.CodingAgentResponse::CodingAgentResponse(
    status=@coding.Succeeded,
    summary=Some(turn.final_response),
    continuation_id=self.thread.id(),
    changed_files=changed_files(turn.items),
  )
}

///|
impl @coding.CodingAgentSession for CodexAgentSession with fn close(self) {
  self.mutex.acquire()
  self.closed = true
  self.mutex.release()
}

///|
/// Creates a coding agent backed by the pinned Codex SDK.
pub fn codex_agent(
  id : @coding.CodingAgentId,
  options : CodexAgentOptions,
) -> @coding.CodingAgent {
  @coding.CodingAgent::CodingAgent(id, async fn(context) {
    @async.pause()
    let client = @sdk.Codex::Codex(
      options=@sdk.CodexOptions::CodexOptions(
        codex_path_override?=options.codex_path_override,
        base_url?=options.base_url,
        api_key?=options.api_key,
        config?=options.config,
        env=Map(context.environment.to_array()),
      ),
    )
    let thread_options = @sdk.ThreadOptions::ThreadOptions(
      model?=options.model,
      sandbox_mode?=options.sandbox,
      working_directory=context.workspace.root,
      skip_git_repo_check?=options.skip_git,
      model_reasoning_effort?=options.reasoning,
      network_access_enabled=network_enabled(context.network),
      web_search_mode?=options.web_search,
      approval_policy=approval_mode(context.approval),
      additional_directories=[..context.workspace.additional_writable_roots],
    )
    let thread = match options.resume_thread_id {
      Some(thread_id) => client.resume_thread(thread_id, options=thread_options)
      None => client.start_thread(options=thread_options)
    }
    let session = CodexAgentSession::{
      thread,
      mutex: @async.Mutex::Mutex(),
      closed: false,
    }
    (session : &@coding.CodingAgentSession)
  })
}
