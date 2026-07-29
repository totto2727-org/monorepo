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
test "Lens get - reads finite numbers and exact integers" {
  let document = @json.parse(
    "{\"ratio\":42.5,\"maximum\":2147483647,\"minimum\":-2147483648}",
  )
  inspect(@lens.root().number("ratio").get(document), content="42.5")
  inspect(@lens.root().int("maximum").get(document), content="2147483647")
  inspect(@lens.root().int("minimum").get(document), content="-2147483648")
}

///|
test "Lens get - rejects fractional integers" {
  let document = @json.parse("{\"age\":42.5}")
  let issue = get_issue(@lens.root().int("age"), document)
  inspect(issue.pointer.to_string(), content="/age")
  match issue.code {
    @lens.IssueCode::InvalidInteger => ()
    _ => fail("expected InvalidInteger")
  }
}

///|
test "Lens get - rejects integers outside the Int range" {
  let document = @json.parse(
    "{\"positive\":2147483648,\"negative\":-2147483649}",
  )
  let positive = get_issue(@lens.root().int("positive"), document)
  inspect(positive.pointer.to_string(), content="/positive")
  match positive.code {
    @lens.IssueCode::NumberOutOfRange(target~) => inspect(target, content="Int")
    _ => fail("expected NumberOutOfRange")
  }
  let negative = get_issue(@lens.root().int("negative"), document)
  inspect(negative.pointer.to_string(), content="/negative")
  match negative.code {
    @lens.IssueCode::NumberOutOfRange(target~) => inspect(target, content="Int")
    _ => fail("expected NumberOutOfRange")
  }
}

///|
test "Lens get - rejects non-finite numbers" {
  let document = @json.parse("{\"ratio\":1e999}")
  let issue = get_issue(@lens.root().number("ratio"), document)
  inspect(issue.pointer.to_string(), content="/ratio")
  match issue.code {
    @lens.IssueCode::NumberOutOfRange(target~) =>
      inspect(target, content="Double")
    _ => fail("expected NumberOutOfRange")
  }
}
