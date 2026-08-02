///|
struct Encoder[T] {
  encode_ : (T) -> Json
}

///|
fn[T] Encoder::encode(self : Encoder[T], value : T) -> Json {
  (self.encode_)(value)
}

///|
fn string_encoder() -> Encoder[String] {
  Encoder::{ encode_: value => Json::string(value) }
}

///|
fn bool_encoder() -> Encoder[Bool] {
  Encoder::{ encode_: value => Json::boolean(value) }
}

///|
fn number_encoder() -> Encoder[Double] {
  Encoder::{ encode_: value => Json::number(value) }
}

///|
fn int_encoder() -> Encoder[Int] {
  Encoder::{ encode_: value => Json::number(value.to_double()) }
}

///|
fn json_encoder() -> Encoder[Json] {
  Encoder::{ encode_: value => value }
}

///|
fn object_encoder() -> Encoder[Map[String, Json]] {
  Encoder::{ encode_: value => Json::object(value.copy()) }
}

///|
fn[T] array_encoder(item_encoder : Encoder[T]) -> Encoder[Array[T]] {
  Encoder::{
    encode_: items => Json::array(items.map(item => item_encoder.encode(item))),
  }
}

///|
fn[T] nullable_encoder(encoder : Encoder[T]) -> Encoder[T?] {
  Encoder::{
    encode_: value => {
      match value {
        Some(value) => encoder.encode(value)
        None => Json::null()
      }
    },
  }
}
