///|
let lens_test_user_object : @lens.ObjectLens = @lens.object("user")

///|
let lens_test_user_profile_object : @lens.ObjectLens = @lens.object("user").object(
  "profile",
)

///|
let lens_test_user_profile_name : @lens.Lens[String] = @lens.object("user")
  .object("profile")
  .string("name")

///|
let lens_test_user_profile_active : @lens.Lens[Bool] = @lens.object("user")
  .object("profile")
  .bool("active")

///|
let lens_test_user_profile_metadata : @lens.Lens[Json] = @lens.object("user")
  .object("profile")
  .json("metadata")

///|
let lens_test_user_name : @lens.Lens[String] = @lens.object("user").string(
  "name",
)

///|
let lens_test_root_name : @lens.Lens[String] = @lens.root().string("name")

///|
let lens_test_escaped_key : @lens.Lens[String] = @lens.object("a/b").string(
  "~key",
)

///|
let lens_test_empty_key : @lens.Lens[String] = @lens.root().string("")

///|
let lens_test_text : @lens.Lens[String] = @lens.root().string("text")

///|
let lens_test_flag : @lens.Lens[Bool] = @lens.root().bool("flag")

///|
let lens_test_number : @lens.Lens[Double] = @lens.root().number("number")

///|
let lens_test_integer : @lens.Lens[Int] = @lens.root().int("integer")

///|
let lens_test_ratio : @lens.Lens[Double] = @lens.root().number("ratio")

///|
let lens_test_maximum : @lens.Lens[Int] = @lens.root().int("maximum")

///|
let lens_test_minimum : @lens.Lens[Int] = @lens.root().int("minimum")

///|
let lens_test_positive_int : @lens.Lens[Int] = @lens.root().int("positive")

///|
let lens_test_negative_int : @lens.Lens[Int] = @lens.root().int("negative")

///|
let lens_test_positive_number : @lens.Lens[Double] = @lens.root().number(
  "positive",
)

///|
let lens_test_names_array : @lens.Lens[Array[String]] = @lens.root()
  .string("names")
  .array()

///|
let lens_test_name_nullable : @lens.Lens[String?] = @lens.root()
  .string("name")
  .nullable()

///|
let lens_test_name_optional : @lens.Lens[String?] = @lens.root()
  .string("name")
  .optional()

///|
let lens_test_user_name_optional : @lens.Lens[String?] = @lens.object("user")
  .string("name")
  .optional()

///|
let lens_test_name_nullish : @lens.Lens[String?] = @lens.root()
  .string("name")
  .nullish()

///|
fn[T] get_issue(lens : @lens.Lens[T], document : Json) -> @lens.Issue raise {
  try {
    lens.get(document) |> ignore
    fail("expected LensError")
  } catch {
    @lens.LensError::LensError(issue) => issue
    _ => fail("unexpected error")
  }
}

///|
fn get_object_issue(
  lens : @lens.ObjectLens,
  document : Json,
) -> @lens.Issue raise {
  try {
    lens.get(document) |> ignore
    fail("expected LensError")
  } catch {
    @lens.LensError::LensError(issue) => issue
    _ => fail("unexpected error")
  }
}

///|
fn assert_type_mismatch(
  issue : @lens.Issue,
  pointer : String,
  expected : @lens.JsonKind,
  actual : @lens.JsonKind,
) -> Unit raise {
  inspect(issue.pointer.to_string(), content=pointer)
  match issue.code {
    @lens.IssueCode::TypeMismatch(expected=found_expected, actual=found_actual) => {
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
test "Lens add_to_json_path - appends the lens pointer to the existing path" {
  let path = root_json_path().add_key("request")
  inspect(
    @lens.object("user").string("name").add_to_json_path(path),
    content="/request/user/name",
  )
}

///|
test "Lens json_decode_error - prefixes the path and preserves the message" {
  let path = root_json_path().add_key("request")
  let name_lens = @lens.object("user").string("name")
  let @json.JsonDecodeError::JsonDecodeError((error_path, message)) = name_lens.json_decode_error(
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
    @lens.object("user").string("name").get_or_json_decode_error(document, path),
    content="Ada",
  )
}

///|
test "Lens get_or_json_decode_error - converts a lens failure" {
  let document = @json.parse("{\"user\":{\"profile\":false}}")
  let path = root_json_path().add_key("request")
  try {
    @lens.object("user")
    .object("profile")
    .string("name")
    .get_or_json_decode_error(document, path)
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
    @lens.JsonKind::Object,
    @lens.JsonKind::String,
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
    @lens.IssueCode::MissingProperty => ()
    _ => fail("expected MissingProperty")
  }
}

///|
test "Lens get - reports an incompatible intermediate pointer" {
  let document = @json.parse("{\"user\":{\"profile\":\"invalid\"}}")
  let issue = get_issue(lens_test_user_profile_name, document)
  inspect(issue.pointer.to_string(), content="/user/profile")
  match issue.code {
    @lens.IssueCode::TypeMismatch(expected~, actual~) => {
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
    @lens.IssueCode::MissingProperty => ()
    _ => fail("expected MissingProperty")
  }
}

///|
test "Lens get - reports a non-object root at the root pointer" {
  let document = @json.parse("[]")
  let issue = get_issue(lens_test_root_name, document)
  assert_type_mismatch(issue, "", @lens.JsonKind::Object, @lens.JsonKind::Array)
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
    @lens.JsonKind::String,
    @lens.JsonKind::Boolean,
  )
  assert_type_mismatch(
    get_issue(lens_test_flag, document),
    "/flag",
    @lens.JsonKind::Boolean,
    @lens.JsonKind::Number,
  )
  assert_type_mismatch(
    get_issue(lens_test_number, document),
    "/number",
    @lens.JsonKind::Number,
    @lens.JsonKind::String,
  )
  assert_type_mismatch(
    get_issue(lens_test_integer, document),
    "/integer",
    @lens.JsonKind::Number,
    @lens.JsonKind::Null,
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
  assert_type_mismatch(
    issue,
    "/names/1",
    @lens.JsonKind::String,
    @lens.JsonKind::Boolean,
  )
}

///|
test "Lens array - rejects a non-array value" {
  let document = @json.parse("{\"names\":\"Ada\"}")
  let issue = get_issue(lens_test_names_array, document)
  assert_type_mismatch(
    issue,
    "/names",
    @lens.JsonKind::Array,
    @lens.JsonKind::String,
  )
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
  let issue = get_issue(lens_test_name_nullable, document)
  inspect(issue.pointer.to_string(), content="/name")
  match issue.code {
    @lens.IssueCode::MissingProperty => ()
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
  let issue = get_issue(lens_test_user_name_optional, document)
  inspect(issue.pointer.to_string(), content="/user")
  match issue.code {
    @lens.IssueCode::MissingProperty => ()
    _ => fail("expected MissingProperty")
  }
}

///|
test "Lens optional - rejects JSON null" {
  let document = @json.parse("{\"name\":null}")
  let issue = get_issue(lens_test_name_optional, document)
  assert_type_mismatch(
    issue,
    "/name",
    @lens.JsonKind::String,
    @lens.JsonKind::Null,
  )
}

///|
test "Lens nullish - returns None for a missing path" {
  let document = @json.parse("{}")
  debug_inspect(lens_test_name_nullish.get(document), content="None")
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
