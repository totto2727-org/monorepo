fn json_object(json : Json, context : String) -> Map[String, Json] raise CodexSdkError {
  match json {
    Json::Object(object) => object
    _ => raise InvalidEvent(message="\{context} must be an object")
  }
}

fn required_json(
  object : Map[String, Json],
  key : String,
  context : String,
) -> Json raise CodexSdkError {
  match object.get(key) {
    Some(value) => value
    None => raise InvalidEvent(message="\{context} is missing \{key}")
  }
}

fn required_string(
  object : Map[String, Json],
  key : String,
  context : String,
) -> String raise CodexSdkError {
  match required_json(object, key, context) {
    Json::String(value) => value
    _ => raise InvalidEvent(message="\{context}.\{key} must be a string")
  }
}

fn required_int(
  object : Map[String, Json],
  key : String,
  context : String,
) -> Int raise CodexSdkError {
  match required_json(object, key, context) {
    Json::Number(value, ..) => value.to_int()
    _ => raise InvalidEvent(message="\{context}.\{key} must be a number")
  }
}

fn required_bool(
  object : Map[String, Json],
  key : String,
  context : String,
) -> Bool raise CodexSdkError {
  match required_json(object, key, context) {
    Json::True => true
    Json::False => false
    _ => raise InvalidEvent(message="\{context}.\{key} must be a boolean")
  }
}

fn required_array(
  object : Map[String, Json],
  key : String,
  context : String,
) -> Array[Json] raise CodexSdkError {
  match required_json(object, key, context) {
    Json::Array(value) => value
    _ => raise InvalidEvent(message="\{context}.\{key} must be an array")
  }
}

fn optional_int(
  object : Map[String, Json],
  key : String,
  context : String,
) -> Int? raise CodexSdkError {
  match object.get(key) {
    None | Some(Json::Null) => None
    Some(Json::Number(value, ..)) => Some(value.to_int())
    Some(_) => raise InvalidEvent(message="\{context}.\{key} must be a number")
  }
}

fn optional_json(object : Map[String, Json], key : String) -> Json? {
  match object.get(key) {
    None | Some(Json::Null) => None
    Some(value) => Some(value)
  }
}
