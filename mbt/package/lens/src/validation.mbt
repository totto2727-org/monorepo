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
