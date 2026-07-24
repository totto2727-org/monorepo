// MoonBit-only implementation required because TypeScript casts JSON.parse output to ThreadEvent.
// Corresponding upstream parse/cast: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/thread.ts#L96-L109
// This file is intentionally prefixed moonbit_internal_ because no equivalent decoder module exists upstream.

fn moonbit_internal_json_object(
  json : Json,
  context : String,
) -> Map[String, Json] raise CodexSdkError {
  match json {
    Json::Object(object) => object
    _ => raise InvalidEvent(message="\{context} must be an object")
  }
}

fn moonbit_internal_required_json(
  object : Map[String, Json],
  key : String,
  context : String,
) -> Json raise CodexSdkError {
  match object.get(key) {
    Some(value) => value
    None => raise InvalidEvent(message="\{context} is missing \{key}")
  }
}

fn moonbit_internal_required_string(
  object : Map[String, Json],
  key : String,
  context : String,
) -> String raise CodexSdkError {
  match moonbit_internal_required_json(object, key, context) {
    Json::String(value) => value
    _ => raise InvalidEvent(message="\{context}.\{key} must be a string")
  }
}

fn moonbit_internal_required_int(
  object : Map[String, Json],
  key : String,
  context : String,
) -> Int raise CodexSdkError {
  match moonbit_internal_required_json(object, key, context) {
    Json::Number(value, ..) => value.to_int()
    _ => raise InvalidEvent(message="\{context}.\{key} must be a number")
  }
}

fn moonbit_internal_required_bool(
  object : Map[String, Json],
  key : String,
  context : String,
) -> Bool raise CodexSdkError {
  match moonbit_internal_required_json(object, key, context) {
    Json::True => true
    Json::False => false
    _ => raise InvalidEvent(message="\{context}.\{key} must be a boolean")
  }
}

fn moonbit_internal_required_array(
  object : Map[String, Json],
  key : String,
  context : String,
) -> Array[Json] raise CodexSdkError {
  match moonbit_internal_required_json(object, key, context) {
    Json::Array(value) => value
    _ => raise InvalidEvent(message="\{context}.\{key} must be an array")
  }
}

fn moonbit_internal_optional_int(
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

fn moonbit_internal_optional_json(
  object : Map[String, Json],
  key : String,
) -> Json? {
  match object.get(key) {
    None | Some(Json::Null) => None
    Some(value) => Some(value)
  }
}
