///| Temporary W0 compiler-contract spike. Production behavior is deferred to later workstreams.

///|
/// Identifies a graph node at public map and query boundaries.
pub struct NodeId(String) derive(Eq, Hash, Debug)

///|
/// Wraps an already-selected node identifier without performing W1 validation.
pub fn NodeId::from_string(value : String) -> NodeId {
  NodeId(value)
}

///|
/// Carries the invocation-owned task group to asynchronous node callbacks.
pub(all) struct NodeContext {
  task_group : @async.TaskGroup[Unit]
}

///|
/// Proves that graph-specific state and patch callbacks can remain generic and asynchronous.
pub(all) struct Node[S, P] {
  execute : async (NodeContext, S) -> P
}

///|
/// Proves that synchronous graph callbacks can expose heterogeneous failures.
pub(all) struct Router[S] {
  evaluate : (S) -> NodeId raise
}

///|
/// Retains an unexpected failure as structured public context.
pub(all) struct RunFailure {
  cause : Error
}

///|
/// Exposes node identifiers without returning a mutable array alias.
pub(all) struct NodeQuery {
  node_ids : ReadOnlyArray[NodeId]
}

///|
/// Carries the invocation-owned task group to coding-agent session creation.
pub(all) struct CodingAgentOpenContext {
  task_group : @async.TaskGroup[Unit]
}

///|
/// Defines the asynchronous, externally implementable coding-agent session boundary.
pub(open) trait CodingAgentSession {
  async fn close(Self) -> Unit
}

///|
/// Proves that a coding-agent opener can return an asynchronous trait object.
pub(all) struct CodingAgent {
  open : async (CodingAgentOpenContext) -> &CodingAgentSession
}

///|
/// Proves that runtime-owned session state can retain coding-agent trait objects in a map.
pub(all) struct SessionRegistry {
  sessions : Map[NodeId, &CodingAgentSession]
}
