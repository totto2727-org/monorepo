///|
pub struct WorkspaceRef {
  root : @path.Path
  additional_writable_roots : ReadOnlyArray[@path.Path]
} derive(Debug, Eq)

///|
/// Creates a writable workspace description for a coding agent.
pub fn WorkspaceRef::WorkspaceRef(
  root : @path.Path,
  additional_writable_roots : ReadOnlyArray[@path.Path],
) -> WorkspaceRef {
  WorkspaceRef::{ root, additional_writable_roots }
}

///|
pub struct CodingAgentRequest {
  instruction : String
  context_files : ReadOnlyArray[@path.Path]
} derive(Debug, Eq)

///|
/// Creates one coding-agent request.
pub fn CodingAgentRequest::CodingAgentRequest(
  instruction : String,
  context_files : ReadOnlyArray[@path.Path],
) -> CodingAgentRequest {
  CodingAgentRequest::{ instruction, context_files }
}

///|
pub(all) enum CodingAgentStatus {
  Succeeded
  Failed
  NeedsApproval
} derive(Debug, Eq)

///|
pub struct CodingAgentResponse {
  status : CodingAgentStatus
  summary : String?
  continuation_id : String?
  changed_files : ReadOnlyArray[@path.Path]
  artifacts : ReadOnlyArray[Artifact]
  raw_output : Json?
} derive(Debug)

///|
/// Creates one coding-agent response.
pub fn CodingAgentResponse::CodingAgentResponse(
  status~ : CodingAgentStatus,
  summary~ : String?,
  continuation_id~ : String?,
  changed_files~ : ReadOnlyArray[@path.Path],
  artifacts~ : ReadOnlyArray[Artifact],
  raw_output~ : Json?,
) -> CodingAgentResponse {
  CodingAgentResponse::{
    status,
    summary,
    continuation_id,
    changed_files,
    artifacts,
    raw_output,
  }
}

///|
pub(all) enum ApprovalPolicy {
  Never
  OnRequest
  OnFailure
  Untrusted
} derive(Debug, Eq)

///|
pub(all) enum NetworkPolicy {
  Disabled
  Enabled
} derive(Debug, Eq)

///|
pub struct CodingAgentOpenContext {
  run_id : RunId
  task_group : @async.TaskGroup[Unit]
  workspace : WorkspaceRef
  approval : ApprovalPolicy
  network : NetworkPolicy
  environment : @immut_hashmap.HashMap[String, String]
  events : EventSink
}

///|
/// Creates the runtime context used to open a coding-agent session.
pub fn CodingAgentOpenContext::CodingAgentOpenContext(
  run_id~ : RunId,
  task_group~ : @async.TaskGroup[Unit],
  workspace~ : WorkspaceRef,
  approval~ : ApprovalPolicy,
  network~ : NetworkPolicy,
  environment~ : @immut_hashmap.HashMap[String, String],
  events~ : EventSink,
) -> CodingAgentOpenContext {
  CodingAgentOpenContext::{
    run_id,
    task_group,
    workspace,
    approval,
    network,
    environment,
    events,
  }
}

///|
/// Represents a live provider-specific coding-agent session.
///
/// This trait is open so downstream integrations can provide session
/// implementations for additional coding-agent providers.
pub(open) trait CodingAgentSession {
  fn id(Self) -> SessionId?
  async fn execute(Self, CodingAgentRequest) -> CodingAgentResponse
  async fn close(Self) -> Unit
}

///|
pub struct CodingAgent {
  id : CodingAgentId
  open : async (CodingAgentOpenContext) -> &CodingAgentSession
}

///|
/// Creates a coding-agent adapter.
pub fn CodingAgent::CodingAgent(
  id : CodingAgentId,
  open : async (CodingAgentOpenContext) -> &CodingAgentSession,
) -> CodingAgent {
  CodingAgent::{ id, open }
}
