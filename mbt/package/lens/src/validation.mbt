///|
/// The outcome of validating a JSON document with type-erased checks.
///
/// `Valid` carries no decoded value. Use the original typed lenses to read the
/// document after validation succeeds.
pub enum Validation {
  Valid
  Invalid(Array[Issue])
} derive(Eq, Debug)

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

///|
/// Runs every check and returns all issues in input order.
///
/// This function never constructs or returns application values.
pub fn validate(document : Json, checks : Array[Check]) -> Validation {
  let issues : Array[Issue] = []
  for check in checks {
    (check.run_)(document) catch {
      LensError(issue) => issues.push(issue)
    }
  }
  if issues.is_empty() {
    Valid
  } else {
    Invalid(issues)
  }
}
