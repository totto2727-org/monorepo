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
let simple_object_lens : @lens.ObjectLens = @lens.root().object("object")

///|
let simple_string_lens : @lens.Lens[String] = @lens.root().string("string")

///|
let simple_bool_lens : @lens.Lens[Bool] = @lens.root().bool("bool")

///|
let simple_number_lens : @lens.Lens[Double] = @lens.root().number("number")

///|
let simple_int_lens : @lens.Lens[Int] = @lens.root().int("int")

///|
let simple_json_lens : @lens.Lens[Json] = @lens.root().json("json")

///|
let simple_array_lens : @lens.Lens[Array[String]] = @lens.root()
  .string("array")
  .array()

///|
let simple_nullable_lens : @lens.PresenceLens[String] = @lens.root()
  .string("nullable")
  .nullable()

///|
let simple_optional_lens : @lens.PresenceLens[String] = @lens.root()
  .string("optional")
  .optional()

///|
let simple_nullish_lens : @lens.PresenceLens[String] = @lens.root()
  .string("nullish")
  .nullish()

///|
let complex_lenses : ComplexLenses = {
  request_id: @lens.root().string("requestId"),
  version: @lens.root().int("version"),
  user_name: @lens.root().object("user").string("name"),
  user_active: @lens.root().object("user").bool("active"),
  user_age: @lens.root().object("user").int("age"),
  user_score: @lens.root().object("user").number("score"),
  tags: @lens.root().object("user").object("metadata").string("tags").array(),
  project_id: @lens.root().object("project").string("id"),
  project_archived: @lens.root().object("project").bool("archived"),
  latency_ms: @lens.root().object("metrics").number("latencyMs"),
  attempts: @lens.root().object("metrics").int("attempts"),
  payload_title: @lens.root().object("payload").string("title"),
}

///|
fn complex_document() -> Json raise {
  @json.parse(
    "{\"requestId\":\"req-2026-0001\",\"version\":7,\"timestamp\":\"2026-07-31T12:00:00Z\",\"region\":\"ap-northeast-1\",\"environment\":\"production\",\"user\":{\"id\":\"user-42\",\"name\":\"Ada Lovelace\",\"active\":true,\"age\":37,\"score\":98.75,\"email\":\"ada@example.com\",\"role\":\"admin\",\"locale\":\"en-GB\",\"timezone\":\"Europe/London\",\"metadata\":{\"team\":\"compiler\",\"plan\":\"enterprise\",\"tags\":[\"owner\",\"reviewer\",\"operator\"]}},\"project\":{\"id\":\"project-7\",\"name\":\"Lens benchmark\",\"archived\":false,\"visibility\":\"private\",\"memberCount\":24},\"metrics\":{\"latencyMs\":12.5,\"attempts\":3,\"cached\":true,\"bytes\":65536},\"payload\":{\"title\":\"Benchmark payload\",\"kind\":\"analysis\",\"items\":[{\"id\":1,\"value\":\"alpha\"},{\"id\":2,\"value\":\"beta\"},{\"id\":3,\"value\":\"gamma\"}],\"checksum\":\"sha256:0123456789abcdef\"},\"flags\":{\"trace\":false,\"preview\":true,\"audit\":true}}",
  )
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
    decode_complex_with_lenses(complex_lenses, document),
    content="true",
  )
}

///|
test "bench: simple lens output types" (b : @bench.T) {
  let document = simple_document()
  b.bench(name="pattern_match/object", fn() {
    b.keep(try! match_object(match_root_property(document, "object")).copy())
  })
  b.bench(name="lens/object", fn() {
    b.keep(try! simple_object_lens.get(document))
  })
  b.bench(name="pattern_match/string", fn() {
    b.keep(try! match_string(match_root_property(document, "string")))
  })
  b.bench(name="lens/string", fn() {
    b.keep(try! simple_string_lens.get(document))
  })
  b.bench(name="pattern_match/bool", fn() {
    b.keep(try! match_bool(match_root_property(document, "bool")))
  })
  b.bench(name="lens/bool", fn() { b.keep(try! simple_bool_lens.get(document)) })
  b.bench(name="pattern_match/number", fn() {
    b.keep(try! match_number(match_root_property(document, "number")))
  })
  b.bench(name="lens/number", fn() {
    b.keep(try! simple_number_lens.get(document))
  })
  b.bench(name="pattern_match/int", fn() {
    b.keep(try! match_number(match_root_property(document, "int")).to_int())
  })
  b.bench(name="lens/int", fn() { b.keep(try! simple_int_lens.get(document)) })
  b.bench(name="pattern_match/json", fn() {
    b.keep(try! match_root_property(document, "json"))
  })
  b.bench(name="lens/json", fn() { b.keep(try! simple_json_lens.get(document)) })
  b.bench(name="pattern_match/array", fn() {
    b.keep(try! match_string_array(match_root_property(document, "array")))
  })
  b.bench(name="lens/array", fn() {
    b.keep(try! simple_array_lens.get(document))
  })
  b.bench(name="pattern_match/nullable", fn() {
    b.keep(try! match_nullable_string(document, "nullable"))
  })
  b.bench(name="lens/nullable", fn() {
    b.keep(try! simple_nullable_lens.get(document))
  })
  b.bench(name="pattern_match/optional", fn() {
    b.keep(try! match_optional_string(document, "optional"))
  })
  b.bench(name="lens/optional", fn() {
    b.keep(try! simple_optional_lens.get(document))
  })
  b.bench(name="pattern_match/nullish", fn() {
    b.keep(try! match_nullish_string(document, "nullish"))
  })
  b.bench(name="lens/nullish", fn() {
    b.keep(try! simple_nullish_lens.get(document))
  })
}

///|
test "bench: 33-property nested document with 12 typed reads" (b : @bench.T) {
  let document = complex_document()
  b.bench(name="pattern_match", fn() {
    b.keep(try! decode_complex_with_patterns(document))
  })
  b.bench(name="lens", fn() {
    b.keep(try! decode_complex_with_lenses(complex_lenses, document))
  })
}
