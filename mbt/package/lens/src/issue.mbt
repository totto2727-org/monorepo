///|
/// The JSON value category used by structured lens diagnostics.
pub(all) enum JsonKind {
  Null
  Boolean
  Number
  String
  Array
  Object
} derive(Eq, Debug)

///|
/// A machine-readable reason why a lens or validation check failed.
pub(all) enum IssueCode {
  MissingProperty
  TypeMismatch(expected~ : JsonKind, actual~ : JsonKind)
  IndexOutOfBounds(index~ : Int, length~ : Int)
  ConstraintViolation(code~ : String)
  ExternalDecode
} derive(Eq, Debug)

///|
/// A structured diagnostic containing the exact pointer and failure reason.
pub(all) struct Issue {
  pointer : Pointer
  code : IssueCode
  message : String?
} derive(Eq, Debug)

///|
/// The typed error raised when a lens cannot read its selected value.
pub(all) suberror LensError {
  LensError(Issue)
} derive(Eq, Debug)
