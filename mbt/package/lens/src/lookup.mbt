///|
fn json_kind(value : Json) -> JsonKind {
  match value {
    Json::Null => JsonKind::Null
    Json::True | Json::False => JsonKind::Boolean
    Json::Number(_, ..) => JsonKind::Number
    Json::String(_) => JsonKind::String
    Json::Array(_) => JsonKind::Array
    Json::Object(_) => JsonKind::Object
  }
}

///|
fn lookup(document : Json, pointer : Pointer) -> Json raise LensError {
  let mut current = document
  let mut traversed = Pointer::root()
  for segment in pointer.segments {
    match segment {
      Key(key) => {
        guard current is Json::Object(properties) else {
          raise LensError(Issue::{
            pointer: traversed,
            code: TypeMismatch(
              expected=JsonKind::Object,
              actual=json_kind(current),
            ),
            message: None,
          })
        }
        traversed = traversed.key(key)
        guard properties.get(key) is Some(value) else {
          raise LensError(Issue::{
            pointer: traversed,
            code: MissingProperty,
            message: None,
          })
        }
        current = value
      }
      Index(index) => {
        guard current is Json::Array(items) else {
          raise LensError(Issue::{
            pointer: traversed,
            code: TypeMismatch(
              expected=JsonKind::Array,
              actual=json_kind(current),
            ),
            message: None,
          })
        }
        let length = items.length()
        guard index >= 0 && index < length else {
          raise LensError(Issue::{
            pointer: traversed.index(index),
            code: IndexOutOfBounds(index~, length~),
            message: None,
          })
        }
        traversed = traversed.index(index)
        current = items[index]
      }
    }
  }
  current
}
