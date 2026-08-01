///|
pub(all) enum ResourceScope {
  Node
  Run
} derive(Debug, Eq)

///|
pub(all) suberror ResourceStoreError {
  NodeOwnerRequired(ResourceKey)
  InvalidCleanupTimeout(Int)
  CleanupTimedOut(Int)
  CloseFailed(errors~ : ReadOnlyArray[Error])
} derive(Debug)

///|
struct StoredSession {
  session : &CodingAgentSession
  scope : ResourceScope
  owner : NodeId?
  mut closed : Bool
}

///|
pub struct RuntimeResourceStore {
  sessions : Array[StoredSession]
  run_entries : Map[ResourceKey, Int]
}

///|
pub fn RuntimeResourceStore::RuntimeResourceStore() -> RuntimeResourceStore {
  RuntimeResourceStore::{ sessions: [], run_entries: Map([]) }
}

///|
pub async fn RuntimeResourceStore::acquire_agent_session(
  self : RuntimeResourceStore,
  key : ResourceKey,
  scope : ResourceScope,
  open : async () -> &CodingAgentSession,
  owner? : NodeId,
) -> &CodingAgentSession {
  match scope {
    Run =>
      match self.run_entries.get(key) {
        Some(index) if !self.sessions[index].closed =>
          return self.sessions[index].session
        _ => ()
      }
    Node => if owner is None { raise NodeOwnerRequired(key) }
  }
  let session = open()
  let index = self.sessions.length()
  self.sessions.push(StoredSession::{ session, scope, owner, closed: false })
  if scope == Run {
    self.run_entries[key] = index
  }
  session
}

///|
async fn RuntimeResourceStore::close_session(
  self : RuntimeResourceStore,
  index : Int,
  errors : Array[Error],
) -> Unit {
  if self.sessions[index].closed {
    return
  }
  self.sessions[index].closed = true
  self.sessions[index].session.close() catch {
    error =>
      if @async.is_cancellation_error(error) {
        raise error
      } else {
        errors.push(error)
      }
  }
}

///|
pub async fn RuntimeResourceStore::release_node(
  self : RuntimeResourceStore,
  node_id : NodeId,
) -> Unit {
  let errors : Array[Error] = []
  let mut index = self.sessions.length() - 1
  while index >= 0 {
    let stored = self.sessions[index]
    if stored.scope == Node && stored.owner == Some(node_id) {
      self.close_session(index, errors)
    }
    index = index - 1
  }
  if !errors.is_empty() {
    raise CloseFailed(errors=ReadOnlyArray::from_array(errors))
  }
}

///|
pub async fn RuntimeResourceStore::close_all(
  self : RuntimeResourceStore,
) -> Unit {
  let errors : Array[Error] = []
  let mut index = self.sessions.length() - 1
  while index >= 0 {
    self.close_session(index, errors)
    index = index - 1
  }
  if !errors.is_empty() {
    raise CloseFailed(errors=ReadOnlyArray::from_array(errors))
  }
}

///|
pub async fn RuntimeResourceStore::finalize(
  self : RuntimeResourceStore,
  timeout_ms : Int,
) -> Unit {
  if timeout_ms <= 0 {
    raise InvalidCleanupTimeout(timeout_ms)
  }
  @async.protect_from_cancel(async fn() {
    @async.with_timeout(
      timeout_ms,
      async fn() { self.close_all() },
      error=CleanupTimedOut(timeout_ms),
    )
  })
}
