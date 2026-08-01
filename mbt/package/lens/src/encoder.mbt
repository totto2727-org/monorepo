///|
priv suberror EncodeProblem {
  EncodeProblem(Pointer, JsonBuildIssueCode)
}

///|
priv enum EncodedValue {
  Present(Json)
  Omitted
}

///|
struct Encoder[T] {
  encode_ : (T) -> EncodedValue raise EncodeProblem
}

///|
fn[T] Encoder::encode(
  self : Encoder[T],
  value : T,
) -> EncodedValue raise EncodeProblem {
  (self.encode_)(value)
}

///|
fn require_present(encoded : EncodedValue) -> EncodedValue raise EncodeProblem {
  match encoded {
    Present(value) => Present(value)
    Omitted =>
      raise EncodeProblem(
        Pointer::root(),
        JsonBuildIssueCode::OmissionNotAllowed,
      )
  }
}

///|
fn string_encoder() -> Encoder[String] {
  Encoder::{ encode_: value => Present(Json::string(value)) }
}

///|
fn bool_encoder() -> Encoder[Bool] {
  Encoder::{ encode_: value => Present(Json::boolean(value)) }
}

///|
fn number_encoder() -> Encoder[Double] {
  Encoder::{ encode_: value => Present(Json::number(value)) }
}

///|
fn int_encoder() -> Encoder[Int] {
  Encoder::{ encode_: value => Present(Json::number(value.to_double())) }
}

///|
fn json_encoder() -> Encoder[Json] {
  Encoder::{ encode_: value => Present(value) }
}

///|
fn object_encoder() -> Encoder[Map[String, Json]] {
  Encoder::{ encode_: value => Present(Json::object(value.copy())) }
}

///|
fn[T] array_encoder(item_encoder : Encoder[T]) -> Encoder[Array[T]] {
  Encoder::{
    encode_: items => {
      let encoded_items = items.mapi((index, item) => {
        let encoded = item_encoder.encode(item) catch {
          EncodeProblem(pointer, code) =>
            raise EncodeProblem(pointer.prepend_index(index), code)
        }
        match encoded {
          Present(value) => value
          Omitted =>
            raise EncodeProblem(
              Pointer::root().index(index),
              JsonBuildIssueCode::OmissionNotAllowed,
            )
        }
      })
      Present(Json::array(encoded_items))
    },
  }
}

///|
fn[T] nullable_encoder(encoder : Encoder[T]) -> Encoder[T?] {
  Encoder::{
    encode_: value => {
      match value {
        Some(value) => require_present(encoder.encode(value))
        None => Present(Json::null())
      }
    },
  }
}

///|
fn[T] optional_encoder(encoder : Encoder[T]) -> Encoder[T?] {
  Encoder::{
    encode_: value => {
      match value {
        Some(value) => require_present(encoder.encode(value))
        None => Omitted
      }
    },
  }
}
