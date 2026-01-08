///|
pub fn[T : ToJson] to_optional_json(
  map : Map[String, Json],
  key : String,
  value : T?,
) -> Unit {
  match value {
    Some(value) => map.set(key, value.to_json())
    None => ()
  }
}

///|
pub fn[T : ToJson] to_nullable_json(
  map : Map[String, Json],
  key : String,
  value : T?,
) -> Unit {
  match value {
    Some(value) => map.set(key, value.to_json())
    None => map.set(key, Json::null())
  }
}

///|
pub fn[T : ToJson, U : ToJson] to_json_or_default(
  map : Map[String, Json],
  key : String,
  value : T?,
  default : () -> U,
) -> Unit {
  match value {
    Some(value) => map.set(key, value.to_json())
    None => map.set(key, default().to_json())
  }
}
