///|
priv suberror DecodeProblem {
  Structured(pointer~ : Pointer, code~ : IssueCode, message~ : String?)
  External(pointer~ : Pointer, error~ : @json.JsonDecodeError)
}

///|
struct Decoder[T] {
  decode_ : (Json, @json.JsonPath?) -> T raise DecodeProblem
}

///|
fn[T] Decoder::decode(
  self : Decoder[T],
  value : Json,
  path : @json.JsonPath?,
) -> T raise DecodeProblem {
  (self.decode_)(value, path)
}

///|
fn type_mismatch(expected : JsonKind, value : Json) -> DecodeProblem {
  Structured(
    pointer=Pointer::root(),
    code=IssueCode::TypeMismatch(expected~, actual=json_kind(value)),
    message=None,
  )
}

///|
fn string_decoder() -> Decoder[String] {
  Decoder::{
    decode_: fn(value, _path) -> String raise DecodeProblem {
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
    decode_: fn(value, _path) -> Bool raise DecodeProblem {
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
    decode_: fn(value, _path) -> Double raise DecodeProblem {
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
    decode_: fn(value, _path) -> Int raise DecodeProblem {
      match value {
        Json::Number(number, ..) => number.to_int()
        _ => raise type_mismatch(JsonKind::Number, value)
      }
    },
  }
}

///|
fn json_decoder() -> Decoder[Json] {
  Decoder::{ decode_: fn(value, _path) { value } }
}

///|
fn object_decoder() -> Decoder[Map[String, Json]] {
  Decoder::{
    decode_: fn(value, _path) -> Map[String, Json] raise DecodeProblem {
      match value {
        Json::Object(properties) => properties.copy()
        _ => raise type_mismatch(JsonKind::Object, value)
      }
    },
  }
}

///|
fn[T : @json.FromJson] custom_decoder() -> Decoder[T] {
  Decoder::{
    decode_: fn(value, path) -> T raise DecodeProblem {
      @json.from_json(value, path?) catch {
        error => raise External(pointer=Pointer::root(), error~)
      }
    },
  }
}

///|
fn[T] array_decoder(item_decoder : Decoder[T]) -> Decoder[Array[T]] {
  Decoder::{
    decode_: fn(value, path) -> Array[T] raise DecodeProblem {
      match value {
        Json::Array(items) =>
          items.mapi((index, item) => {
            let item_path = match path {
              Some(path) => Some(path.add_index(index))
              None => None
            }
            item_decoder.decode(item, item_path) catch {
              Structured(pointer~, code~, message~) =>
                raise Structured(
                  pointer=pointer.prepend_index(index),
                  code~,
                  message~,
                )
              External(pointer~, error~) =>
                raise External(pointer=pointer.prepend_index(index), error~)
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
    decode_: fn(value, path) -> T? raise DecodeProblem {
      match value {
        Json::Null => None
        _ => Some(decoder.decode(value, path))
      }
    },
  }
}

///|
fn DecodeProblem::json_decode_error(
  self : DecodeProblem,
  path : @json.JsonPath,
) -> @json.JsonDecodeError {
  match self {
    Structured(pointer~, code~, message~) => {
      let issue = Issue::{ pointer, code, message }
      pointer.json_decode_error(path, repr(LensError(issue)))
    }
    External(error~, pointer=_) => error
  }
}
