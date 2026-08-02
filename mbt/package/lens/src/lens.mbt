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
  priv on_missing : (() -> T)?
  priv schema_shape : SchemaShape
  priv schema_required : Bool
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
      on_missing: None,
      schema_shape: ObjectSchema,
      schema_required: true,
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
      on_missing: None,
      schema_shape: ObjectSchema,
      schema_required: true,
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
    on_missing: None,
    schema_shape: StringSchema,
    schema_required: true,
  }
}

///|
/// Returns a boolean lens positioned at a child property.
pub fn ObjectLens::bool(self : ObjectLens, key : String) -> Lens[Bool] {
  Lens::{
    pointer: self.lens.pointer.key(key),
    decoder: bool_decoder(),
    encoder: bool_encoder(),
    on_missing: None,
    schema_shape: BooleanSchema,
    schema_required: true,
  }
}

///|
/// Returns a finite-number lens positioned at a child property.
pub fn ObjectLens::number(self : ObjectLens, key : String) -> Lens[Double] {
  Lens::{
    pointer: self.lens.pointer.key(key),
    decoder: number_decoder(),
    encoder: number_encoder(),
    on_missing: None,
    schema_shape: NumberSchema,
    schema_required: true,
  }
}

///|
/// Returns an integer lens that delegates conversion to `Double::to_int`.
pub fn ObjectLens::int(self : ObjectLens, key : String) -> Lens[Int] {
  Lens::{
    pointer: self.lens.pointer.key(key),
    decoder: int_decoder(),
    encoder: int_encoder(),
    on_missing: None,
    // The decoder accepts every JSON number and applies Double::to_int.
    schema_shape: NumberSchema,
    schema_required: true,
  }
}

///|
/// Returns a raw JSON lens positioned at a child property.
pub fn ObjectLens::json(self : ObjectLens, key : String) -> Lens[Json] {
  Lens::{
    pointer: self.lens.pointer.key(key),
    decoder: json_decoder(),
    encoder: json_encoder(),
    on_missing: None,
    schema_shape: AnySchema,
    schema_required: true,
  }
}

///|
/// Returns a lens that decodes every array item with this lens's decoder.
pub fn[T] Lens::array(self : Lens[T]) -> Lens[Array[T]] {
  Lens::{
    pointer: self.pointer,
    decoder: array_decoder(self.decoder),
    encoder: array_encoder(self.encoder),
    on_missing: None,
    schema_shape: ArraySchema(self.schema_shape),
    schema_required: true,
  }
}

///|
/// Returns `None` for JSON `null` while preserving missing-property errors.
pub fn[T] Lens::nullable(self : Lens[T]) -> Lens[T?] {
  Lens::{
    pointer: self.pointer,
    decoder: nullable_decoder(self.decoder),
    encoder: nullable_encoder(self.encoder),
    on_missing: None,
    schema_shape: self.schema_shape.nullable(),
    schema_required: true,
  }
}

///|
/// Returns `None` for a missing selected path while rejecting JSON `null`.
pub fn[T] Lens::optional(self : Lens[T]) -> Lens[T?] {
  Lens::{
    pointer: self.pointer,
    decoder: optional_decoder(self.decoder),
    encoder: optional_encoder(self.encoder),
    on_missing: Some(() => None),
    schema_shape: self.schema_shape,
    schema_required: false,
  }
}

///|
/// Returns `None` for either a missing selected path or JSON `null`.
///
/// `None` is omitted by default. Pass `encode_mode=Null` to write JSON `null` instead.
pub fn[T] Lens::nullish(
  self : Lens[T],
  encode_mode? : NullishEncodeMode,
) -> Lens[T?] {
  Lens::{
    pointer: self.pointer,
    decoder: nullable_decoder(self.decoder),
    encoder: match encode_mode {
      Some(Null) => nullable_encoder(self.encoder)
      Some(Omit) | None => optional_encoder(self.encoder)
    },
    on_missing: Some(() => None),
    schema_shape: self.schema_shape.nullable(),
    schema_required: false,
  }
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
    None => {
      match self.on_missing {
        Some(on_missing) => return on_missing()
        None => ()
      }
      raise LensError(Issue::{
        pointer: self.pointer,
        code: MissingProperty,
        message: None,
      })
    }
  }
  self.decoder.decode(selected) catch {
    DecodeProblem(pointer, code, message) =>
      raise LensError(Issue::{
        pointer: self.pointer.append(pointer),
        code,
        message,
      })
  }
}
