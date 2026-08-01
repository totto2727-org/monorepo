///|
/// An immutable hash map of named dynamically typed values accessed through
/// `AnyRef`.
pub struct AnyImmutableHashMap {
  priv values : @immut.HashMap[String, @any.Any]
}

///|
/// Creates an empty immutable any hash map.
pub fn AnyImmutableHashMap::AnyImmutableHashMap() -> AnyImmutableHashMap {
  { values: @immut.new() }
}

///|
/// Returns a map associating `value` with `reference` without changing this map.
pub fn[T] AnyImmutableHashMap::added(
  self : AnyImmutableHashMap,
  reference : AnyRef[T],
  value : T,
) -> AnyImmutableHashMap {
  { values: self.values.add(reference.name, (reference.encode)(value)) }
}

///|
/// Returns the value selected by `reference` when it exists with type `T`.
///
/// A missing name or a value stored through a differently typed reference
/// returns `None`.
pub fn[T] AnyImmutableHashMap::get(
  self : AnyImmutableHashMap,
  reference : AnyRef[T],
) -> T? {
  match self.values.get(reference.name) {
    Some(value) => (reference.decode)(value)
    None => None
  }
}

///|
/// Returns whether a value is associated with `reference`'s name.
pub fn[T] AnyImmutableHashMap::contains(
  self : AnyImmutableHashMap,
  reference : AnyRef[T],
) -> Bool {
  self.values.contains(reference.name)
}

///|
/// Returns a map without the value associated with `reference`'s name.
pub fn[T] AnyImmutableHashMap::removed(
  self : AnyImmutableHashMap,
  reference : AnyRef[T],
) -> AnyImmutableHashMap {
  { values: self.values.remove(reference.name) }
}

///|
/// Returns the number of stored values.
///
/// This operation has the same `O(N)` cost as `@immut.HashMap::length`.
pub fn AnyImmutableHashMap::length(self : AnyImmutableHashMap) -> Int {
  self.values.length()
}
