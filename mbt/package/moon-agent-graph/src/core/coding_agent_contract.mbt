///|
pub(all) struct WorkspaceRef {
  root : @path.Path
  additional_writable_roots : Array[@path.Path]
} derive(Debug, Eq)

///|
pub(all) struct CodingAgentRequest {
  instruction : String
  context_files : Array[@path.Path]
} derive(Debug, Eq)

///|
pub(all) enum CodingAgentStatus {
  Succeeded
  Failed
  NeedsApproval
} derive(Debug, Eq)

///|
pub(all) struct CodingAgentResponse {
  status : CodingAgentStatus
  summary : String?
  continuation_id : String?
  changed_files : Array[@path.Path]
  artifacts : Array[Artifact]
  raw_output : Json?
} derive(Debug)

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
pub(all) struct CodingAgentOpenContext {
  run_id : RunId
  task_group : @async.TaskGroup[Unit]
  workspace : WorkspaceRef
  approval : ApprovalPolicy
  network : NetworkPolicy
  environment : Map[String, String]
  events : EventSink
}

///|
pub(open) trait CodingAgentSession {
  fn id(Self) -> SessionId?
  async fn execute(Self, CodingAgentRequest) -> CodingAgentResponse
  async fn close(Self) -> Unit
}

///|
pub(all) struct CodingAgent {
  id : CodingAgentId
  open : async (CodingAgentOpenContext) -> &CodingAgentSession
}
