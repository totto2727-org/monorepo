///|
struct FromJsonRepository {
  owner : String
} derive(Debug, FromJson)

///|
enum FromJsonKind {
  Stable
  Preview
} derive(Debug)

///|
impl FromJson for FromJsonKind with fn from_json(json, path) {
  let value : String = @json.from_json(json, path~)
  match value {
    "stable" => Stable
    "preview" => Preview
    _ => raise @json.JsonDecodeError::JsonDecodeError((path, "invalid kind"))
  }
}

///|
struct FromJsonAbsolutePath(String) derive(Debug)

///|
impl FromJson for FromJsonAbsolutePath with fn from_json(json, path) {
  let value : String = @json.from_json(json, path~)
  guard value.has_prefix("/") else {
    raise @json.JsonDecodeError::JsonDecodeError(
      (path, "expected absolute path"),
    )
  }
  FromJsonAbsolutePath(value)
}

///|
fn from_json_test_root_path() -> @json.JsonPath raise {
  try {
    let _ : Bool = @json.from_json(Json::null())
    fail("expected JsonDecodeError")
  } catch {
    @json.JsonDecodeError::JsonDecodeError((path, _)) => path
    _ => fail("unexpected error")
  }
}

///|
fn from_json_test_error_path(action : () -> Unit raise) -> @json.JsonPath raise {
  try {
    action()
    fail("expected JsonDecodeError")
  } catch {
    @json.JsonDecodeError::JsonDecodeError((error_path, _)) => error_path
    _ => fail("unexpected error")
  }
}

///|
test "Lens decode_from_json - decodes object enum and validated values" {
  let document = @json.parse(
    "{\"repository\":{\"owner\":\"totto2727\"},\"kind\":\"stable\",\"path\":\"/tmp/cache\"}",
  )
  let path = from_json_test_root_path().add_key("request")
  let repository : FromJsonRepository = root()
    .json("repository")
    .decode_from_json(document, path)
  let kind : FromJsonKind = root().json("kind").decode_from_json(document, path)
  let validated : FromJsonAbsolutePath = root()
    .json("path")
    .decode_from_json(document, path)
  debug_inspect(repository, content="{ owner: \"totto2727\" }")
  debug_inspect(kind, content="Stable")
  debug_inspect(validated, content="FromJsonAbsolutePath(\"/tmp/cache\")")
}

///|
test "Lens decode_from_json - preserves selection nested and caller paths" {
  let path = from_json_test_root_path().add_key("request")
  inspect(
    from_json_test_error_path(() => {
      let _ : FromJsonRepository = root()
        .json("repository")
        .decode_from_json(@json.parse("{}"), path)
    }),
    content="/request/repository",
  )
  inspect(
    from_json_test_error_path(() => {
      let _ : FromJsonRepository = root()
        .json("repository")
        .decode_from_json(@json.parse("{\"repository\":false}"), path)
    }),
    content="/request/repository",
  )
  inspect(
    from_json_test_error_path(() => {
      let _ : FromJsonRepository = root()
        .json("repository")
        .decode_from_json(
          @json.parse("{\"repository\":{\"owner\":false}}"),
          path,
        )
    }),
    content="/request/repository/owner",
  )
  inspect(
    from_json_test_error_path(() => {
      let _ : FromJsonKind = root()
        .json("kind")
        .decode_from_json(@json.parse("{\"kind\":\"unknown\"}"), path)
    }),
    content="/request/kind",
  )
  inspect(
    from_json_test_error_path(() => {
      let _ : FromJsonAbsolutePath = root()
        .json("path")
        .decode_from_json(@json.parse("{\"path\":\"relative\"}"), path)
    }),
    content="/request/path",
  )
}
