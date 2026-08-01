///|
/// The outcome of validating a JSON document with type-erased checks.
///
/// `Valid` carries no decoded value. Use the original typed lenses to read the
/// document after validation succeeds.
pub enum Validation {
  Valid
  Invalid(ReadOnlyArray[Issue])
} derive(Eq, Debug)

///|
/// Runs every lens check and returns all issues in input order.
///
/// This function never constructs or returns application values.
pub fn validate(document : Json, lenses : Array[&LensTrait]) -> Validation {
  let issues : Array[Issue] = []
  for lens in lenses {
    LensTrait::check(lens, document) catch {
      LensError(issue) => issues.push(issue)
    }
  }
  if issues.is_empty() {
    Valid
  } else {
    Invalid(ReadOnlyArray::from_array(issues))
  }
}
