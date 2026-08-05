///|
/// White-box coverage may construct read-only diagnostic variants.
let validation_user_lens : ObjectLens = object("user")

///|
let validation_name_lens : Lens[String] = object("user").string("name")

///|
let validation_age_lens : Lens[Int] = object("user").int("age")

///|
let validation_active_lens : Lens[Bool] = object("user").bool("active")

///|
test "validate - accepts heterogeneous lenses without conversion" {
  let document = @json.parse(
    "{\"user\":{\"name\":\"Ada\",\"age\":37,\"active\":true}}",
  )
  match
    validate(document, [
      validation_user_lens, validation_name_lens, validation_age_lens, validation_active_lens,
    ]) {
    Validation::Valid => {
      inspect(validation_name_lens.get(document), content="Ada")
      inspect(validation_age_lens.get(document), content="37")
      inspect(validation_active_lens.get(document), content="true")
    }
    Validation::Invalid(_) => fail("expected Valid")
  }
}

///|
test "validate - collects all issues in check order" {
  let document = @json.parse("{\"user\":{\"age\":\"old\",\"active\":\"yes\"}}")
  let validation = validate(document, [
    validation_user_lens, validation_name_lens, validation_age_lens, validation_active_lens,
  ])
  match validation {
    Validation::Invalid(issues) => {
      inspect(issues.length(), content="3")
      inspect(issues[0].pointer.to_string(), content="/user/name")
      inspect(issues[1].pointer.to_string(), content="/user/age")
      inspect(issues[2].pointer.to_string(), content="/user/active")
      match (issues[0].code, issues[1].code, issues[2].code) {
        (
          IssueCode::MissingProperty,
          IssueCode::TypeMismatch(
            expected=JsonKind::Number,
            actual=JsonKind::String
          ),
          IssueCode::TypeMismatch(
            expected=JsonKind::Boolean,
            actual=JsonKind::String
          ),
        ) => ()
        _ => fail("unexpected issue order or code")
      }
    }
    Validation::Valid => fail("expected Invalid")
  }
}

///|
test "validate - accepts an empty check list" {
  let document = @json.parse("{}")
  match validate(document, []) {
    Validation::Valid => ()
    Validation::Invalid(_) => fail("expected Valid")
  }
}
