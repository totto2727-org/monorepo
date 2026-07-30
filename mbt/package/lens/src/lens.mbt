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
}

///|
/// Returns an object lens positioned at the document root.
pub fn root() -> ObjectLens {
  ObjectLens::{
    lens: Lens::{ pointer: Pointer::root(), decoder: object_decoder() },
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
    },
  }
}

///|
/// Returns a string lens positioned at a child property.
pub fn ObjectLens::string(self : ObjectLens, key : String) -> Lens[String] {
  Lens::{ pointer: self.lens.pointer.key(key), decoder: string_decoder() }
}

///|
/// Returns a boolean lens positioned at a child property.
pub fn ObjectLens::bool(self : ObjectLens, key : String) -> Lens[Bool] {
  Lens::{ pointer: self.lens.pointer.key(key), decoder: bool_decoder() }
}

///|
/// Returns a finite-number lens positioned at a child property.
pub fn ObjectLens::number(self : ObjectLens, key : String) -> Lens[Double] {
  Lens::{ pointer: self.lens.pointer.key(key), decoder: number_decoder() }
}

///|
/// Returns an integer lens that delegates conversion to `Double::to_int`.
pub fn ObjectLens::int(self : ObjectLens, key : String) -> Lens[Int] {
  Lens::{ pointer: self.lens.pointer.key(key), decoder: int_decoder() }
}

///|
/// Returns a raw JSON lens positioned at a child property.
pub fn ObjectLens::json(self : ObjectLens, key : String) -> Lens[Json] {
  Lens::{ pointer: self.lens.pointer.key(key), decoder: json_decoder() }
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
  let selected = lookup(document, self.pointer)
  self.decoder.decode(selected) catch {
    DecodeProblem(code, message) =>
      raise LensError(Issue::{ pointer: self.pointer, code, message })
  }
}
