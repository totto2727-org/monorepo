///|
pub fn[T : FromJson] from_json_property(
  key : String,
  json : Json,
  path : @json.JsonPath,
) -> T? raise @json.JsonDecodeError {
  let path = path.add_key(key)
  guard json is Object(object) else {
    raise @json.JsonDecodeError((path, "Expected object, got \{json}"))
  }
  match object.get(key) {
    None | Some(Null) => None
    Some(json) => Some(T::from_json(json, path))
  }
}

///|
pub fn[T : FromJson] from_json_property_or_throw(
  key : String,
  json : Json,
  path : @json.JsonPath,
) -> T raise @json.JsonDecodeError {
  match from_json_property(key, json, path) {
    None => raise @json.JsonDecodeError((path, "Missing key \{key}"))
    Some(val) => val
  }
}

///|
pub fn[T : FromJson] from_json_property_or_default(
  key : String,
  default : () -> T,
  json : Json,
  path : @json.JsonPath,
) -> T raise @json.JsonDecodeError {
  match from_json_property(key, json, path) {
    None => default()
    Some(val) => val
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
