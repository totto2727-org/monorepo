///|
/// An immutable hash map of dynamically typed values accessed through
/// `AnyRef`.
pub(all) struct AnyImmutableHashMap[K] {
  map : @immut.HashMap[K, @any.Any]
}

///|
/// Creates an immutable any hash map from key-value pairs.
pub fn[K : Hash + Eq] AnyImmutableHashMap::AnyImmutableHashMap(
  entries : ArrayView[(K, @any.Any)],
) -> AnyImmutableHashMap[K] {
  { map: @immut.HashMap::HashMap(entries) }
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
/// returns `None` or raises the conversion error, respectively.
pub fn[K : Hash + Eq, T] AnyImmutableHashMap::get(
  self : AnyImmutableHashMap[K],
  reference : AnyRef[K, T],
) -> T? raise {
  match self.map.get(reference.key) {
    Some(value) => Some((reference.decode)(value))
    None => None
  }
}

///|
/// Returns the selected value, replacing a missing key or conversion error with
/// `default`.
pub fn[K : Hash + Eq, T] AnyImmutableHashMap::get_or(
  self : AnyImmutableHashMap[K],
  reference : AnyRef[K, T],
  default : T,
) -> T {
  try self.get(reference).unwrap_or(default) catch {
    _ => default
  }
}

///|
/// Returns the selected value, replacing a conversion error with `None`.
pub fn[K : Hash + Eq, T] AnyImmutableHashMap::get_or_none(
  self : AnyImmutableHashMap[K],
  reference : AnyRef[K, T],
) -> T? {
  try self.get(reference) catch {
    _ => None
  }
}
