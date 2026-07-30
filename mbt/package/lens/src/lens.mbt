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
  priv on_missing : (() -> T)?
}

///|
/// Returns an object lens positioned at the document root.
pub fn root() -> ObjectLens {
  ObjectLens::{
    lens: Lens::{
      pointer: Pointer::root(),
      decoder: object_decoder(),
      on_missing: None,
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
      on_missing: None,
    },
  }
}

///|
/// Returns a string lens positioned at a child property.
pub fn ObjectLens::string(self : ObjectLens, key : String) -> Lens[String] {
  Lens::{
    pointer: self.lens.pointer.key(key),
    decoder: string_decoder(),
    on_missing: None,
  }
}

///|
/// Returns a boolean lens positioned at a child property.
pub fn ObjectLens::bool(self : ObjectLens, key : String) -> Lens[Bool] {
  Lens::{
    pointer: self.lens.pointer.key(key),
    decoder: bool_decoder(),
    on_missing: None,
  }
}

///|
/// Returns a finite-number lens positioned at a child property.
pub fn ObjectLens::number(self : ObjectLens, key : String) -> Lens[Double] {
  Lens::{
    pointer: self.lens.pointer.key(key),
    decoder: number_decoder(),
    on_missing: None,
  }
}

///|
/// Returns an integer lens that delegates conversion to `Double::to_int`.
pub fn ObjectLens::int(self : ObjectLens, key : String) -> Lens[Int] {
  Lens::{
    pointer: self.lens.pointer.key(key),
    decoder: int_decoder(),
    on_missing: None,
  }
}

///|
/// Returns a raw JSON lens positioned at a child property.
pub fn ObjectLens::json(self : ObjectLens, key : String) -> Lens[Json] {
  Lens::{
    pointer: self.lens.pointer.key(key),
    decoder: json_decoder(),
    on_missing: None,
  }
}

///|
/// Returns a lens that decodes every array item with this lens's decoder.
pub fn[T] Lens::array(self : Lens[T]) -> Lens[Array[T]] {
  Lens::{
    pointer: self.pointer,
    decoder: array_decoder(self.decoder),
    on_missing: None,
  }
}

///|
/// Returns `None` for JSON `null` while preserving missing-property errors.
pub fn[T] Lens::nullable(self : Lens[T]) -> Lens[T?] {
  Lens::{
    pointer: self.pointer,
    decoder: nullable_decoder(self.decoder),
    on_missing: None,
  }
}

///|
/// Returns `None` for a missing selected path while rejecting JSON `null`.
pub fn[T] Lens::optional(self : Lens[T]) -> Lens[T?] {
  Lens::{
    pointer: self.pointer,
    decoder: optional_decoder(self.decoder),
    on_missing: Some(() => None),
  }
}

///|
/// Returns `None` for either a missing selected path or JSON `null`.
pub fn[T] Lens::nullish(self : Lens[T]) -> Lens[T?] {
  Lens::{
    pointer: self.pointer,
    decoder: nullable_decoder(self.decoder),
    on_missing: Some(() => None),
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
  let selected = lookup(document, self.pointer) catch {
    LensError(issue) =>
      match (issue.code, self.on_missing) {
        (MissingProperty, Some(on_missing)) =>
          if issue.pointer == self.pointer {
            return on_missing()
          } else {
            raise LensError(issue)
          }
        _ => raise LensError(issue)
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
