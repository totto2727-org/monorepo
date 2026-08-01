///|
/// A mutable map of dynamically typed values accessed through `AnyRef`.
pub(all) struct AnyMutableMap[K] {
  map : Map[K, @any.Any]
}

///|
/// Creates an empty mutable any map.
pub fn[K : Hash + Eq] AnyMutableMap::AnyMutableMap() -> AnyMutableMap[K] {
  { map: Map([]) }
}

///|
/// Associates `value` with `reference`, replacing an existing value.
pub fn[K : Hash + Eq, T] AnyMutableMap::set(
  self : AnyMutableMap[K],
  reference : AnyRef[K, T],
  value : T,
) -> Unit {
  self.map[reference.key] = (reference.encode)(value)
}

///|
/// Returns the value selected by `reference` when it exists with type `T`.
///
/// A missing key or a value stored through a differently typed reference
/// returns `None`.
pub fn[K : Hash + Eq, T] AnyMutableMap::get(
  self : AnyMutableMap[K],
  reference : AnyRef[K, T],
) -> T? {
  match self.map.get(reference.key) {
    Some(value) => (reference.decode)(value)
    None => None
  }
}
