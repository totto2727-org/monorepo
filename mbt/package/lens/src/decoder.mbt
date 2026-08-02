///|
priv suberror DecodeProblem {
  DecodeProblem(Pointer, IssueCode, String?)
}

///|
struct Decoder[T] {
  decode_ : (Json) -> T raise DecodeProblem
}

///|
fn[T] Decoder::decode(self : Decoder[T], value : Json) -> T raise DecodeProblem {
  (self.decode_)(value)
}

///|
fn type_mismatch(expected : JsonKind, value : Json) -> DecodeProblem {
  DecodeProblem(
    Pointer::root(),
    IssueCode::TypeMismatch(expected~, actual=json_kind(value)),
    None,
  )
}

///|
fn string_decoder() -> Decoder[String] {
  Decoder::{
    decode_: fn(value) -> String raise DecodeProblem {
      match value {
        Json::String(value) => value
        _ => raise type_mismatch(JsonKind::String, value)
      }
    },
  }
}

///|
fn bool_decoder() -> Decoder[Bool] {
  Decoder::{
    decode_: fn(value) -> Bool raise DecodeProblem {
      match value {
        Json::True => true
        Json::False => false
        _ => raise type_mismatch(JsonKind::Boolean, value)
      }
    },
  }
}

///|
fn number_decoder() -> Decoder[Double] {
  Decoder::{
    decode_: fn(value) -> Double raise DecodeProblem {
      match value {
        Json::Number(number, ..) => number
        _ => raise type_mismatch(JsonKind::Number, value)
      }
    },
  }
}

///|
fn int_decoder() -> Decoder[Int] {
  Decoder::{
    decode_: fn(value) -> Int raise DecodeProblem {
      match value {
        Json::Number(number, ..) => number.to_int()
        _ => raise type_mismatch(JsonKind::Number, value)
      }
    },
  }
}

///|
fn json_decoder() -> Decoder[Json] {
  Decoder::{ decode_: fn(value) { value } }
}

///|
fn object_decoder() -> Decoder[Map[String, Json]] {
  Decoder::{
    decode_: fn(value) -> Map[String, Json] raise DecodeProblem {
      match value {
        Json::Object(properties) => properties.copy()
        _ => raise type_mismatch(JsonKind::Object, value)
      }
    },
  }
}

///|
fn[T] array_decoder(item_decoder : Decoder[T]) -> Decoder[Array[T]] {
  Decoder::{
    decode_: fn(value) -> Array[T] raise DecodeProblem {
      match value {
        Json::Array(items) =>
          items.mapi((index, item) => {
            item_decoder.decode(item) catch {
              DecodeProblem(pointer, code, message) =>
                raise DecodeProblem(pointer.prepend_index(index), code, message)
            }
          })
        _ => raise type_mismatch(JsonKind::Array, value)
      }
    },
  }
}

///|
fn[T] nullable_decoder(decoder : Decoder[T]) -> Decoder[T?] {
  Decoder::{
    decode_: fn(value) -> T? raise DecodeProblem {
      match value {
        Json::Null => None
        _ => Some(decoder.decode(value))
      }
    },
  }
}
