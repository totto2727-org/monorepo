///|
/// A location in a JSON document from which typed child lenses can be created.
pub struct ObjectLens {
  priv lens : Lens[Map[String, Json]]
}

///|
/// A reusable typed accessor for one location in a JSON document.
pub struct Lens[T] {
  priv pointer : Pointer
  priv decoder : Decoder[T]
  priv encoder : Encoder[T]
}

///|
/// A typed accessor whose missing and `null` behavior can be replaced without nesting options.
pub struct PresenceLens[T] {
  priv lens : Lens[T]
  priv mode : PresenceMode
}

///|
priv enum PresenceMode {
  Nullable
  Optional
  Nullish(NullishEncodeMode)
}

///|
/// Controls how a `nullish` lens encodes `None`.
pub(all) enum NullishEncodeMode {
  Omit
  Null
} derive(Eq, Debug)

///|
/// Returns an object lens positioned at the document root.
pub fn root() -> ObjectLens {
  ObjectLens::{
    lens: Lens::{
      pointer: Pointer::root(),
      decoder: object_decoder(),
      encoder: object_encoder(),
    },
  }
}

///|
/// Returns an object lens positioned at a root property.
pub fn object(key : String) -> ObjectLens {
  root().object(key)
}

///|
/// Returns an object lens positioned at a child property.
pub fn ObjectLens::object(self : ObjectLens, key : String) -> ObjectLens {
  ObjectLens::{
    lens: Lens::{
      pointer: self.lens.pointer.key(key),
      decoder: object_decoder(),
      encoder: object_encoder(),
    },
  }
}

///|
/// Returns a string lens positioned at a child property.
pub fn ObjectLens::string(self : ObjectLens, key : String) -> Lens[String] {
  Lens::{
    pointer: self.lens.pointer.key(key),
    decoder: string_decoder(),
    encoder: string_encoder(),
  }
}

///|
/// Returns a boolean lens positioned at a child property.
pub fn ObjectLens::bool(self : ObjectLens, key : String) -> Lens[Bool] {
  Lens::{
    pointer: self.lens.pointer.key(key),
    decoder: bool_decoder(),
    encoder: bool_encoder(),
  }
}

///|
/// Returns a finite-number lens positioned at a child property.
pub fn ObjectLens::number(self : ObjectLens, key : String) -> Lens[Double] {
  Lens::{
    pointer: self.lens.pointer.key(key),
    decoder: number_decoder(),
    encoder: number_encoder(),
  }
}

///|
/// Returns an integer lens that delegates conversion to `Double::to_int`.
pub fn ObjectLens::int(self : ObjectLens, key : String) -> Lens[Int] {
  Lens::{
    pointer: self.lens.pointer.key(key),
    decoder: int_decoder(),
    encoder: int_encoder(),
  }
}

///|
/// Returns a raw JSON lens positioned at a child property.
pub fn ObjectLens::json(self : ObjectLens, key : String) -> Lens[Json] {
  Lens::{
    pointer: self.lens.pointer.key(key),
    decoder: json_decoder(),
    encoder: json_encoder(),
  }
}

///|
/// Returns a lens that decodes every array item with this lens's decoder.
pub fn[T] Lens::array(self : Lens[T]) -> Lens[Array[T]] {
  Lens::{
    pointer: self.pointer,
    decoder: array_decoder(self.decoder),
    encoder: array_encoder(self.encoder),
  }
}

///|
/// Returns `None` for JSON `null` while preserving missing-property errors.
pub fn[T] Lens::nullable(self : Lens[T]) -> PresenceLens[T] {
  PresenceLens::{ lens: self, mode: Nullable }
}

///|
/// Returns `None` for a missing selected path while rejecting JSON `null`.
pub fn[T] Lens::optional(self : Lens[T]) -> PresenceLens[T] {
  PresenceLens::{ lens: self, mode: Optional }
}

///|
/// Returns `None` for either a missing selected path or JSON `null`.
///
/// `None` is omitted by default. Pass `encode_mode=Null` to write JSON `null` instead.
pub fn[T] Lens::nullish(
  self : Lens[T],
  encode_mode? : NullishEncodeMode,
) -> PresenceLens[T] {
  PresenceLens::{ lens: self, mode: Nullish(encode_mode.unwrap_or(Omit)) }
}

///|
/// Replaces the current presence policy with nullable semantics.
pub fn[T] PresenceLens::nullable(self : PresenceLens[T]) -> PresenceLens[T] {
  PresenceLens::{ lens: self.lens, mode: Nullable }
}

///|
/// Replaces the current presence policy with optional semantics.
pub fn[T] PresenceLens::optional(self : PresenceLens[T]) -> PresenceLens[T] {
  PresenceLens::{ lens: self.lens, mode: Optional }
}

///|
/// Replaces the current presence policy with nullish semantics.
pub fn[T] PresenceLens::nullish(
  self : PresenceLens[T],
  encode_mode? : NullishEncodeMode,
) -> PresenceLens[T] {
  PresenceLens::{ lens: self.lens, mode: Nullish(encode_mode.unwrap_or(Omit)) }
}

///|
/// Returns a lens that treats every array item as nullable.
pub fn[T] PresenceLens::array(self : PresenceLens[T]) -> Lens[Array[T?]] {
  Lens::{
    pointer: self.lens.pointer,
    decoder: array_decoder(nullable_decoder(self.lens.decoder)),
    encoder: array_encoder(nullable_encoder(self.lens.encoder)),
  }
}

///|
/// Appends this lens's pointer to an existing JSON path.
pub fn[T] Lens::add_to_json_path(
  self : Lens[T],
  path : @json.JsonPath,
) -> @json.JsonPath {
  self.pointer.add_to_json_path(path)
}

///|
/// Appends this lens's pointer to an existing JSON path.
pub fn[T] PresenceLens::add_to_json_path(
  self : PresenceLens[T],
  path : @json.JsonPath,
) -> @json.JsonPath {
  self.lens.pointer.add_to_json_path(path)
}

///|
/// Creates a standard JSON decode error at this lens's location under an existing path.
pub fn[T] Lens::json_decode_error(
  self : Lens[T],
  path : @json.JsonPath,
  message : String,
) -> @json.JsonDecodeError {
  self.pointer.json_decode_error(path, message)
}

///|
/// Creates a standard JSON decode error at this lens's location under an existing path.
pub fn[T] PresenceLens::json_decode_error(
  self : PresenceLens[T],
  path : @json.JsonPath,
  message : String,
) -> @json.JsonDecodeError {
  self.lens.pointer.json_decode_error(path, message)
}

///|
/// Reads this object lens from a JSON document.
pub fn ObjectLens::get(
  self : ObjectLens,
  document : Json,
) -> Map[String, Json] raise LensError {
  self.lens.get(document)
}

///|
/// Reads and decodes this lens from a JSON document.
pub fn[T] Lens::get(self : Lens[T], document : Json) -> T raise LensError {
  let selected = match lookup(document, self.pointer) {
    Some(value) => value
    None => raise missing_property(self.pointer)
  }
  self.decode_selected(selected)
}

///|
fn missing_property(pointer : Pointer) -> LensError {
  LensError(Issue::{ pointer, code: MissingProperty, message: None })
}

///|
fn[T] Lens::decode_selected(
  self : Lens[T],
  selected : Json,
) -> T raise LensError {
  self.decoder.decode(selected) catch {
    DecodeProblem(pointer, code, message) =>
      raise LensError(Issue::{
        pointer: self.pointer.append(pointer),
        code,
        message,
      })
  }
}

///|
/// Reads and decodes this presence-aware lens from a JSON document.
pub fn[T] PresenceLens::get(
  self : PresenceLens[T],
  document : Json,
) -> T? raise LensError {
  match self.mode {
    Optional => {
      let selected = match lookup(document, self.lens.pointer) {
        Some(value) => value
        None => return None
      }
      Some(self.lens.decode_selected(selected))
    }
    Nullable => {
      let selected = match lookup(document, self.lens.pointer) {
        Some(value) => value
        None => raise missing_property(self.lens.pointer)
      }
      match selected {
        Json::Null => None
        _ => Some(self.lens.decode_selected(selected))
      }
    }
    Nullish(_) => {
      let selected = match lookup(document, self.lens.pointer) {
        Some(value) => value
        None => return None
      }
      match selected {
        Json::Null => None
        _ => Some(self.lens.decode_selected(selected))
      }
    }
  }
}

///|
/// Reads this lens and translates a lens failure into a standard JSON decode error.
pub fn[T] Lens::get_or_json_decode_error(
  self : Lens[T],
  document : Json,
  path : @json.JsonPath,
) -> T raise @json.JsonDecodeError {
  self.get(document) catch {
    LensError(issue) =>
      raise issue.pointer.json_decode_error(path, repr(LensError(issue)))
  }
}

///|
/// Selects raw JSON and delegates its typed decoding to the standard `FromJson` implementation.
pub fn[T : @json.FromJson] Lens::decode_from_json(
  self : Lens[Json],
  document : Json,
  path : @json.JsonPath,
) -> T raise @json.JsonDecodeError {
  @json.from_json(
    self.get_or_json_decode_error(document, path),
    path=self.add_to_json_path(path),
  )
}

///|
/// Reads this lens and translates a lens failure into a standard JSON decode error.
pub fn[T] PresenceLens::get_or_json_decode_error(
  self : PresenceLens[T],
  document : Json,
  path : @json.JsonPath,
) -> T? raise @json.JsonDecodeError {
  self.get(document) catch {
    LensError(issue) =>
      raise issue.pointer.json_decode_error(path, repr(LensError(issue)))
  }
}
