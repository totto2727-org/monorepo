///|
test "validate - reports success without constructing typed values" {
  let document = @json.parse(
    "{\"user\":{\"name\":\"Ada\",\"age\":37,\"active\":true}}",
  )
  let user = @lens.object("user")
  let name_lens = user.string("name")
  let age_lens = user.int("age")
  let active_lens = user.bool("active")
  match
    @lens.validate(document, [
      name_lens.check(),
      age_lens.check(),
      active_lens.check(),
    ]) {
    @lens.Validation::Valid => {
      inspect(name_lens.get(document), content="Ada")
      inspect(age_lens.get(document), content="37")
      inspect(active_lens.get(document), content="true")
    }
    @lens.Validation::Invalid(_) => fail("expected Valid")
  }
}

///|
test "validate - collects all issues in check order" {
  let document = @json.parse("{\"user\":{\"age\":42.5,\"active\":\"yes\"}}")
  let user = @lens.object("user")
  let validation = @lens.validate(document, [
    user.string("name").check(),
    user.int("age").check(),
    user.bool("active").check(),
  ])
  match validation {
    @lens.Validation::Invalid(issues) => {
      inspect(issues.length(), content="3")
      inspect(issues[0].pointer.to_string(), content="/user/name")
      inspect(issues[1].pointer.to_string(), content="/user/age")
      inspect(issues[2].pointer.to_string(), content="/user/active")
      match (issues[0].code, issues[1].code, issues[2].code) {
        (
          @lens.IssueCode::MissingProperty,
          @lens.IssueCode::InvalidInteger,
          @lens.IssueCode::TypeMismatch(
            expected=@lens.JsonKind::Boolean,
            actual=@lens.JsonKind::String
          ),
        ) => ()
        _ => fail("unexpected issue order or code")
      }
    }
    @lens.Validation::Valid => fail("expected Invalid")
  }
}

///|
test "validate - accepts an empty check list" {
  let document = @json.parse("{}")
  match @lens.validate(document, []) {
    @lens.Validation::Valid => ()
    @lens.Validation::Invalid(_) => fail("expected Valid")
  }
}
