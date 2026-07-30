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
test "Lens get - reads nested typed values" {
  let document = @json.parse(
    "{\"user\":{\"profile\":{\"name\":\"Ada\",\"active\":true,\"metadata\":{\"role\":\"admin\"}}}}",
  )
  let profile = @lens.object("user").object("profile")
  inspect(profile.string("name").get(document), content="Ada")
  inspect(profile.bool("active").get(document), content="true")
  inspect(
    profile.json("metadata").get(document).stringify(),
    content="{\"role\":\"admin\"}",
  )
}

///|
test "Lens get - reuses one lens across documents" {
  let name_lens = @lens.object("user").string("name")
  let first = @json.parse("{\"user\":{\"name\":\"Ada\"}}")
  let second = @json.parse("{\"user\":{\"name\":\"Grace\"}}")
  inspect(name_lens.get(first), content="Ada")
  inspect(name_lens.get(second), content="Grace")
}

///|
test "Lens get - reports a missing leaf pointer" {
  let document = @json.parse("{\"user\":{\"profile\":{}}}")
  let issue = get_issue(
    @lens.object("user").object("profile").string("name"),
    document,
  )
  inspect(issue.pointer.to_string(), content="/user/profile/name")
  match issue.code {
    @lens.IssueCode::MissingProperty => ()
    _ => fail("expected MissingProperty")
  }
}

///|
test "Lens get - reports an incompatible intermediate pointer" {
  let document = @json.parse("{\"user\":{\"profile\":\"invalid\"}}")
  let issue = get_issue(
    @lens.object("user").object("profile").string("name"),
    document,
  )
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
  let issue = get_issue(
    @lens.object("user").object("profile").string("name"),
    document,
  )
  inspect(issue.pointer.to_string(), content="/user/profile")
  match issue.code {
    @lens.IssueCode::MissingProperty => ()
    _ => fail("expected MissingProperty")
  }
}

///|
test "Lens get - reports a non-object root at the root pointer" {
  let document = @json.parse("[]")
  let issue = get_issue(@lens.root().string("name"), document)
  assert_type_mismatch(issue, "", @lens.JsonKind::Object, @lens.JsonKind::Array)
}

///|
test "Lens get - escapes JSON Pointer keys in errors" {
  let document = @json.parse("{\"a/b\":{}}")
  let issue = get_issue(@lens.object("a/b").string("~key"), document)
  inspect(issue.pointer.to_string(), content="/a~1b/~0key")
}

///|
test "Lens get - renders an empty key as one pointer segment" {
  let document = @json.parse("{}")
  let issue = get_issue(@lens.root().string(""), document)
  inspect(issue.pointer.to_string(), content="/")
}

///|
test "Lens get - classifies primitive type mismatches" {
  let document = @json.parse(
    "{\"text\":false,\"flag\":0,\"number\":\"0\",\"integer\":null}",
  )
  assert_type_mismatch(
    get_issue(@lens.root().string("text"), document),
    "/text",
    @lens.JsonKind::String,
    @lens.JsonKind::Boolean,
  )
  assert_type_mismatch(
    get_issue(@lens.root().bool("flag"), document),
    "/flag",
    @lens.JsonKind::Boolean,
    @lens.JsonKind::Number,
  )
  assert_type_mismatch(
    get_issue(@lens.root().number("number"), document),
    "/number",
    @lens.JsonKind::Number,
    @lens.JsonKind::String,
  )
  assert_type_mismatch(
    get_issue(@lens.root().int("integer"), document),
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
  inspect(@lens.root().number("ratio").get(document), content="42.5")
  inspect(@lens.root().int("maximum").get(document), content="2147483647")
  inspect(@lens.root().int("minimum").get(document), content="-2147483648")
}

///|
test "Lens get - delegates fractional conversion to Double::to_int" {
  let document = @json.parse("{\"positive\":42.5,\"negative\":-42.5}")
  inspect(@lens.root().int("positive").get(document), content="42")
  inspect(@lens.root().int("negative").get(document), content="-42")
}

///|
test "Lens get - delegates saturating conversion to Double::to_int" {
  let document = @json.parse(
    "{\"positive\":2147483648,\"negative\":-2147483649}",
  )
  inspect(@lens.root().int("positive").get(document), content="2147483647")
  inspect(@lens.root().int("negative").get(document), content="-2147483648")
}

///|
test "Lens get - passes through non-finite numbers" {
  let document = @json.parse("{\"positive\":1e999,\"negative\":-1e999}")
  inspect(
    @lens.root().number("positive").get(document).is_inf(),
    content="true",
  )
  inspect(@lens.root().int("positive").get(document), content="2147483647")
  inspect(@lens.root().int("negative").get(document), content="-2147483648")
}

///|
test "Lens array - decodes every item" {
  let document = @json.parse("{\"names\":[\"Ada\",\"Grace\"]}")
  debug_inspect(
    @lens.root().string("names").array().get(document),
    content="[\"Ada\", \"Grace\"]",
  )
}

///|
test "Lens array - reports an item pointer" {
  let document = @json.parse("{\"names\":[\"Ada\",false]}")
  let issue = get_issue(@lens.root().string("names").array(), document)
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
  let issue = get_issue(@lens.root().string("names").array(), document)
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
  debug_inspect(
    @lens.root().string("name").nullable().get(document),
    content="None",
  )
}

///|
test "Lens nullable - returns Some for a decoded value" {
  let document = @json.parse("{\"name\":\"Ada\"}")
  debug_inspect(
    @lens.root().string("name").nullable().get(document),
    content="Some(\"Ada\")",
  )
}

///|
test "Lens nullable - preserves missing-property errors" {
  let document = @json.parse("{}")
  let issue = get_issue(@lens.root().string("name").nullable(), document)
  inspect(issue.pointer.to_string(), content="/name")
  match issue.code {
    @lens.IssueCode::MissingProperty => ()
    _ => fail("expected MissingProperty")
  }
}

///|
test "Lens optional - returns None for a missing path" {
  let document = @json.parse("{}")
  debug_inspect(
    @lens.root().string("name").optional().get(document),
    content="None",
  )
}

///|
test "Lens optional - returns Some for a decoded value" {
  let document = @json.parse("{\"name\":\"Ada\"}")
  debug_inspect(
    @lens.root().string("name").optional().get(document),
    content="Some(\"Ada\")",
  )
}

///|
test "Lens optional - preserves a missing intermediate error" {
  let document = @json.parse("{}")
  let issue = get_issue(
    @lens.object("user").string("name").optional(),
    document,
  )
  inspect(issue.pointer.to_string(), content="/user")
  match issue.code {
    @lens.IssueCode::MissingProperty => ()
    _ => fail("expected MissingProperty")
  }
}

///|
test "Lens optional - rejects JSON null" {
  let document = @json.parse("{\"name\":null}")
  let issue = get_issue(@lens.root().string("name").optional(), document)
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
  debug_inspect(
    @lens.root().string("name").nullish().get(document),
    content="None",
  )
}

///|
test "Lens nullish - returns None for JSON null" {
  let document = @json.parse("{\"name\":null}")
  debug_inspect(
    @lens.root().string("name").nullish().get(document),
    content="None",
  )
}

///|
test "Lens nullish - returns Some for a decoded value" {
  let document = @json.parse("{\"name\":\"Ada\"}")
  debug_inspect(
    @lens.root().string("name").nullish().get(document),
    content="Some(\"Ada\")",
  )
}
