///|
/// A reusable typed reference to one keyed value in an any collection.
///
/// The same reference can be used with both `AnyMutableMap` and
/// `AnyImmutableHashMap`.
pub struct AnyRef[K, T] {
  key : K
  priv encode : (T) -> @any.Any
  priv decode : (@any.Any) -> T?
}

///|
/// Creates a typed reference for `key`.
///
/// Callers should define one shared reference per key and value type. Creating
/// references with the same key but different value types makes mismatched
/// reads return `None`.
pub fn[K, T : @any.Anyable] AnyRef::AnyRef(key : K) -> AnyRef[K, T] {
  {
    key,
    encode: value => @any.Any::Any(value),
    decode: value =>
      try {
        Some((value.dyn_cast() : T))
      } catch {
        _ => None
      },
  }
}
