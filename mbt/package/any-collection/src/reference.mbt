///|
/// A reusable typed reference to one named value in an any collection.
///
/// The same reference can be used with both `AnyMutableMap` and
/// `AnyImmutableHashMap`.
pub struct AnyRef[T] {
  priv name : String
  priv encode : (T) -> @any.Any
  priv decode : (@any.Any) -> T?
}

///|
/// Creates a typed reference for `name`.
///
/// Callers should define one shared reference per name and value type. Creating
/// references with the same name but different value types makes mismatched
/// reads return `None`.
pub fn[T] AnyRef::AnyRef(name : String) -> AnyRef[T] {
  {
    name,
    encode: value => @any.of(value),
    decode: value => value.try_to(),
  }
}
