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
fn number_out_of_range(target : String) -> DecodeProblem {
  DecodeProblem(IssueCode::NumberOutOfRange(target~), None)
}

///|
fn number_decoder() -> Decoder[Double] {
  Decoder::{
    decode_: fn(value) -> Double raise DecodeProblem {
      match value {
        Json::Number(number, ..) => {
          guard !number.is_nan() && !number.is_inf() else {
            raise number_out_of_range("Double")
          }
          number
        }
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
        Json::Number(number, ..) => {
          guard !number.is_nan() &&
            !number.is_inf() &&
            number >= @int.MIN_VALUE.to_double() &&
            number <= @int.MAX_VALUE.to_double() else {
            raise number_out_of_range("Int")
          }
          let integer = number.to_int()
          guard integer.to_double() == number else {
            raise DecodeProblem(IssueCode::InvalidInteger, None)
          }
          integer
        }
        _ => raise type_mismatch(JsonKind::Number, value)
      }
    },
  }
}

///|
fn json_decoder() -> Decoder[Json] {
  Decoder::{ decode_: fn(value) { value } }
}
