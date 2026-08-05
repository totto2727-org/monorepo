///|
/// Describes values that can produce an independent logical copy.
///
/// Implementations for composite values recursively copy their contents. An
/// implementation may share immutable internal storage when doing so cannot
/// expose mutation through the returned value.
///
/// This trait is open so downstream value types can define their own copy
/// semantics.
pub(open) trait Copy {
  fn copy(Self) -> Self
}

///|
pub impl Copy for Unit with fn copy(self) {
  self
}

///|
pub impl Copy for Bool with fn copy(self) {
  self
}

///|
pub impl Copy for Byte with fn copy(self) {
  self
}

///|
pub impl Copy for Char with fn copy(self) {
  self
}

///|
pub impl Copy for Int16 with fn copy(self) {
  self
}

///|
pub impl Copy for Int with fn copy(self) {
  self
}

///|
pub impl Copy for Int64 with fn copy(self) {
  self
}

///|
pub impl Copy for UInt16 with fn copy(self) {
  self
}

///|
pub impl Copy for UInt with fn copy(self) {
  self
}

///|
pub impl Copy for UInt64 with fn copy(self) {
  self
}

///|
pub impl Copy for Float with fn copy(self) {
  self
}

///|
pub impl Copy for Double with fn copy(self) {
  self
}

///|
pub impl Copy for BigInt with fn copy(self) {
  self
}

///|
pub impl Copy for String with fn copy(self) {
  self
}

///|
pub impl Copy for Bytes with fn copy(self) {
  self
}

///|
pub impl[T : Copy] Copy for T? with fn copy(self) {
  match self {
    None => None
    Some(value) => Some(Copy::copy(value))
  }
}

///|
pub impl[Value : Copy, CopyError : Copy] Copy for Result[Value, CopyError] with fn copy(
  self,
) {
  match self {
    Ok(value) => Ok(Copy::copy(value))
    Err(error) => Err(Copy::copy(error))
  }
}

///|
pub impl[T : Copy] Copy for Array[T] with fn copy(self) {
  self.map(value => Copy::copy(value))
}

///|
pub impl[T : Copy] Copy for FixedArray[T] with fn copy(self) {
  self.map(value => Copy::copy(value))
}

///|
pub impl[T : Copy] Copy for ReadOnlyArray[T] with fn copy(self) {
  ReadOnlyArray::from_iter(self.iter().map(value => Copy::copy(value)))
}

///|
pub impl[Key : Hash + Eq + Copy, Value : Copy] Copy for Map[Key, Value] with fn copy(
  self,
) {
  Map::from_iter(
    self
    .iter()
    .map(entry => {
      let (key, value) = entry
      (Copy::copy(key), Copy::copy(value))
    }),
  )
}

///|
pub impl[First : Copy, Second : Copy] Copy for (First, Second) with fn copy(
  self,
) {
  let (first, second) = self
  (Copy::copy(first), Copy::copy(second))
}

///|
pub impl[First : Copy, Second : Copy, Third : Copy] Copy for (
  First,
  Second,
  Third,
) with fn copy(self) {
  let (first, second, third) = self
  (Copy::copy(first), Copy::copy(second), Copy::copy(third))
}
