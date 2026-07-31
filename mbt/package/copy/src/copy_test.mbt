///|
priv struct MutableBox {
  mut value : Int
}

///|
impl @copy.Copy for MutableBox with fn copy(self) {
  MutableBox::{ value: self.value }
}

///|
test "Copy::copy - copies an immutable value" {
  inspect(@copy.Copy::copy(42), content="42")
}

///|
test "Copy::copy - recursively copies composite values" {
  let source : Result[FixedArray[Array[Int]]?, String] = Ok(Some([[1]]))
  let copied = @copy.Copy::copy(source)
  match (source, copied) {
    (Ok(Some(source_values)), Ok(Some(copied_values))) => {
      copied_values[0][0] = 2
      debug_inspect(
        (source_values[0][0], copied_values[0][0]),
        content="(1, 2)",
      )
    }
    _ => fail("unexpected copied value")
  }
}

///|
test "MutableBox Copy::copy - uses the type-defined copy policy" {
  let source = MutableBox::{ value: 1 }
  let copied = @copy.Copy::copy(source)
  copied.value = 2
  debug_inspect((source.value, copied.value), content="(1, 2)")
}
