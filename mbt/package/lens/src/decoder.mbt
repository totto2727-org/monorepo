///|
priv suberror DecodeProblem {
  DecodeProblem(IssueCode, String?)
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
        Json::Object(properties) => properties
        _ => raise type_mismatch(JsonKind::Object, value)
      }
    },
  }
}
