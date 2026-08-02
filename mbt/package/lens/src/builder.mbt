///|
/// A machine-readable reason why a typed value could not be written to a JSON builder.
pub(all) enum JsonBuildIssueCode {
  PathConflict
} derive(Eq, Debug)

///|
/// A structured JSON construction failure at an exact output pointer.
pub(all) struct JsonBuildIssue {
  pointer : Pointer
  code : JsonBuildIssueCode
} derive(Eq, Debug)

///|
/// The typed error raised when a lens cannot write a value to a JSON builder.
pub(all) suberror JsonBuildError {
  JsonBuildError(JsonBuildIssue)
} derive(Eq, Debug)

///|
priv enum BuildNode {
  BuildValue(Json)
  BuildObject(Map[String, BuildNode])
}

///|
/// A mutable object builder populated through typed lenses and serialized with `ToJson`.
pub struct JsonBuilder {
  priv properties : Map[String, BuildNode]
}

///|
/// Creates an empty JSON object builder.
pub fn JsonBuilder::JsonBuilder() -> JsonBuilder {
  JsonBuilder::{ properties: Map([]) }
}

///|
fn build_error(pointer : Pointer, code : JsonBuildIssueCode) -> JsonBuildError {
  JsonBuildError(JsonBuildIssue::{ pointer, code })
}

///|
fn set_build_value(
  properties : Map[String, BuildNode],
  pointer : Pointer,
  segment_index : Int,
  value : Json,
) -> Unit raise JsonBuildError {
  match pointer.segments[segment_index] {
    Key(key) => {
      if segment_index + 1 == pointer.length() {
        properties.set(key, BuildValue(value))
        return
      }
      match properties.get(key) {
        Some(BuildObject(children)) =>
          set_build_value(children, pointer, segment_index + 1, value)
        Some(BuildValue(_)) =>
          raise build_error(
            pointer.prefix(segment_index + 1),
            JsonBuildIssueCode::PathConflict,
          )
        None => {
          let children : Map[String, BuildNode] = Map([])
          set_build_value(children, pointer, segment_index + 1, value)
          properties.set(key, BuildObject(children))
        }
      }
    }
    Index(_) =>
      raise build_error(
        pointer.prefix(segment_index + 1),
        JsonBuildIssueCode::PathConflict,
      )
  }
}

///|
fn remove_build_value(
  properties : Map[String, BuildNode],
  pointer : Pointer,
  segment_index : Int,
) -> Unit {
  match pointer.segments[segment_index] {
    Key(key) => {
      if segment_index + 1 == pointer.length() {
        properties.remove(key)
        return
      }
      match properties.get(key) {
        Some(BuildObject(children)) => {
          remove_build_value(children, pointer, segment_index + 1)
          if children.is_empty() {
            properties.remove(key)
          }
        }
        Some(BuildValue(_)) | None => ()
      }
    }
    Index(_) => ()
  }
}

///|
impl ToJson for BuildNode with fn to_json(self) -> Json {
  match self {
    BuildValue(value) => value
    BuildObject(properties) => properties.to_json()
  }
}

///|
/// Writes a typed value at this lens's output pointer.
///
/// Repeated writes to the same pointer use the latest value. Missing object parents are created. An omitted optional value removes a previous value and prunes empty generated parents.
pub fn[T] Lens::set(
  self : Lens[T],
  builder : JsonBuilder,
  value : T,
) -> Unit raise JsonBuildError {
  set_build_value(
    builder.properties,
    self.pointer,
    0,
    self.encoder.encode(value),
  )
}

///|
/// Writes an optional typed value using this lens's current presence policy.
pub fn[T] PresenceLens::set(
  self : PresenceLens[T],
  builder : JsonBuilder,
  value : T?,
) -> Unit raise JsonBuildError {
  match value {
    Some(value) =>
      set_build_value(
        builder.properties,
        self.lens.pointer,
        0,
        self.lens.encoder.encode(value),
      )
    None =>
      match self.mode {
        Nullable | Nullish(Null) =>
          set_build_value(
            builder.properties,
            self.lens.pointer,
            0,
            Json::null(),
          )
        Optional | Nullish(Omit) =>
          remove_build_value(builder.properties, self.lens.pointer, 0)
      }
  }
}

///|
/// Writes a typed value for an infallible serialization contract.
///
/// Use this from `ToJson::to_json`, whose trait signature cannot propagate `JsonBuildError`. A failure indicates a conflicting static output schema or another serializer implementation defect and aborts the process.
pub fn[T] Lens::set_or_abort(
  self : Lens[T],
  builder : JsonBuilder,
  value : T,
) -> Unit {
  self.set(builder, value) catch {
    error => abort("invalid lens-based ToJson implementation: \{repr(error)}")
  }
}

///|
/// Writes an optional typed value for an infallible serialization contract.
pub fn[T] PresenceLens::set_or_abort(
  self : PresenceLens[T],
  builder : JsonBuilder,
  value : T?,
) -> Unit {
  self.set(builder, value) catch {
    error => abort("invalid lens-based ToJson implementation: \{repr(error)}")
  }
}

///|
pub impl ToJson for JsonBuilder with fn to_json(self) -> Json {
  self.properties.to_json()
}
