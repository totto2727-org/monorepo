///|
/// A type-erased lens used for aggregate validation and JSON Schema generation.
pub trait LensTrait {
  fn check(Self, Json) -> Unit raise LensError
  fn to_json_schema(Self) -> Json
}

///|
/// Erases this lens's successful value while preserving its typed failure.
pub impl[T] LensTrait for Lens[T] with fn check(self, document) {
  self.get(document) |> ignore
}

///|
pub impl[T] LensTrait for Lens[T] with fn to_json_schema(self) {
  self.schema_fragment()
}

///|
/// Erases this object lens's successful value while preserving its failure.
pub impl LensTrait for ObjectLens with fn check(self, document) {
  self.get(document) |> ignore
}

///|
pub impl LensTrait for ObjectLens with fn to_json_schema(self) {
  self.lens.schema_fragment()
}
