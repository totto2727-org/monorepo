///|
fn moonbit_internal_json_object(
  json : Json,
  context : String,
) -> Map[String, Json] raise OpenCodeSdkError {
  match json {
    Json::Object(object) => object
    _ => raise InvalidEvent(message="\{context} must be an object")
  }
}

///|
fn moonbit_internal_required_json(
  object : Map[String, Json],
  key : String,
  context : String,
) -> Json raise OpenCodeSdkError {
  match object.get(key) {
    Some(value) => value
    None => raise InvalidEvent(message="\{context}.\{key} is required")
  }
}

///|
fn moonbit_internal_required_string(
  object : Map[String, Json],
  key : String,
  context : String,
) -> String raise OpenCodeSdkError {
  match object.get(key) {
    Some(Json::String(value)) => value
    Some(_) => raise InvalidEvent(message="\{context}.\{key} must be a string")
    None => raise InvalidEvent(message="\{context}.\{key} is required")
  }
}

///|
fn moonbit_internal_required_double(
  object : Map[String, Json],
  key : String,
  context : String,
) -> Double raise OpenCodeSdkError {
  match object.get(key) {
    Some(Json::Number(value, ..)) => value
    Some(_) => raise InvalidEvent(message="\{context}.\{key} must be a number")
    None => raise InvalidEvent(message="\{context}.\{key} is required")
  }
}

///|
fn moonbit_internal_required_int(
  object : Map[String, Json],
  key : String,
  context : String,
) -> Int raise OpenCodeSdkError {
  moonbit_internal_required_double(object, key, context).to_int()
}
