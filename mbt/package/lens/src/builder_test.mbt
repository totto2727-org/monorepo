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
let builder_test_user_nickname : @lens.PresenceLens[String] = @lens.object(
    "user",
  )
  .string("nickname")
  .optional()

///|
let builder_test_user_biography : @lens.PresenceLens[String] = @lens.object(
    "user",
  )
  .string("biography")
  .nullable()

///|
let builder_test_root_name : @lens.Lens[String] = @lens.root().string("name")

///|
let builder_test_root_user : @lens.Lens[Json] = @lens.root().json("user")

///|
let builder_test_omitted : @lens.PresenceLens[String] = @lens.root()
  .string("omitted")
  .nullish()

///|
let builder_test_null : @lens.PresenceLens[String] = @lens.root()
  .string("null")
  .nullish(encode_mode=@lens.NullishEncodeMode::Null)

///|
let builder_test_nullish_name : @lens.PresenceLens[String] = @lens.root()
  .string("name")
  .nullish()

///|
let builder_test_optional_then_nullable : @lens.PresenceLens[String] = @lens.root()
  .string("optionalThenNullable")
  .optional()
  .nullable()

///|
let builder_test_nullish_then_nullable : @lens.PresenceLens[String] = @lens.root()
  .string("nullishThenNullable")
  .nullish()
  .nullable()

///|
let builder_test_nullable_then_optional : @lens.PresenceLens[String] = @lens.root()
  .string("nullableThenOptional")
  .nullable()
  .optional()

///|
let builder_test_optional_then_nullish : @lens.PresenceLens[String] = @lens.root()
  .string("optionalThenNullish")
  .optional()
  .nullish(encode_mode=@lens.NullishEncodeMode::Null)

///|
let builder_test_optional_array : @lens.Lens[Array[String?]] = @lens.root()
  .string("optional")
  .optional()
  .array()

///|
let builder_test_nullable_array : @lens.Lens[Array[String?]] = @lens.root()
  .string("nullable")
  .nullable()
  .array()

///|
let builder_test_nullish_array : @lens.Lens[Array[String?]] = @lens.root()
  .string("nullish")
  .nullish()
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
  debug_inspect(issue.code, content="PathConflict")
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
test "PresenceLens set - the last presence policy controls None" {
  let builder = @lens.JsonBuilder::JsonBuilder()
  builder_test_optional_then_nullable.set(builder, None)
  builder_test_nullish_then_nullable.set(builder, None)
  builder_test_nullable_then_optional.set(builder, None)
  builder_test_optional_then_nullish.set(builder, None)
  @json.json_inspect(builder, content={
    "optionalThenNullable": null,
    "nullishThenNullable": null,
    "optionalThenNullish": null,
  })
}

///|
test "PresenceLens array - encodes None as null for every presence policy" {
  let builder = @lens.JsonBuilder::JsonBuilder()
  builder_test_optional_array.set(builder, [Some("Ada"), None])
  builder_test_nullable_array.set(builder, [Some("Ada"), None])
  builder_test_nullish_array.set(builder, [Some("Ada"), None])
  @json.json_inspect(builder, content={
    "optional": ["Ada", null],
    "nullable": ["Ada", null],
    "nullish": ["Ada", null],
  })
}
