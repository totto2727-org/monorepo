// MoonBit-only JSON decoding support required because TypeScript casts JSON.parse output to ThreadEvent.
// Corresponding upstream parse/cast: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/thread.ts#L96-L109
// This file is intentionally prefixed moonbit_internal_ because no equivalent decoder module exists upstream.

///|
fn[T] moonbit_internal_decode_error(
  path : @json.JsonPath,
  message : String,
) -> T raise @json.JsonDecodeError {
  raise @json.JsonDecodeError((path, message))
}

///|
fn moonbit_internal_json_object(
  json : Json,
  path : @json.JsonPath,
  context : String,
) -> Map[String, Json] raise @json.JsonDecodeError {
  guard json is Json::Object(object) else {
    return moonbit_internal_decode_error(path, "\{context} must be an object")
  }
  object
}

///|
fn moonbit_internal_required_json(
  object : Map[String, Json],
  key : String,
  path : @json.JsonPath,
  context : String,
) -> Json raise @json.JsonDecodeError {
  @lens.root().json(key).get(Json::object(object)) catch {
    @lens.LensError::LensError(_) =>
      moonbit_internal_decode_error(
        path.add_key(key),
        "\{context} is missing \{key}",
      )
  }
}

///|
fn moonbit_internal_required_string(
  object : Map[String, Json],
  key : String,
  path : @json.JsonPath,
  context : String,
) -> String raise @json.JsonDecodeError {
  let value = moonbit_internal_required_json(object, key, path, context)
  @json.from_json(value, path=path.add_key(key)) catch {
    _ =>
      moonbit_internal_decode_error(
        path.add_key(key),
        "\{context}.\{key} must be a string",
      )
  }
}

///|
fn moonbit_internal_required_int(
  object : Map[String, Json],
  key : String,
  path : @json.JsonPath,
  context : String,
) -> Int raise @json.JsonDecodeError {
  let value = moonbit_internal_required_json(object, key, path, context)
  @json.from_json(value, path=path.add_key(key)) catch {
    _ =>
      moonbit_internal_decode_error(
        path.add_key(key),
        "\{context}.\{key} must be a number",
      )
  }
}

///|
fn moonbit_internal_required_bool(
  object : Map[String, Json],
  key : String,
  path : @json.JsonPath,
  context : String,
) -> Bool raise @json.JsonDecodeError {
  let value = moonbit_internal_required_json(object, key, path, context)
  @json.from_json(value, path=path.add_key(key)) catch {
    _ =>
      moonbit_internal_decode_error(
        path.add_key(key),
        "\{context}.\{key} must be a boolean",
      )
  }
}

///|
fn moonbit_internal_required_array(
  object : Map[String, Json],
  key : String,
  path : @json.JsonPath,
  context : String,
) -> Array[Json] raise @json.JsonDecodeError {
  let value = moonbit_internal_required_json(object, key, path, context)
  @json.from_json(value, path=path.add_key(key)) catch {
    _ =>
      moonbit_internal_decode_error(
        path.add_key(key),
        "\{context}.\{key} must be an array",
      )
  }
}

///|
fn moonbit_internal_optional_int(
  object : Map[String, Json],
  key : String,
  path : @json.JsonPath,
  context : String,
) -> Int? raise @json.JsonDecodeError {
  let value = @lens.root().json(key).nullish().get(Json::object(object)) catch {
      @lens.LensError::LensError(_) =>
        moonbit_internal_decode_error(
          path.add_key(key),
          "\{context}.\{key} must be a number",
        )
    }
  match value {
    None => None
    Some(value) =>
      Some(@json.from_json(value, path=path.add_key(key))) catch {
        _ =>
          moonbit_internal_decode_error(
            path.add_key(key),
            "\{context}.\{key} must be a number",
          )
      }
  }
}

///|
fn moonbit_internal_optional_json(
  object : Map[String, Json],
  key : String,
) -> Json? {
  @lens.root().json(key).nullish().get(Json::object(object)) catch {
    @lens.LensError::LensError(_) => None
  }
}

///|
fn moonbit_internal_int_or_missing_default(
  object : Map[String, Json],
  key : String,
  path : @json.JsonPath,
  context : String,
  fallback : Int,
) -> Int raise @json.JsonDecodeError {
  let value = @lens.root().json(key).optional().get(Json::object(object)) catch {
      @lens.LensError::LensError(_) =>
        moonbit_internal_decode_error(
          path.add_key(key),
          "\{context}.\{key} must be a number",
        )
    }
  match value {
    None => fallback
    Some(value) =>
      @json.from_json(value, path=path.add_key(key)) catch {
        _ =>
          moonbit_internal_decode_error(
            path.add_key(key),
            "\{context}.\{key} must be a number",
          )
      }
  }
}
