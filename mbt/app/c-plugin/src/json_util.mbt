///|
fn parse_json_object(text : String) -> Map[String, Json]? {
  match (@json.parse(text) catch { _ => Json::null() }) {
    Json::Object(object) => Some(object)
    _ => None
  }
}

///|
fn json_string(object : Map[String, Json], key : String) -> String? {
  match object.get(key) {
    Some(Json::String(value)) => Some(value)
    _ => None
  }
}

///|
fn json_object(object : Map[String, Json], key : String) -> Map[String, Json]? {
  match object.get(key) {
    Some(Json::Object(value)) => Some(value)
    _ => None
  }
}

///|
fn json_array(object : Map[String, Json], key : String) -> Array[Json] {
  match object.get(key) {
    Some(Json::Array(values)) => values
    _ => []
  }
}

///|
fn json_string_array(object : Map[String, Json], key : String) -> Array[String] {
  let result : Array[String] = []
  for value in json_array(object, key) {
    match value {
      Json::String(text) => result.push(text)
      _ => ()
    }
  }
  result
}
