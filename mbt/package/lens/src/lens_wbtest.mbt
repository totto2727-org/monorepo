///|
/// White-box coverage may construct read-only diagnostic variants.
let lens_test_user_object : ObjectLens = object("user")

///|
let lens_test_user_profile_object : ObjectLens = object("user").object(
  "profile",
)

///|
let lens_test_user_profile_name : Lens[String] = object("user")
  .object("profile")
  .string("name")

///|
let lens_test_user_profile_active : Lens[Bool] = object("user")
  .object("profile")
  .bool("active")

///|
let lens_test_user_profile_metadata : Lens[Json] = object("user")
  .object("profile")
  .json("metadata")

///|
let lens_test_user_name : Lens[String] = object("user").string("name")

///|
struct FromJsonRepository {
  owner : String
} derive(Debug, FromJson, ToJson)

///|
struct FromJsonOnlyRepository {
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
impl ToJson for FromJsonKind with fn to_json(self) {
  match self {
    Stable => "stable".to_json()
    Preview => "preview".to_json()
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
impl ToJson for FromJsonAbsolutePath with fn to_json(self) {
  let FromJsonAbsolutePath(value) = self
  value.to_json()
}

///|
let lens_test_root_name : Lens[String] = root().string("name")

///|
let lens_test_escaped_key : Lens[String] = object("a/b").string("~key")

///|
let lens_test_empty_key : Lens[String] = root().string("")

///|
let lens_test_text : Lens[String] = root().string("text")

///|
let lens_test_flag : Lens[Bool] = root().bool("flag")

///|
let lens_test_number : Lens[Double] = root().number("number")

///|
let lens_test_integer : Lens[Int] = root().int("integer")

///|
let lens_test_ratio : Lens[Double] = root().number("ratio")

///|
let lens_test_maximum : Lens[Int] = root().int("maximum")

///|
let lens_test_minimum : Lens[Int] = root().int("minimum")

///|
let lens_test_positive_int : Lens[Int] = root().int("positive")

///|
let lens_test_negative_int : Lens[Int] = root().int("negative")

///|
let lens_test_positive_number : Lens[Double] = root().number("positive")

///|
let lens_test_names_array : Lens[Array[String]] = root().string("names").array()

///|
let lens_test_optional_names_array : Lens[Array[String?]] = root()
  .string("names")
  .optional()
  .array()

///|
let lens_test_nullable_names_array : Lens[Array[String?]] = root()
  .string("names")
  .nullable()
  .array()

///|
let lens_test_nullish_names_array : Lens[Array[String?]] = root()
  .string("names")
  .nullish()
  .array()

///|
let lens_test_name_nullable : PresenceLens[String] = root()
  .string("name")
  .nullable()

///|
let lens_test_name_optional : PresenceLens[String] = root()
  .string("name")
  .optional()

///|
let lens_test_user_name_optional : PresenceLens[String] = object("user")
  .string("name")
  .optional()

///|
let lens_test_name_nullish : PresenceLens[String] = root()
  .string("name")
  .nullish()

///|
let lens_test_optional_then_nullable : PresenceLens[String] = root()
  .string("name")
  .optional()
  .nullable()

///|
let lens_test_nullish_then_nullable : PresenceLens[String] = root()
  .string("name")
  .nullish()
  .nullable()

///|
let lens_test_nullable_then_optional : PresenceLens[String] = root()
  .string("name")
  .nullable()
  .optional()

///|
fn[T] get_issue(lens : Lens[T], document : Json) -> Issue raise {
  try {
    lens.get(document) |> ignore
    fail("expected LensError")
  } catch {
    LensError::LensError(issue) => issue
    _ => fail("unexpected error")
  }
}

///|
fn[T] get_presence_issue(
  lens : PresenceLens[T],
  document : Json,
) -> Issue raise {
  try {
    lens.get(document) |> ignore
    fail("expected LensError")
  } catch {
    LensError::LensError(issue) => issue
    _ => fail("unexpected error")
  }
}

///|
fn get_object_issue(lens : ObjectLens, document : Json) -> Issue raise {
  try {
    lens.get(document) |> ignore
    fail("expected LensError")
  } catch {
    LensError::LensError(issue) => issue
    _ => fail("unexpected error")
  }
}

///|
fn assert_type_mismatch(
  issue : Issue,
  pointer : String,
  expected : JsonKind,
  actual : JsonKind,
) -> Unit raise {
  inspect(issue.pointer.to_string(), content=pointer)
  match issue.code {
    IssueCode::TypeMismatch(expected=found_expected, actual=found_actual) => {
      guard found_expected == expected && found_actual == actual else {
        fail("unexpected JSON kinds")
      }
    }
    _ => fail("expected TypeMismatch")
  }
}

///|
fn root_json_path() -> @json.JsonPath raise {
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
test "Lens add_to_json_path - appends the lens pointer to the existing path" {
  let path = root_json_path().add_key("request")
  inspect(
    lens_test_user_name.add_to_json_path(path),
    content="/request/user/name",
  )
}

///|
test "Lens json_decode_error - prefixes the path and preserves the message" {
  let path = root_json_path().add_key("request")
  let @json.JsonDecodeError::JsonDecodeError((error_path, message)) = lens_test_user_name.json_decode_error(
    path, "expected string",
  )
  inspect(error_path, content="/request/user/name")
  inspect(message, content="expected string")
}

///|
test "Lens get_or_json_decode_error - returns the decoded value" {
  let document = @json.parse("{\"user\":{\"name\":\"Ada\"}}")
  let path = root_json_path().add_key("request")
  inspect(
    lens_test_user_name.get_or_json_decode_error(document, path),
    content="Ada",
  )
}

///|
test "Lens get_or_json_decode_error - converts a lens failure" {
  let document = @json.parse("{\"user\":{\"profile\":false}}")
  let path = root_json_path().add_key("request")
  try {
    lens_test_user_profile_name.get_or_json_decode_error(document, path)
    |> ignore
    fail("expected JsonDecodeError")
  } catch {
    @json.JsonDecodeError::JsonDecodeError((error_path, message)) => {
      inspect(error_path, content="/request/user/profile")
      assert_true(message.contains("TypeMismatch"))
    }
    _ => fail("unexpected error")
  }
}

///|
test "ObjectLens custom - decodes object enum and validated values" {
  let document = @json.parse(
    "{\"repository\":{\"owner\":\"totto2727\"},\"kind\":\"stable\",\"path\":\"/tmp/cache\"}",
  )
  let path = root_json_path().add_key("request")
  let repository_lens : Lens[FromJsonRepository] = root().custom("repository")
  let repository = repository_lens.get(document)
  let kind : FromJsonKind = root()
    .custom("kind")
    .get_or_json_decode_error(document, path)
  let validated : FromJsonAbsolutePath = root()
    .custom("path")
    .get_or_json_decode_error(document, path)
  debug_inspect(repository, content="{ owner: \"totto2727\" }")
  debug_inspect(kind, content="Stable")
  debug_inspect(validated, content="FromJsonAbsolutePath(\"/tmp/cache\")")
}

///|
test "ObjectLens custom - encodes values through ToJson" {
  let repository_lens : Lens[FromJsonRepository] = root().custom("repository")
  let builder = JsonBuilder::JsonBuilder()
  repository_lens.set_or_abort(builder, FromJsonRepository::{
    owner: "totto2727",
  })
  inspect(
    ToJson::to_json(builder).stringify(),
    content="{\"repository\":{\"owner\":\"totto2727\"}}",
  )
}

///|
test "ObjectLens custom - preserves selection nested and caller paths" {
  let path = root_json_path().add_key("request")
  inspect(
    from_json_test_error_path(() => {
      let _ : FromJsonRepository = root()
        .custom("repository")
        .get_or_json_decode_error(@json.parse("{}"), path)
    }),
    content="/request/repository",
  )
  inspect(
    from_json_test_error_path(() => {
      let _ : FromJsonRepository = root()
        .custom("repository")
        .get_or_json_decode_error(@json.parse("{\"repository\":false}"), path)
    }),
    content="/request/repository",
  )
  inspect(
    from_json_test_error_path(() => {
      let _ : FromJsonRepository = root()
        .custom("repository")
        .get_or_json_decode_error(
          @json.parse("{\"repository\":{\"owner\":false}}"),
          path,
        )
    }),
    content="/request/repository/owner",
  )
  inspect(
    from_json_test_error_path(() => {
      let _ : FromJsonKind = root()
        .custom("kind")
        .get_or_json_decode_error(@json.parse("{\"kind\":\"unknown\"}"), path)
    }),
    content="/request/kind",
  )
  inspect(
    from_json_test_error_path(() => {
      let _ : FromJsonAbsolutePath = root()
        .custom("path")
        .get_or_json_decode_error(@json.parse("{\"path\":\"relative\"}"), path)
    }),
    content="/request/path",
  )
}

///|
test "ObjectLens custom array - preserves item decode paths" {
  let repositories : Lens[Array[FromJsonRepository]] = root()
    .custom("repositories")
    .array()
  let path = root_json_path().add_key("request")
  inspect(
    from_json_test_error_path(() => {
      repositories.get_or_json_decode_error(
        @json.parse(
          "{\"repositories\":[{\"owner\":\"totto2727\"},{\"owner\":false}]}",
        ),
        path,
      )
      |> ignore
    }),
    content="/request/repositories/1/owner",
  )
}

///|
test "ObjectLens custom presence - preserves nested decode paths" {
  let repository : PresenceLens[FromJsonRepository] = root()
    .custom("repository")
    .optional()
  let path = root_json_path().add_key("request")
  inspect(
    from_json_test_error_path(() => {
      repository.get_or_json_decode_error(
        @json.parse("{\"repository\":{\"owner\":false}}"),
        path,
      )
      |> ignore
    }),
    content="/request/repository/owner",
  )
}

///|
test "ObjectLens custom presence - preserves missing and null policies" {
  let optional : PresenceLens[FromJsonRepository] = root()
    .custom("repository")
    .optional()
  let nullable : PresenceLens[FromJsonRepository] = root()
    .custom("repository")
    .nullable()
  let nullish : PresenceLens[FromJsonRepository] = root()
    .custom("repository")
    .nullish()
  let path = root_json_path().add_key("request")
  debug_inspect(
    optional.get_or_json_decode_error(@json.parse("{}"), path),
    content="None",
  )
  inspect(
    from_json_test_error_path(() => {
      optional.get_or_json_decode_error(
        @json.parse("{\"repository\":null}"),
        path,
      )
      |> ignore
    }),
    content="/request/repository",
  )
  inspect(
    from_json_test_error_path(() => {
      nullable.get_or_json_decode_error(@json.parse("{}"), path) |> ignore
    }),
    content="/request/repository",
  )
  debug_inspect(
    nullable.get_or_json_decode_error(
      @json.parse("{\"repository\":null}"),
      path,
    ),
    content="None",
  )
  debug_inspect(
    nullish.get_or_json_decode_error(@json.parse("{}"), path),
    content="None",
  )
  debug_inspect(
    nullish.get_or_json_decode_error(@json.parse("{\"repository\":null}"), path),
    content="None",
  )
}

///|
test "ObjectLens custom get - reports external decode at the selected pointer" {
  let repository : Lens[FromJsonRepository] = root().custom("repository")
  let issue = get_issue(
    repository,
    @json.parse("{\"repository\":{\"owner\":false}}"),
  )
  inspect(issue.pointer.to_string(), content="/repository")
  debug_inspect(issue.code, content="ExternalDecode")
}

///|
test "ObjectLens custom array get - reports external decode at the item pointer" {
  let repositories : Lens[Array[FromJsonRepository]] = root()
    .custom("repositories")
    .array()
  let issue = get_issue(
    repositories,
    @json.parse(
      "{\"repositories\":[{\"owner\":\"totto2727\"},{\"owner\":false}]}",
    ),
  )
  inspect(issue.pointer.to_string(), content="/repositories/1")
  debug_inspect(issue.code, content="ExternalDecode")
}

///|
test "Lens decode_from_json - preserves the FromJson-only read bridge" {
  let repository_lens : Lens[Json] = root().json("repository")
  let path = root_json_path().add_key("request")
  let repository : FromJsonOnlyRepository = repository_lens.decode_from_json(
    @json.parse("{\"repository\":{\"owner\":\"totto2727\"}}"),
    path,
  )
  debug_inspect(repository, content="{ owner: \"totto2727\" }")
  inspect(
    from_json_test_error_path(() => {
      let _ : FromJsonOnlyRepository = repository_lens.decode_from_json(
        @json.parse("{\"repository\":{\"owner\":false}}"),
        path,
      )
    }),
    content="/request/repository/owner",
  )
}

///|
test "ObjectLens get - reads the selected object" {
  let document = @json.parse(
    "{\"user\":{\"name\":\"Ada\",\"metadata\":{\"role\":\"admin\"}}}",
  )
  debug_inspect(
    lens_test_user_object.get(document),
    content=(
      #|{
      #|  "name": String("Ada"),
      #|  "metadata": Object({ "role": String("admin") }),
      #|}
    ),
  )
}

///|
test "ObjectLens get - isolates the returned map from the document" {
  let document = @json.parse("{\"user\":{\"name\":\"Ada\"}}")
  let selected = lens_test_user_object.get(document)
  selected.set("name", @json.parse("\"Grace\""))
  inspect(lens_test_user_name.get(document), content="Ada")
}

///|
test "ObjectLens get - reports a selected non-object pointer" {
  let document = @json.parse("{\"user\":{\"profile\":\"invalid\"}}")
  let issue = get_object_issue(lens_test_user_profile_object, document)
  assert_type_mismatch(
    issue,
    "/user/profile",
    JsonKind::Object,
    JsonKind::String,
  )
}

///|
test "Lens get - reads nested typed values" {
  let document = @json.parse(
    "{\"user\":{\"profile\":{\"name\":\"Ada\",\"active\":true,\"metadata\":{\"role\":\"admin\"}}}}",
  )
  inspect(lens_test_user_profile_name.get(document), content="Ada")
  inspect(lens_test_user_profile_active.get(document), content="true")
  inspect(
    lens_test_user_profile_metadata.get(document).stringify(),
    content="{\"role\":\"admin\"}",
  )
}

///|
test "Lens get - reuses one lens across documents" {
  let first = @json.parse("{\"user\":{\"name\":\"Ada\"}}")
  let second = @json.parse("{\"user\":{\"name\":\"Grace\"}}")
  inspect(lens_test_user_name.get(first), content="Ada")
  inspect(lens_test_user_name.get(second), content="Grace")
}

///|
test "Lens get - reports a missing leaf pointer" {
  let document = @json.parse("{\"user\":{\"profile\":{}}}")
  let issue = get_issue(lens_test_user_profile_name, document)
  inspect(issue.pointer.to_string(), content="/user/profile/name")
  match issue.code {
    IssueCode::MissingProperty => ()
    _ => fail("expected MissingProperty")
  }
}

///|
test "Lens get - reports an incompatible intermediate pointer" {
  let document = @json.parse("{\"user\":{\"profile\":\"invalid\"}}")
  let issue = get_issue(lens_test_user_profile_name, document)
  inspect(issue.pointer.to_string(), content="/user/profile")
  match issue.code {
    IssueCode::TypeMismatch(expected~, actual~) => {
      debug_inspect(expected, content="Object")
      debug_inspect(actual, content="String")
    }
    _ => fail("expected TypeMismatch")
  }
}

///|
test "Lens get - reports a missing intermediate pointer" {
  let document = @json.parse("{\"user\":{}}")
  let issue = get_issue(lens_test_user_profile_name, document)
  inspect(issue.pointer.to_string(), content="/user/profile")
  match issue.code {
    IssueCode::MissingProperty => ()
    _ => fail("expected MissingProperty")
  }
}

///|
test "Lens get - reports a non-object root at the root pointer" {
  let document = @json.parse("[]")
  let issue = get_issue(lens_test_root_name, document)
  assert_type_mismatch(issue, "", JsonKind::Object, JsonKind::Array)
}

///|
test "Lens get - escapes JSON Pointer keys in errors" {
  let document = @json.parse("{\"a/b\":{}}")
  let issue = get_issue(lens_test_escaped_key, document)
  inspect(issue.pointer.to_string(), content="/a~1b/~0key")
}

///|
test "Lens get - renders an empty key as one pointer segment" {
  let document = @json.parse("{}")
  let issue = get_issue(lens_test_empty_key, document)
  inspect(issue.pointer.to_string(), content="/")
}

///|
test "Lens get - classifies primitive type mismatches" {
  let document = @json.parse(
    "{\"text\":false,\"flag\":0,\"number\":\"0\",\"integer\":null}",
  )
  assert_type_mismatch(
    get_issue(lens_test_text, document),
    "/text",
    JsonKind::String,
    JsonKind::Boolean,
  )
  assert_type_mismatch(
    get_issue(lens_test_flag, document),
    "/flag",
    JsonKind::Boolean,
    JsonKind::Number,
  )
  assert_type_mismatch(
    get_issue(lens_test_number, document),
    "/number",
    JsonKind::Number,
    JsonKind::String,
  )
  assert_type_mismatch(
    get_issue(lens_test_integer, document),
    "/integer",
    JsonKind::Number,
    JsonKind::Null,
  )
}

///|
test "Lens get - reads numbers and standard-converted integers" {
  let document = @json.parse(
    "{\"ratio\":42.5,\"maximum\":2147483647,\"minimum\":-2147483648}",
  )
  inspect(lens_test_ratio.get(document), content="42.5")
  inspect(lens_test_maximum.get(document), content="2147483647")
  inspect(lens_test_minimum.get(document), content="-2147483648")
}

///|
test "Lens get - delegates fractional conversion to Double::to_int" {
  let document = @json.parse("{\"positive\":42.5,\"negative\":-42.5}")
  inspect(lens_test_positive_int.get(document), content="42")
  inspect(lens_test_negative_int.get(document), content="-42")
}

///|
test "Lens get - delegates saturating conversion to Double::to_int" {
  let document = @json.parse(
    "{\"positive\":2147483648,\"negative\":-2147483649}",
  )
  inspect(lens_test_positive_int.get(document), content="2147483647")
  inspect(lens_test_negative_int.get(document), content="-2147483648")
}

///|
test "Lens get - passes through non-finite numbers" {
  let document = @json.parse("{\"positive\":1e999,\"negative\":-1e999}")
  inspect(lens_test_positive_number.get(document).is_inf(), content="true")
  inspect(lens_test_positive_int.get(document), content="2147483647")
  inspect(lens_test_negative_int.get(document), content="-2147483648")
}

///|
test "Lens array - decodes every item" {
  let document = @json.parse("{\"names\":[\"Ada\",\"Grace\"]}")
  debug_inspect(
    lens_test_names_array.get(document),
    content="[\"Ada\", \"Grace\"]",
  )
}

///|
test "Lens array - reports an item pointer" {
  let document = @json.parse("{\"names\":[\"Ada\",false]}")
  let issue = get_issue(lens_test_names_array, document)
  assert_type_mismatch(issue, "/names/1", JsonKind::String, JsonKind::Boolean)
}

///|
test "Lens array - rejects a non-array value" {
  let document = @json.parse("{\"names\":\"Ada\"}")
  let issue = get_issue(lens_test_names_array, document)
  assert_type_mismatch(issue, "/names", JsonKind::Array, JsonKind::String)
}

///|
test "PresenceLens array - decodes JSON null for every presence policy" {
  let document = @json.parse("{\"names\":[\"Ada\",null]}")
  for
    lens in [
      lens_test_optional_names_array, lens_test_nullable_names_array, lens_test_nullish_names_array,
    ] {
    debug_inspect(lens.get(document), content="[Some(\"Ada\"), None]")
  }
}

///|
test "Lens nullable - returns None for JSON null" {
  let document = @json.parse("{\"name\":null}")
  debug_inspect(lens_test_name_nullable.get(document), content="None")
}

///|
test "Lens nullable - returns Some for a decoded value" {
  let document = @json.parse("{\"name\":\"Ada\"}")
  debug_inspect(lens_test_name_nullable.get(document), content="Some(\"Ada\")")
}

///|
test "Lens nullable - preserves missing-property errors" {
  let document = @json.parse("{}")
  let issue = get_presence_issue(lens_test_name_nullable, document)
  inspect(issue.pointer.to_string(), content="/name")
  match issue.code {
    IssueCode::MissingProperty => ()
    _ => fail("expected MissingProperty")
  }
}

///|
test "Lens optional - returns None for a missing path" {
  let document = @json.parse("{}")
  debug_inspect(lens_test_name_optional.get(document), content="None")
}

///|
test "Lens optional - returns Some for a decoded value" {
  let document = @json.parse("{\"name\":\"Ada\"}")
  debug_inspect(lens_test_name_optional.get(document), content="Some(\"Ada\")")
}

///|
test "Lens optional - preserves a missing intermediate error" {
  let document = @json.parse("{}")
  let issue = get_presence_issue(lens_test_user_name_optional, document)
  inspect(issue.pointer.to_string(), content="/user")
  match issue.code {
    IssueCode::MissingProperty => ()
    _ => fail("expected MissingProperty")
  }
}

///|
test "Lens optional - rejects JSON null" {
  let document = @json.parse("{\"name\":null}")
  let issue = get_presence_issue(lens_test_name_optional, document)
  assert_type_mismatch(issue, "/name", JsonKind::String, JsonKind::Null)
}

///|
test "Lens nullish - returns None for a missing path" {
  let document = @json.parse("{}")
  debug_inspect(lens_test_name_nullish.get(document), content="None")
}

///|
test "PresenceLens nullable - replaces earlier optional and nullish policies" {
  let null_document = @json.parse("{\"name\":null}")
  let missing_document = @json.parse("{}")
  for
    lens in [lens_test_optional_then_nullable, lens_test_nullish_then_nullable] {
    debug_inspect(lens.get(null_document), content="None")
    let issue = get_presence_issue(lens, missing_document)
    inspect(issue.pointer.to_string(), content="/name")
    match issue.code {
      IssueCode::MissingProperty => ()
      _ => fail("expected MissingProperty")
    }
  }
}

///|
test "PresenceLens optional - replaces an earlier nullable policy" {
  let missing_document = @json.parse("{}")
  let null_document = @json.parse("{\"name\":null}")
  debug_inspect(
    lens_test_nullable_then_optional.get(missing_document),
    content="None",
  )
  let issue = get_presence_issue(
    lens_test_nullable_then_optional, null_document,
  )
  assert_type_mismatch(issue, "/name", JsonKind::String, JsonKind::Null)
}

///|
test "Lens nullish - returns None for JSON null" {
  let document = @json.parse("{\"name\":null}")
  debug_inspect(lens_test_name_nullish.get(document), content="None")
}

///|
test "Lens nullish - returns Some for a decoded value" {
  let document = @json.parse("{\"name\":\"Ada\"}")
  debug_inspect(lens_test_name_nullish.get(document), content="Some(\"Ada\")")
}
