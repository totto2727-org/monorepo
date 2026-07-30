// MoonBit-only implementation required because TypeScript casts JSON.parse output to ThreadEvent.
// Corresponding upstream parse/cast: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/thread.ts#L96-L109
// This file is intentionally prefixed moonbit_internal_ because no equivalent decoder module exists upstream.

///|
fn moonbit_internal_json_object(
  json : Json,
  context : String,
) -> Map[String, Json] raise CodexSdkError {
  @lens.root().get(json) catch {
    _ => raise InvalidEvent(message="\{context} must be an object")
  }
}

///|
fn moonbit_internal_required_json(
  object : Map[String, Json],
  key : String,
  context : String,
) -> Json raise CodexSdkError {
  @lens.root().json(key).get(Json::object(object)) catch {
    _ => raise InvalidEvent(message="\{context} is missing \{key}")
  }
}

///|
fn moonbit_internal_required_string(
  object : Map[String, Json],
  key : String,
  context : String,
) -> String raise CodexSdkError {
  @lens.root().string(key).get(Json::object(object)) catch {
    @lens.LensError::LensError(issue) if issue.code ==
      @lens.IssueCode::MissingProperty =>
      raise InvalidEvent(message="\{context} is missing \{key}")
    _ => raise InvalidEvent(message="\{context}.\{key} must be a string")
  }
}

///|
fn moonbit_internal_required_int(
  object : Map[String, Json],
  key : String,
  context : String,
) -> Int raise CodexSdkError {
  @lens.root().int(key).get(Json::object(object)) catch {
    @lens.LensError::LensError(issue) if issue.code ==
      @lens.IssueCode::MissingProperty =>
      raise InvalidEvent(message="\{context} is missing \{key}")
    _ => raise InvalidEvent(message="\{context}.\{key} must be a number")
  }
}

///|
fn moonbit_internal_required_bool(
  object : Map[String, Json],
  key : String,
  context : String,
) -> Bool raise CodexSdkError {
  @lens.root().bool(key).get(Json::object(object)) catch {
    @lens.LensError::LensError(issue) if issue.code ==
      @lens.IssueCode::MissingProperty =>
      raise InvalidEvent(message="\{context} is missing \{key}")
    _ => raise InvalidEvent(message="\{context}.\{key} must be a boolean")
  }
}

///|
fn moonbit_internal_required_array(
  object : Map[String, Json],
  key : String,
  context : String,
) -> Array[Json] raise CodexSdkError {
  @lens.root().json(key).array().get(Json::object(object)) catch {
    @lens.LensError::LensError(issue) if issue.code ==
      @lens.IssueCode::MissingProperty =>
      raise InvalidEvent(message="\{context} is missing \{key}")
    _ => raise InvalidEvent(message="\{context}.\{key} must be an array")
  }
}

///|
fn moonbit_internal_optional_int(
  object : Map[String, Json],
  key : String,
  context : String,
) -> Int? raise CodexSdkError {
  @lens.root().int(key).nullish().get(Json::object(object)) catch {
    _ => raise InvalidEvent(message="\{context}.\{key} must be a number")
  }
}

///|
fn moonbit_internal_optional_json(
  object : Map[String, Json],
  key : String,
) -> Json? {
  @lens.root().json(key).nullish().get(Json::object(object)) catch {
    _ => None
  }
}

///|
fn moonbit_internal_int_or_missing_default(
  object : Map[String, Json],
  key : String,
  context : String,
  fallback : Int,
) -> Int raise CodexSdkError {
  let value = @lens.root().int(key).optional().get(Json::object(object)) catch {
      _ => raise InvalidEvent(message="\{context}.\{key} must be a number")
    }
  match value {
    Some(value) => value
    None => fallback
  }
}
