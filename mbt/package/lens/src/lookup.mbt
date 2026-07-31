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
fn lookup(document : Json, pointer : Pointer) -> Json? raise LensError {
  let mut current = document
  for segment_index, segment in pointer.segments {
    match segment {
      Key(key) => {
        guard current is Json::Object(properties) else {
          raise LensError(Issue::{
            pointer: pointer.prefix(segment_index),
            code: TypeMismatch(
              expected=JsonKind::Object,
              actual=json_kind(current),
            ),
            message: None,
          })
        }
        guard properties.get(key) is Some(value) else {
          let depth = segment_index + 1
          if depth == pointer.length() {
            return None
          }
          raise LensError(Issue::{
            pointer: pointer.prefix(depth),
            code: MissingProperty,
            message: None,
          })
        }
        current = value
      }
      Index(index) => {
        guard current is Json::Array(items) else {
          raise LensError(Issue::{
            pointer: pointer.prefix(segment_index),
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
            pointer: pointer.prefix(segment_index + 1),
            code: IndexOutOfBounds(index~, length~),
            message: None,
          })
        }
        current = items[index]
      }
    }
  }
  Some(current)
}
