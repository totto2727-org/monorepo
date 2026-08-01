///|
/// An immutable hash map of dynamically typed values accessed through
/// `AnyRef`.
pub(all) struct AnyImmutableHashMap[K] {
  map : @immut.HashMap[K, @any.Any]
}

///|
/// Creates an empty immutable any hash map.
pub fn[K] AnyImmutableHashMap::AnyImmutableHashMap() -> AnyImmutableHashMap[K] {
  { map: @immut.new() }
}

///|
/// Returns a map associating `value` with `reference` without changing this map.
pub fn[K : Hash + Eq, T] AnyImmutableHashMap::added(
  self : AnyImmutableHashMap[K],
  reference : AnyRef[K, T],
  value : T,
) -> AnyImmutableHashMap[K] {
  { map: self.map.add(reference.key, (reference.encode)(value)) }
}

///|
/// Returns the value selected by `reference` when it exists with type `T`.
///
/// A missing key or a value stored through a differently typed reference
/// returns `None`.
pub fn[K : Hash + Eq, T] AnyImmutableHashMap::get(
  self : AnyImmutableHashMap[K],
  reference : AnyRef[K, T],
) -> T? {
  match self.map.get(reference.key) {
    Some(value) => (reference.decode)(value)
    None => None
  }
}
