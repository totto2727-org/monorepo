///|
pub(all) enum ResourceScope {
  Node
  Run
} derive(Debug, Eq)

///|
pub suberror ResourceStoreError {
  NodeOwnerRequired(ResourceKey)
  InvalidCleanupTimeout(Int)
  CleanupTimedOut(Int)
  CloseFailed(errors~ : ReadOnlyArray[Error])
} derive(Debug)

///|
struct StoredResourceCleanup {
  key : ResourceKey
  scope : ResourceScope
  owner : NodeId?
  cleanup : async () -> Unit
  mut closed : Bool
}

///|
pub struct ResourceStore {
  values : @any_collection.AnyMutableMap[ResourceKey]
  cleanups : Array[StoredResourceCleanup]
}

///|
pub fn ResourceStore::ResourceStore() -> ResourceStore {
  ResourceStore::{
    values: @any_collection.AnyMutableMap::AnyMutableMap([]),
    cleanups: [],
  }
}

///|
/// Stores an invocation-local value through a typed resource reference.
pub fn[T] ResourceStore::set(
  self : ResourceStore,
  reference : @any_collection.AnyRef[ResourceKey, T],
  value : T,
) -> Unit {
  self.values.set(reference, value)
}

///|
/// Returns an invocation-local value through its typed resource reference.
///
/// A missing key returns `None`; reusing a key with a different value type
/// raises the conversion error from `AnyRef`.
pub fn[T] ResourceStore::get(
  self : ResourceStore,
  reference : @any_collection.AnyRef[ResourceKey, T],
) -> T? raise {
  self.values.get(reference)
}

///|
/// Removes the invocation-local value selected by `reference`.
pub fn[T] ResourceStore::remove(
  self : ResourceStore,
  reference : @any_collection.AnyRef[ResourceKey, T],
) -> Unit {
  self.values.map.remove(reference.key)
}

///|
/// Acquires any typed resource and records its cleanup independently of the
/// resource's concrete type.
pub async fn[T] ResourceStore::acquire_resource(
  self : ResourceStore,
  reference : @any_collection.AnyRef[ResourceKey, T],
  scope : ResourceScope,
  open : async () -> T,
  cleanup : async (T) -> Unit,
  owner? : NodeId,
) -> T {
  match scope {
    Run =>
      match self.get(reference) {
        Some(resource) => return resource
        _ => ()
      }
    Node => if owner is None { raise NodeOwnerRequired(reference.key) }
  }
  let resource = open()
  self.set(reference, resource)
  self.cleanups.push(StoredResourceCleanup::{
    key: reference.key,
    scope,
    owner,
    cleanup: async fn() { cleanup(resource) },
    closed: false,
  })
  resource
}

///|
async fn ResourceStore::close_resource(
  self : ResourceStore,
  index : Int,
  errors : Array[Error],
) -> Unit {
  if self.cleanups[index].closed {
    return
  }
  self.cleanups[index].closed = true
  (self.cleanups[index].cleanup)() catch {
    error =>
      if @async.is_cancellation_error(error) {
        raise error
      } else {
        errors.push(error)
      }
  }
  self.values.map.remove(self.cleanups[index].key)
}

///|
pub async fn ResourceStore::release_node(
  self : ResourceStore,
  node_id : NodeId,
) -> Unit {
  let errors : Array[Error] = []
  let mut index = self.cleanups.length() - 1
  while index >= 0 {
    let stored = self.cleanups[index]
    if stored.scope == Node && stored.owner == Some(node_id) {
      self.close_resource(index, errors)
    }
    index = index - 1
  }
  if !errors.is_empty() {
    raise CloseFailed(errors=ReadOnlyArray::from_array(errors))
  }
}

///|
pub async fn ResourceStore::close_all(self : ResourceStore) -> Unit {
  let errors : Array[Error] = []
  let mut index = self.cleanups.length() - 1
  while index >= 0 {
    self.close_resource(index, errors)
    index = index - 1
  }
  if !errors.is_empty() {
    raise CloseFailed(errors=ReadOnlyArray::from_array(errors))
  }
}

///|
pub async fn ResourceStore::finalize(
  self : ResourceStore,
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
