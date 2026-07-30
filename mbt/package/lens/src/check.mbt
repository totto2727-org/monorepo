///|
/// A type-erased lens read used only for aggregate validation.
pub(open) trait LensTrait {
  fn check(Self, Json) -> Unit raise LensError
}

///|
/// Erases this lens's successful value while preserving its typed failure.
pub impl[T] LensTrait for Lens[T] with fn check(self, document) {
  self.get(document) |> ignore
}

///|
/// Erases this object lens's successful value while preserving its failure.
pub impl LensTrait for ObjectLens with fn check(self, document) {
  self.get(document) |> ignore
}
