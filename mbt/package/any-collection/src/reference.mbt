///|
/// A reusable typed reference to one keyed value in an any collection.
///
/// The same reference can be used with both `AnyMutableMap` and
/// `AnyImmutableHashMap`.
pub struct AnyRef[K, T] {
  key : K
  priv encode : (T) -> @any.Any
  priv decode : (@any.Any) -> T raise
}

///|
/// Creates a typed reference for `key`.
///
/// Callers should define one shared reference per key and value type. Creating
/// references with the same key but different value types makes mismatched
/// reads raise the conversion error unless a fallback getter is used.
pub fn[K, T : @any.Anyable] AnyRef::AnyRef(key : K) -> AnyRef[K, T] {
  {
    key,
    encode: value => @any.Any::Any(value),
    decode: value => (value.dyn_cast() : T),
  }
}

///|
/// Creates a key-value entry for collection initialization.
pub fn[K, T] AnyRef::entry(
  self : AnyRef[K, T],
  value : T,
) -> (K, @any.Any) {
  (self.key, (self.encode)(value))
}
