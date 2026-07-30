///|
fn moonbit_internal_json_object(
  json : Json,
  context : String,
) -> Map[String, Json] raise OpenCodeSdkError {
  @lens.root().get(json) catch {
    _ => raise InvalidEvent(message="\{context} must be an object")
  }
}

///|
fn moonbit_internal_required_json(
  object : Map[String, Json],
  key : String,
  context : String,
) -> Json raise OpenCodeSdkError {
  @lens.root().json(key).get(Json::object(object)) catch {
    _ => raise InvalidEvent(message="\{context}.\{key} is required")
  }
}

///|
fn moonbit_internal_required_string(
  object : Map[String, Json],
  key : String,
  context : String,
) -> String raise OpenCodeSdkError {
  @lens.root().string(key).get(Json::object(object)) catch {
    @lens.LensError::LensError(issue) if issue.code ==
      @lens.IssueCode::MissingProperty =>
      raise InvalidEvent(message="\{context}.\{key} is required")
    _ => raise InvalidEvent(message="\{context}.\{key} must be a string")
  }
}

///|
fn moonbit_internal_required_double(
  object : Map[String, Json],
  key : String,
  context : String,
) -> Double raise OpenCodeSdkError {
  @lens.root().number(key).get(Json::object(object)) catch {
    @lens.LensError::LensError(issue) if issue.code ==
      @lens.IssueCode::MissingProperty =>
      raise InvalidEvent(message="\{context}.\{key} is required")
    _ => raise InvalidEvent(message="\{context}.\{key} must be a number")
  }
}

///|
fn moonbit_internal_required_int(
  object : Map[String, Json],
  key : String,
  context : String,
) -> Int raise OpenCodeSdkError {
  @lens.root().int(key).get(Json::object(object)) catch {
    @lens.LensError::LensError(issue) if issue.code ==
      @lens.IssueCode::MissingProperty =>
      raise InvalidEvent(message="\{context}.\{key} is required")
    _ => raise InvalidEvent(message="\{context}.\{key} must be a number")
  }
}
