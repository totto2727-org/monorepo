///|
/// A mutable map of named dynamically typed values accessed through `AnyRef`.
pub struct AnyMutableMap {
  priv values : Map[String, @any.Any]
}

///|
/// Creates an empty mutable any map.
pub fn AnyMutableMap::AnyMutableMap() -> AnyMutableMap {
  { values: Map([]) }
}

///|
/// Associates `value` with `reference`, replacing an existing value.
pub fn[T] AnyMutableMap::set(
  self : AnyMutableMap,
  reference : AnyRef[T],
  value : T,
) -> Unit {
  self.values[reference.name] = (reference.encode)(value)
}

///|
/// Returns the value selected by `reference` when it exists with type `T`.
///
/// A missing name or a value stored through a differently typed reference
/// returns `None`.
pub fn[T] AnyMutableMap::get(
  self : AnyMutableMap,
  reference : AnyRef[T],
) -> T? {
  match self.values.get(reference.name) {
    Some(value) => (reference.decode)(value)
    None => None
  }
}

///|
/// Returns whether a value is associated with `reference`'s name.
pub fn[T] AnyMutableMap::contains(
  self : AnyMutableMap,
  reference : AnyRef[T],
) -> Bool {
  self.values.contains(reference.name)
}

///|
/// Removes the value associated with `reference`'s name when present.
pub fn[T] AnyMutableMap::remove(
  self : AnyMutableMap,
  reference : AnyRef[T],
) -> Unit {
  self.values.remove(reference.name)
}

///|
/// Returns the number of stored values.
pub fn AnyMutableMap::length(self : AnyMutableMap) -> Int {
  self.values.length()
}

///|
/// Returns whether this map contains no values.
pub fn AnyMutableMap::is_empty(self : AnyMutableMap) -> Bool {
  self.values.is_empty()
}
