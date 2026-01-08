///|
pub fn[T : FromJson] from_json_property(
  key : String,
  json : Json,
  path : @json.JsonPath,
) -> T? raise @json.JsonDecodeError {
  guard json is Object(object) else {
    raise @json.JsonDecodeError((path, "Expected object, got \{json}"))
  }
  match object.get(key) {
    None | Some(Null) => None
    Some(json) => Some(T::from_json(json, path))
  }
}

///|
pub fn[T : FromJson] from_json_property_or_default(
  key : String,
  default : () -> T,
  json : Json,
  path : @json.JsonPath,
) -> T raise @json.JsonDecodeError {
  guard json is Object(object) else {
    raise @json.JsonDecodeError((path, "Expected object, got \{json}"))
  }
  match object.get(key) {
    None | Some(Null) => default()
    Some(json) => T::from_json(json, path)
  }
}

///|
pub fn[T : FromJson] from_json_property_or_array_or_empty(
  key : String,
  json : Json,
  path : @json.JsonPath,
) -> Array[T] raise @json.JsonDecodeError {
  from_json_property_or_default(key, () => [], json, path)
}
