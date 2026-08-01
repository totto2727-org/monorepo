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
test "ObjectLens get - reads the selected object" {
  let document = @json.parse(
    "{\"user\":{\"name\":\"Ada\",\"metadata\":{\"role\":\"admin\"}}}",
  )
  debug_inspect(
    @lens.object("user").get(document),
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
  let user = @lens.object("user")
  let selected = user.get(document)
  selected.set("name", @json.parse("\"Grace\""))
  inspect(user.string("name").get(document), content="Ada")
}

///|
test "ObjectLens get - reports a selected non-object pointer" {
  let document = @json.parse("{\"user\":{\"profile\":\"invalid\"}}")
  let issue = get_object_issue(@lens.object("user").object("profile"), document)
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

///|
fn match_object(value : Json) -> Map[String, Json] raise {
  guard value is Json::Object(properties) else { fail("expected object") }
  properties
}

///|
fn match_property(properties : Map[String, Json], key : String) -> Json raise {
  guard properties.get(key) is Some(value) else { fail("expected property") }
  value
}

///|
fn match_string(value : Json) -> String raise {
  guard value is Json::String(string) else { fail("expected string") }
  string
}

///|
fn match_bool(value : Json) -> Bool raise {
  match value {
    Json::True => true
    Json::False => false
    _ => fail("expected boolean")
  }
}

///|
fn match_number(value : Json) -> Double raise {
  guard value is Json::Number(number, ..) else { fail("expected number") }
  number
}

///|
fn match_string_array(value : Json) -> Array[String] raise {
  guard value is Json::Array(items) else { fail("expected array") }
  items.map(item => match_string(item))
}

///|
fn match_root_property(document : Json, key : String) -> Json raise {
  match_property(match_object(document), key)
}

///|
fn match_nullable_string(document : Json, key : String) -> String? raise {
  match match_root_property(document, key) {
    Json::Null => None
    value => Some(match_string(value))
  }
}

///|
fn match_optional_string(document : Json, key : String) -> String? raise {
  let properties = match_object(document)
  match properties.get(key) {
    None => None
    Some(value) => Some(match_string(value))
  }
}

///|
fn match_nullish_string(document : Json, key : String) -> String? raise {
  let properties = match_object(document)
  match properties.get(key) {
    None | Some(Json::Null) => None
    Some(value) => Some(match_string(value))
  }
}

///|
fn simple_document() -> Json raise {
  @json.parse(
    "{\"object\":{\"nested\":\"value\"},\"string\":\"Ada\",\"bool\":true,\"number\":42.5,\"int\":42,\"json\":{\"kind\":\"raw\"},\"array\":[\"Ada\",\"Grace\",\"Lin\"],\"nullable\":null,\"nullish\":null}",
  )
}

///|
struct ComplexResult {
  request_id : String
  version : Int
  user_name : String
  user_active : Bool
  user_age : Int
  user_score : Double
  tags : Array[String]
  project_id : String
  project_archived : Bool
  latency_ms : Double
  attempts : Int
  payload_title : String
} derive(Eq)

///|
struct ComplexLenses {
  request_id : @lens.Lens[String]
  version : @lens.Lens[Int]
  user_name : @lens.Lens[String]
  user_active : @lens.Lens[Bool]
  user_age : @lens.Lens[Int]
  user_score : @lens.Lens[Double]
  tags : @lens.Lens[Array[String]]
  project_id : @lens.Lens[String]
  project_archived : @lens.Lens[Bool]
  latency_ms : @lens.Lens[Double]
  attempts : @lens.Lens[Int]
  payload_title : @lens.Lens[String]
}

///|
fn complex_document() -> Json raise {
  @json.parse(
    "{\"requestId\":\"req-2026-0001\",\"version\":7,\"timestamp\":\"2026-07-31T12:00:00Z\",\"region\":\"ap-northeast-1\",\"environment\":\"production\",\"user\":{\"id\":\"user-42\",\"name\":\"Ada Lovelace\",\"active\":true,\"age\":37,\"score\":98.75,\"email\":\"ada@example.com\",\"role\":\"admin\",\"locale\":\"en-GB\",\"timezone\":\"Europe/London\",\"metadata\":{\"team\":\"compiler\",\"plan\":\"enterprise\",\"tags\":[\"owner\",\"reviewer\",\"operator\"]}},\"project\":{\"id\":\"project-7\",\"name\":\"Lens benchmark\",\"archived\":false,\"visibility\":\"private\",\"memberCount\":24},\"metrics\":{\"latencyMs\":12.5,\"attempts\":3,\"cached\":true,\"bytes\":65536},\"payload\":{\"title\":\"Benchmark payload\",\"kind\":\"analysis\",\"items\":[{\"id\":1,\"value\":\"alpha\"},{\"id\":2,\"value\":\"beta\"},{\"id\":3,\"value\":\"gamma\"}],\"checksum\":\"sha256:0123456789abcdef\"},\"flags\":{\"trace\":false,\"preview\":true,\"audit\":true}}",
  )
}

///|
fn complex_lenses() -> ComplexLenses {
  let root = @lens.root()
  let user = root.object("user")
  let metadata = user.object("metadata")
  let project = root.object("project")
  let metrics = root.object("metrics")
  let payload = root.object("payload")
  ComplexLenses::{
    request_id: root.string("requestId"),
    version: root.int("version"),
    user_name: user.string("name"),
    user_active: user.bool("active"),
    user_age: user.int("age"),
    user_score: user.number("score"),
    tags: metadata.string("tags").array(),
    project_id: project.string("id"),
    project_archived: project.bool("archived"),
    latency_ms: metrics.number("latencyMs"),
    attempts: metrics.int("attempts"),
    payload_title: payload.string("title"),
  }
}

///|
fn decode_complex_with_patterns(document : Json) -> ComplexResult raise {
  let root = match_object(document)
  let user = match_object(match_property(root, "user"))
  let metadata = match_object(match_property(user, "metadata"))
  let project = match_object(match_property(root, "project"))
  let metrics = match_object(match_property(root, "metrics"))
  let payload = match_object(match_property(root, "payload"))
  ComplexResult::{
    request_id: match_string(match_property(root, "requestId")),
    version: match_number(match_property(root, "version")).to_int(),
    user_name: match_string(match_property(user, "name")),
    user_active: match_bool(match_property(user, "active")),
    user_age: match_number(match_property(user, "age")).to_int(),
    user_score: match_number(match_property(user, "score")),
    tags: match_string_array(match_property(metadata, "tags")),
    project_id: match_string(match_property(project, "id")),
    project_archived: match_bool(match_property(project, "archived")),
    latency_ms: match_number(match_property(metrics, "latencyMs")),
    attempts: match_number(match_property(metrics, "attempts")).to_int(),
    payload_title: match_string(match_property(payload, "title")),
  }
}

///|
fn decode_complex_with_lenses(
  lenses : ComplexLenses,
  document : Json,
) -> ComplexResult raise {
  ComplexResult::{
    request_id: lenses.request_id.get(document),
    version: lenses.version.get(document),
    user_name: lenses.user_name.get(document),
    user_active: lenses.user_active.get(document),
    user_age: lenses.user_age.get(document),
    user_score: lenses.user_score.get(document),
    tags: lenses.tags.get(document),
    project_id: lenses.project_id.get(document),
    project_archived: lenses.project_archived.get(document),
    latency_ms: lenses.latency_ms.get(document),
    attempts: lenses.attempts.get(document),
    payload_title: lenses.payload_title.get(document),
  }
}

///|
test "Lens benchmark fixtures - both decoders produce the same complex result" {
  let document = complex_document()
  inspect(
    decode_complex_with_patterns(document) ==
    decode_complex_with_lenses(complex_lenses(), document),
    content="true",
  )
}

///|
test "bench: simple lens output types" (b : @bench.T) {
  let document = simple_document()
  let root = @lens.root()
  let object_lens = root.object("object")
  let string_lens = root.string("string")
  let bool_lens = root.bool("bool")
  let number_lens = root.number("number")
  let int_lens = root.int("int")
  let json_lens = root.json("json")
  let array_lens = root.string("array").array()
  let nullable_lens = root.string("nullable").nullable()
  let optional_lens = root.string("optional").optional()
  let nullish_lens = root.string("nullish").nullish()
  b.bench(name="pattern_match/object", fn() {
    b.keep(try! match_object(match_root_property(document, "object")).copy())
  })
  b.bench(name="lens/object", fn() { b.keep(try! object_lens.get(document)) })
  b.bench(name="pattern_match/string", fn() {
    b.keep(try! match_string(match_root_property(document, "string")))
  })
  b.bench(name="lens/string", fn() { b.keep(try! string_lens.get(document)) })
  b.bench(name="pattern_match/bool", fn() {
    b.keep(try! match_bool(match_root_property(document, "bool")))
  })
  b.bench(name="lens/bool", fn() { b.keep(try! bool_lens.get(document)) })
  b.bench(name="pattern_match/number", fn() {
    b.keep(try! match_number(match_root_property(document, "number")))
  })
  b.bench(name="lens/number", fn() { b.keep(try! number_lens.get(document)) })
  b.bench(name="pattern_match/int", fn() {
    b.keep(try! match_number(match_root_property(document, "int")).to_int())
  })
  b.bench(name="lens/int", fn() { b.keep(try! int_lens.get(document)) })
  b.bench(name="pattern_match/json", fn() {
    b.keep(try! match_root_property(document, "json"))
  })
  b.bench(name="lens/json", fn() { b.keep(try! json_lens.get(document)) })
  b.bench(name="pattern_match/array", fn() {
    b.keep(try! match_string_array(match_root_property(document, "array")))
  })
  b.bench(name="lens/array", fn() { b.keep(try! array_lens.get(document)) })
  b.bench(name="pattern_match/nullable", fn() {
    b.keep(try! match_nullable_string(document, "nullable"))
  })
  b.bench(name="lens/nullable", fn() {
    b.keep(try! nullable_lens.get(document))
  })
  b.bench(name="pattern_match/optional", fn() {
    b.keep(try! match_optional_string(document, "optional"))
  })
  b.bench(name="lens/optional", fn() {
    b.keep(try! optional_lens.get(document))
  })
  b.bench(name="pattern_match/nullish", fn() {
    b.keep(try! match_nullish_string(document, "nullish"))
  })
  b.bench(name="lens/nullish", fn() { b.keep(try! nullish_lens.get(document)) })
}

///|
test "bench: 33-property nested document with 12 typed reads" (b : @bench.T) {
  let document = complex_document()
  let lenses = complex_lenses()
  b.bench(name="pattern_match", fn() {
    b.keep(try! decode_complex_with_patterns(document))
  })
  b.bench(name="lens", fn() {
    b.keep(try! decode_complex_with_lenses(lenses, document))
  })
}
