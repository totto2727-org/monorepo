///|
let builder_test_user_name : @lens.Lens[String] = @lens.object("user").string(
  "name",
)

///|
let builder_test_user_age : @lens.Lens[Int] = @lens.object("user").int("age")

///|
let builder_test_user_active : @lens.Lens[Bool] = @lens.object("user").bool(
  "active",
)

///|
let builder_test_user_score : @lens.Lens[Double] = @lens.object("user").number(
  "score",
)

///|
let builder_test_user_metadata : @lens.Lens[Json] = @lens.object("user").json(
  "metadata",
)

///|
let builder_test_user_roles : @lens.Lens[Array[String]] = @lens.object("user")
  .string("roles")
  .array()

///|
let builder_test_user_nickname : @lens.Lens[String?] = @lens.object("user")
  .string("nickname")
  .optional()

///|
let builder_test_user_biography : @lens.Lens[String?] = @lens.object("user")
  .string("biography")
  .nullable()

///|
let builder_test_root_name : @lens.Lens[String] = @lens.root().string("name")

///|
let builder_test_root_user : @lens.Lens[Json] = @lens.root().json("user")

///|
let builder_test_omitted : @lens.Lens[String?] = @lens.root()
  .string("omitted")
  .nullish()

///|
let builder_test_null : @lens.Lens[String?] = @lens.root()
  .string("null")
  .nullish(encode_mode=@lens.NullishEncodeMode::Null)

///|
let builder_test_nullish_name : @lens.Lens[String?] = @lens.root()
  .string("name")
  .nullish()

///|
let builder_test_status : @lens.Lens[String] = @lens.root().string("status")

///|
let builder_test_optional_names : @lens.Lens[Array[String?]] = @lens.root()
  .string("names")
  .optional()
  .array()

///|
fn get_build_issue(write : () -> Unit raise) -> @lens.JsonBuildIssue raise {
  try {
    write()
    fail("expected JsonBuildError")
  } catch {
    @lens.JsonBuildError::JsonBuildError(issue) => issue
    _ => fail("unexpected error")
  }
}

///|
test "JsonBuilder ToJson::to_json - builds a nested typed object" {
  let builder = @lens.JsonBuilder::JsonBuilder()
  builder_test_user_name.set(builder, "Ada")
  builder_test_user_age.set(builder, 37)
  builder_test_user_active.set(builder, true)
  builder_test_user_score.set(builder, 42.5)
  builder_test_user_metadata.set(builder, Json::object({ "role": "admin" }))
  builder_test_user_roles.set(builder, ["admin", "reviewer"])
  @json.json_inspect(builder, content={
    "user": {
      "name": "Ada",
      "age": 37,
      "active": true,
      "score": 42.5,
      "metadata": { "role": "admin" },
      "roles": ["admin", "reviewer"],
    },
  })
}

///|
test "Lens set - omits optional values and emits nullable null" {
  let builder = @lens.JsonBuilder::JsonBuilder()
  builder_test_user_nickname.set(builder, Some("Ada"))
  builder_test_user_nickname.set(builder, None)
  builder_test_user_biography.set(builder, None)
  @json.json_inspect(builder, content={ "user": { "biography": null } })
}

///|
test "Lens set - uses the latest value at one pointer" {
  let builder = @lens.JsonBuilder::JsonBuilder()
  builder_test_root_name.set(builder, "Ada")
  builder_test_root_name.set(builder, "Grace")
  @json.json_inspect(builder, content={ "name": "Grace" })
}

///|
test "JsonBuilder ToJson::to_json - isolates earlier output from later writes" {
  let builder = @lens.JsonBuilder::JsonBuilder()
  builder_test_root_name.set(builder, "Ada")
  let first = builder.to_json()
  builder_test_root_name.set(builder, "Grace")
  @json.json_inspect(first, content={ "name": "Ada" })
}

///|
test "Lens set - reports a conflicting intermediate value" {
  let builder = @lens.JsonBuilder::JsonBuilder()
  builder_test_root_user.set(builder, Json::string("invalid"))
  let issue = get_build_issue(() => builder_test_user_name.set(builder, "Ada"))
  inspect(issue.pointer.to_string(), content="/user")
  match issue.code {
    @lens.JsonBuildIssueCode::PathConflict => ()
    _ => fail("expected PathConflict")
  }
  @json.json_inspect(builder, content={ "user": "invalid" })
}

///|
test "Lens set - selects how nullish None is encoded" {
  let builder = @lens.JsonBuilder::JsonBuilder()
  builder_test_omitted.set(builder, None)
  builder_test_null.set(builder, None)
  builder_test_nullish_name.set(builder, Some("Ada"))
  @json.json_inspect(builder, content={ "null": null, "name": "Ada" })
}

///|
test "Lens set - rejects omission inside an array" {
  let builder = @lens.JsonBuilder::JsonBuilder()
  builder_test_status.set(builder, "ready")
  let issue = get_build_issue(() => {
    builder_test_optional_names.set(builder, [Some("Ada"), None])
  })
  inspect(issue.pointer.to_string(), content="/names/1")
  match issue.code {
    @lens.JsonBuildIssueCode::OmissionNotAllowed => ()
    _ => fail("expected OmissionNotAllowed")
  }
  @json.json_inspect(builder, content={ "status": "ready" })
}
