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
  match issue.code {
    @lens.JsonBuildIssueCode::PathConflict => ()
    _ => fail("expected PathConflict")
  }
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
test "Lens set - rejects omission inside an array" {
  let builder = @lens.JsonBuilder::JsonBuilder()
  @lens.root().string("status").set(builder, "ready")
  let issue = get_build_issue(() => {
    @lens.root()
    .string("names")
    .optional()
    .array()
    .set(builder, [Some("Ada"), None])
  })
  inspect(issue.pointer.to_string(), content="/names/1")
  match issue.code {
    @lens.JsonBuildIssueCode::OmissionNotAllowed => ()
    _ => fail("expected OmissionNotAllowed")
  }
  @json.json_inspect(builder, content={ "status": "ready" })
}
