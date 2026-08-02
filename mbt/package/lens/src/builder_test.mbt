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
  let user = @lens.object("user")
  user.string("name").set(builder, "Ada")
  user.int("age").set(builder, 37)
  user.bool("active").set(builder, true)
  user.number("score").set(builder, 42.5)
  user.json("metadata").set(builder, Json::object({ "role": "admin" }))
  user.string("roles").array().set(builder, ["admin", "reviewer"])
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
  let user = @lens.object("user")
  let nickname = user.string("nickname").optional()
  nickname.set(builder, Some("Ada"))
  nickname.set(builder, None)
  user.string("biography").nullable().set(builder, None)
  @json.json_inspect(builder, content={ "user": { "biography": null } })
}

///|
test "Lens set - uses the latest value at one pointer" {
  let builder = @lens.JsonBuilder::JsonBuilder()
  let name = @lens.root().string("name")
  name.set(builder, "Ada")
  name.set(builder, "Grace")
  @json.json_inspect(builder, content={ "name": "Grace" })
}

///|
test "JsonBuilder ToJson::to_json - isolates earlier output from later writes" {
  let builder = @lens.JsonBuilder::JsonBuilder()
  let name = @lens.root().string("name")
  name.set(builder, "Ada")
  let first = builder.to_json()
  name.set(builder, "Grace")
  @json.json_inspect(first, content={ "name": "Ada" })
}

///|
test "Lens set - reports a conflicting intermediate value" {
  let builder = @lens.JsonBuilder::JsonBuilder()
  @lens.root().json("user").set(builder, Json::string("invalid"))
  let issue = get_build_issue(() => {
    @lens.object("user").string("name").set(builder, "Ada")
  })
  inspect(issue.pointer.to_string(), content="/user")
  debug_inspect(issue.code, content="PathConflict")
  @json.json_inspect(builder, content={ "user": "invalid" })
}

///|
test "Lens set - selects how nullish None is encoded" {
  let builder = @lens.JsonBuilder::JsonBuilder()
  let root = @lens.root()
  root.string("omitted").nullish().set(builder, None)
  root
  .string("null")
  .nullish(encode_mode=@lens.NullishEncodeMode::Null)
  .set(builder, None)
  root.string("name").nullish().set(builder, Some("Ada"))
  @json.json_inspect(builder, content={ "null": null, "name": "Ada" })
}

///|
test "PresenceLens set - the last presence policy controls None" {
  let builder = @lens.JsonBuilder::JsonBuilder()
  let root = @lens.root()
  root.string("optionalThenNullable").optional().nullable().set(builder, None)
  root.string("nullishThenNullable").nullish().nullable().set(builder, None)
  root.string("nullableThenOptional").nullable().optional().set(builder, None)
  root
  .string("optionalThenNullish")
  .optional()
  .nullish(encode_mode=@lens.NullishEncodeMode::Null)
  .set(builder, None)
  @json.json_inspect(builder, content={
    "optionalThenNullable": null,
    "nullishThenNullable": null,
    "optionalThenNullish": null,
  })
}

///|
test "PresenceLens array - encodes None as null for every presence policy" {
  let builder = @lens.JsonBuilder::JsonBuilder()
  let root = @lens.root()
  root.string("optional").optional().array().set(builder, [Some("Ada"), None])
  root.string("nullable").nullable().array().set(builder, [Some("Ada"), None])
  root.string("nullish").nullish().array().set(builder, [Some("Ada"), None])
  @json.json_inspect(builder, content={
    "optional": ["Ada", null],
    "nullable": ["Ada", null],
    "nullish": ["Ada", null],
  })
}
