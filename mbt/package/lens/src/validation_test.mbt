///|
let validation_user_lens : @lens.ObjectLens = @lens.object("user")

///|
let validation_name_lens : @lens.Lens[String] = @lens.object("user").string(
  "name",
)

///|
let validation_age_lens : @lens.Lens[Int] = @lens.object("user").int("age")

///|
let validation_active_lens : @lens.Lens[Bool] = @lens.object("user").bool(
  "active",
)

///|
test "validate - accepts heterogeneous lenses without conversion" {
  let document = @json.parse(
    "{\"user\":{\"name\":\"Ada\",\"age\":37,\"active\":true}}",
  )
  match
    @lens.validate(document, [
      validation_user_lens, validation_name_lens, validation_age_lens, validation_active_lens,
    ]) {
    @lens.Validation::Valid => {
      inspect(validation_name_lens.get(document), content="Ada")
      inspect(validation_age_lens.get(document), content="37")
      inspect(validation_active_lens.get(document), content="true")
    }
    @lens.Validation::Invalid(_) => fail("expected Valid")
  }
}

///|
test "validate - collects all issues in check order" {
  let document = @json.parse("{\"user\":{\"age\":\"old\",\"active\":\"yes\"}}")
  let validation = @lens.validate(document, [
    validation_user_lens, validation_name_lens, validation_age_lens, validation_active_lens,
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
          @lens.IssueCode::TypeMismatch(
            expected=@lens.JsonKind::Number,
            actual=@lens.JsonKind::String
          ),
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
