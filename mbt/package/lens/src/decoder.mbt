///|
priv suberror DecodeProblem {
  DecodeProblem(Pointer, IssueCode, String?)
}

///|
struct Decoder[T] {
  decode_ : (Json) -> T raise DecodeProblem
  decode_with_path_ : ((Json, @json.JsonPath) -> T raise @json.JsonDecodeError)?
}

///|
fn[T] Decoder::decode(self : Decoder[T], value : Json) -> T raise DecodeProblem {
  (self.decode_)(value)
}

///|
fn[T] Decoder::decode_with_path(
  self : Decoder[T],
  value : Json,
  path : @json.JsonPath,
) -> T raise @json.JsonDecodeError {
  match self.decode_with_path_ {
    Some(decode) => decode(value, path)
    None =>
      self.decode(value) catch {
        DecodeProblem(pointer, code, message) => {
          let issue = Issue::{ pointer, code, message }
          raise pointer.json_decode_error(path, repr(LensError(issue)))
        }
      }
  }
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
    decode_with_path_: None,
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
    decode_with_path_: None,
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
    decode_with_path_: None,
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
    decode_with_path_: None,
  }
}

///|
fn json_decoder() -> Decoder[Json] {
  Decoder::{ decode_: fn(value) { value }, decode_with_path_: None }
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
    decode_with_path_: None,
  }
}

///|
fn[T : @json.FromJson] custom_decoder() -> Decoder[T] {
  Decoder::{
    decode_: fn(value) -> T raise DecodeProblem {
      @json.from_json(value) catch {
        @json.JsonDecodeError::JsonDecodeError((path, message)) =>
          raise DecodeProblem(
            Pointer::root(),
            ExternalDecode,
            Some("\{path}: \{message}"),
          )
      }
    },
    decode_with_path_: Some(fn(value, path) -> T raise @json.JsonDecodeError {
      @json.from_json(value, path~)
    }),
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
    decode_with_path_: match item_decoder.decode_with_path_ {
      Some(_) =>
        Some(fn(value, path) -> Array[T] raise @json.JsonDecodeError {
          match value {
            Json::Array(items) =>
              items.mapi((index, item) => {
                item_decoder.decode_with_path(item, path.add_index(index))
              })
            _ =>
              raise type_mismatch(JsonKind::Array, value).json_decode_error(
                path,
              )
          }
        })
      None => None
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
    decode_with_path_: match decoder.decode_with_path_ {
      Some(_) =>
        Some(fn(value, path) -> T? raise @json.JsonDecodeError {
          match value {
            Json::Null => None
            _ => Some(decoder.decode_with_path(value, path))
          }
        })
      None => None
    },
  }
}

///|
fn DecodeProblem::json_decode_error(
  self : DecodeProblem,
  path : @json.JsonPath,
) -> @json.JsonDecodeError {
  let DecodeProblem(pointer, code, message) = self
  let issue = Issue::{ pointer, code, message }
  pointer.json_decode_error(path, repr(LensError(issue)))
}
