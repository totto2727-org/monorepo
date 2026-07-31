///|
/// Describes values that can produce an independent logical copy.
///
/// Implementations for composite values recursively copy their contents. An
/// implementation may share immutable internal storage when doing so cannot
/// expose mutation through the returned value.
pub(open) trait Copy {
  fn copy(Self) -> Self = _
}

///|
impl Copy with fn copy(self) {
  self
}

///|
pub impl Copy for Unit

///|
pub impl Copy for Bool

///|
pub impl Copy for Byte

///|
pub impl Copy for Char

///|
pub impl Copy for Int16

///|
pub impl Copy for Int

///|
pub impl Copy for Int64

///|
pub impl Copy for UInt16

///|
pub impl Copy for UInt

///|
pub impl Copy for UInt64

///|
pub impl Copy for Float

///|
pub impl Copy for Double

///|
pub impl Copy for BigInt

///|
pub impl Copy for String

///|
pub impl Copy for Bytes

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
