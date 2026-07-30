///|
/// A type-erased lens read used only to validate success or failure.
pub struct Check {
  priv run_ : (Json) -> Unit raise LensError
}

///|
/// Erases this lens's successful value while preserving its typed failure.
pub fn[T] Lens::check(self : Lens[T]) -> Check {
  Check::{
    run_: fn(document) -> Unit raise LensError { self.get(document) |> ignore },
  }
}
