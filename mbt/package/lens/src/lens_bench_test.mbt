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
/// Lenses intentionally excluded from the measured operation so lazy initialization can avoid constructing them.
#warnings("-unused_field")
struct UnusedLenses {
  timestamp : @lens.Lens[String]
  region : @lens.Lens[String]
  environment : @lens.Lens[String]
  user_id : @lens.Lens[String]
  user_email : @lens.Lens[String]
  user_role : @lens.Lens[String]
  user_locale : @lens.Lens[String]
  user_timezone : @lens.Lens[String]
  user_team : @lens.Lens[String]
  user_plan : @lens.Lens[String]
  project_name : @lens.Lens[String]
  project_visibility : @lens.Lens[String]
  project_member_count : @lens.Lens[Int]
  metrics_cached : @lens.Lens[Bool]
  metrics_bytes : @lens.Lens[Int]
  payload_kind : @lens.Lens[String]
  payload_items : @lens.Lens[Json]
  payload_checksum : @lens.Lens[String]
  flags_trace : @lens.Lens[Bool]
  flags_preview : @lens.Lens[Bool]
  flags_audit : @lens.Lens[Bool]
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
fn unused_lenses() -> UnusedLenses {
  let root = @lens.root()
  let user = root.object("user")
  let metadata = user.object("metadata")
  let project = root.object("project")
  let metrics = root.object("metrics")
  let payload = root.object("payload")
  let flags = root.object("flags")
  UnusedLenses::{
    timestamp: root.string("timestamp"),
    region: root.string("region"),
    environment: root.string("environment"),
    user_id: user.string("id"),
    user_email: user.string("email"),
    user_role: user.string("role"),
    user_locale: user.string("locale"),
    user_timezone: user.string("timezone"),
    user_team: metadata.string("team"),
    user_plan: metadata.string("plan"),
    project_name: project.string("name"),
    project_visibility: project.string("visibility"),
    project_member_count: project.int("memberCount"),
    metrics_cached: metrics.bool("cached"),
    metrics_bytes: metrics.int("bytes"),
    payload_kind: payload.string("kind"),
    payload_items: payload.json("items"),
    payload_checksum: payload.string("checksum"),
    flags_trace: flags.bool("trace"),
    flags_preview: flags.bool("preview"),
    flags_audit: flags.bool("audit"),
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
fn complex_checks(lenses : ComplexLenses) -> Array[&@lens.LensTrait] {
  [
    lenses.request_id,
    lenses.version,
    lenses.user_name,
    lenses.user_active,
    lenses.user_age,
    lenses.user_score,
    lenses.tags,
    lenses.project_id,
    lenses.project_archived,
    lenses.latency_ms,
    lenses.attempts,
    lenses.payload_title,
  ]
}

///|
fn validate_complex_with_standard_api(document : Json) -> Bool raise {
  let root = match_object(document)
  let user = match_object(match_property(root, "user"))
  let metadata = match_object(match_property(user, "metadata"))
  let project = match_object(match_property(root, "project"))
  let metrics = match_object(match_property(root, "metrics"))
  let payload = match_object(match_property(root, "payload"))
  match_string(match_property(root, "requestId")) |> ignore
  match_number(match_property(root, "version")).to_int() |> ignore
  match_string(match_property(user, "name")) |> ignore
  match_bool(match_property(user, "active")) |> ignore
  match_number(match_property(user, "age")).to_int() |> ignore
  match_number(match_property(user, "score")) |> ignore
  match_string_array(match_property(metadata, "tags")) |> ignore
  match_string(match_property(project, "id")) |> ignore
  match_bool(match_property(project, "archived")) |> ignore
  match_number(match_property(metrics, "latencyMs")) |> ignore
  match_number(match_property(metrics, "attempts")).to_int() |> ignore
  match_string(match_property(payload, "title")) |> ignore
  true
}

///|
fn validate_complex_with_lenses(
  checks : Array[&@lens.LensTrait],
  document : Json,
) -> Bool {
  match @lens.validate(document, checks) {
    @lens.Validation::Valid => true
    @lens.Validation::Invalid(_) => false
  }
}

///|
fn encode_complex_with_standard_api(value : ComplexResult) -> Json {
  Json::object({
    "requestId": value.request_id.to_json(),
    "version": value.version.to_json(),
    "user": Json::object({
      "name": value.user_name.to_json(),
      "active": value.user_active.to_json(),
      "age": value.user_age.to_json(),
      "score": value.user_score.to_json(),
      "metadata": Json::object({ "tags": value.tags.to_json() }),
    }),
    "project": Json::object({
      "id": value.project_id.to_json(),
      "archived": value.project_archived.to_json(),
    }),
    "metrics": Json::object({
      "latencyMs": value.latency_ms.to_json(),
      "attempts": value.attempts.to_json(),
    }),
    "payload": Json::object({ "title": value.payload_title.to_json() }),
  })
}

///|
fn encode_complex_with_lenses(
  lenses : ComplexLenses,
  value : ComplexResult,
) -> Json raise {
  let builder = @lens.JsonBuilder::JsonBuilder()
  lenses.request_id.set(builder, value.request_id)
  lenses.version.set(builder, value.version)
  lenses.user_name.set(builder, value.user_name)
  lenses.user_active.set(builder, value.user_active)
  lenses.user_age.set(builder, value.user_age)
  lenses.user_score.set(builder, value.user_score)
  lenses.tags.set(builder, value.tags)
  lenses.project_id.set(builder, value.project_id)
  lenses.project_archived.set(builder, value.project_archived)
  lenses.latency_ms.set(builder, value.latency_ms)
  lenses.attempts.set(builder, value.attempts)
  lenses.payload_title.set(builder, value.payload_title)
  builder.to_json()
}

///|
test "Lens benchmark fixtures - standard API and lens operations agree" {
  let document = complex_document()
  let lenses = complex_lenses()
  let value = decode_complex_with_patterns(document)
  inspect(value == decode_complex_with_lenses(lenses, document), content="true")
  inspect(
    validate_complex_with_standard_api(document) &&
    validate_complex_with_lenses(complex_checks(lenses), document),
    content="true",
  )
  inspect(
    encode_complex_with_standard_api(value) ==
    encode_complex_with_lenses(lenses, value),
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
test "bench: complex lens initialization" (b : @bench.T) {
  b.bench(name="access_generation/eager_all", fn() {
    b.keep((complex_lenses(), unused_lenses()))
  })
  b.bench(name="access_generation/lazy_deferred_all", fn() {
    b.keep((@lazy.Lazy(complex_lenses), @lazy.Lazy(unused_lenses)))
  })
  b.bench(name="access_generation/lazy_force_used", fn() {
    let used = @lazy.Lazy(complex_lenses)
    let unused = @lazy.Lazy(unused_lenses)
    b.keep((used.force(), unused))
  })
  b.bench(name="access_generation/lazy_force_all", fn() {
    let used = @lazy.Lazy(complex_lenses)
    let unused = @lazy.Lazy(unused_lenses)
    b.keep((used.force(), unused.force()))
  })
  let cached_lenses = @lazy.Lazy(complex_lenses)
  let deferred_unused_lenses = @lazy.Lazy(unused_lenses)
  cached_lenses.force() |> ignore
  b.bench(name="access_generation/lazy_cached_force", fn() {
    b.keep((cached_lenses.force(), deferred_unused_lenses))
  })
  b.bench(name="validation/eager_all", fn() {
    b.keep((complex_checks(complex_lenses()), unused_lenses()))
  })
  b.bench(name="validation/lazy_deferred_all", fn() {
    b.keep(
      (
        @lazy.Lazy(() => complex_checks(complex_lenses())),
        @lazy.Lazy(unused_lenses),
      ),
    )
  })
  b.bench(name="validation/lazy_force_used", fn() {
    let used = @lazy.Lazy(() => complex_checks(complex_lenses()))
    let unused = @lazy.Lazy(unused_lenses)
    b.keep((used.force(), unused))
  })
  b.bench(name="validation/lazy_force_all", fn() {
    let used = @lazy.Lazy(() => complex_checks(complex_lenses()))
    let unused = @lazy.Lazy(unused_lenses)
    b.keep((used.force(), unused.force()))
  })
  let cached_checks = @lazy.Lazy(() => complex_checks(complex_lenses()))
  let deferred_unused_checks = @lazy.Lazy(unused_lenses)
  cached_checks.force() |> ignore
  b.bench(name="validation/lazy_cached_force", fn() {
    b.keep((cached_checks.force(), deferred_unused_checks))
  })
}

///|
test "bench: 33-property nested document with 12 typed reads" (b : @bench.T) {
  let document = complex_document()
  let lenses = complex_lenses()
  let lazy_lenses = @lazy.Lazy(() => lenses)
  let lazy_unused = @lazy.Lazy(unused_lenses)
  lazy_lenses.force() |> ignore
  b.bench(name="standard_api", fn() {
    b.keep(try! decode_complex_with_patterns(document))
  })
  b.bench(name="lens/prebuilt", fn() {
    b.keep(try! decode_complex_with_lenses(lenses, document))
  })
  b.bench(name="lens/eager_init", fn() {
    let unused = unused_lenses()
    b.keep(
      (try! decode_complex_with_lenses(complex_lenses(), document), unused),
    )
  })
  b.bench(name="lens/lazy_first_use", fn() {
    let deferred_lenses = @lazy.Lazy(complex_lenses)
    let deferred_unused = @lazy.Lazy(unused_lenses)
    b.keep(
      (
        try! decode_complex_with_lenses(deferred_lenses.force(), document),
        deferred_unused,
      ),
    )
  })
  b.bench(name="lens/lazy_cached", fn() {
    b.keep(
      (
        try! decode_complex_with_lenses(lazy_lenses.force(), document),
        lazy_unused,
      ),
    )
  })
}

///|
test "bench: 33-property nested document with 12 validation checks" (
  b : @bench.T,
) {
  let document = complex_document()
  let checks = complex_checks(complex_lenses())
  let lazy_checks = @lazy.Lazy(() => checks)
  let lazy_unused = @lazy.Lazy(unused_lenses)
  lazy_checks.force() |> ignore
  b.bench(name="standard_api", fn() {
    b.keep(try! validate_complex_with_standard_api(document))
  })
  b.bench(name="lens/prebuilt", fn() {
    b.keep(validate_complex_with_lenses(checks, document))
  })
  b.bench(name="lens/eager_init", fn() {
    let unused = unused_lenses()
    b.keep(
      (
        validate_complex_with_lenses(complex_checks(complex_lenses()), document),
        unused,
      ),
    )
  })
  b.bench(name="lens/lazy_first_use", fn() {
    let deferred_checks = @lazy.Lazy(() => complex_checks(complex_lenses()))
    let deferred_unused = @lazy.Lazy(unused_lenses)
    b.keep(
      (
        validate_complex_with_lenses(deferred_checks.force(), document),
        deferred_unused,
      ),
    )
  })
  b.bench(name="lens/lazy_cached", fn() {
    b.keep(
      (validate_complex_with_lenses(lazy_checks.force(), document), lazy_unused),
    )
  })
}

///|
test "bench: 12-field nested JSON generation" (b : @bench.T) {
  let document = complex_document()
  let value = decode_complex_with_patterns(document)
  let lenses = complex_lenses()
  let lazy_lenses = @lazy.Lazy(() => lenses)
  let lazy_unused = @lazy.Lazy(unused_lenses)
  lazy_lenses.force() |> ignore
  b.bench(name="standard_api", fn() {
    b.keep(encode_complex_with_standard_api(value))
  })
  b.bench(name="lens/prebuilt", fn() {
    b.keep(try! encode_complex_with_lenses(lenses, value))
  })
  b.bench(name="lens/eager_init", fn() {
    let unused = unused_lenses()
    b.keep((try! encode_complex_with_lenses(complex_lenses(), value), unused))
  })
  b.bench(name="lens/lazy_first_use", fn() {
    let deferred_lenses = @lazy.Lazy(complex_lenses)
    let deferred_unused = @lazy.Lazy(unused_lenses)
    b.keep(
      (
        try! encode_complex_with_lenses(deferred_lenses.force(), value),
        deferred_unused,
      ),
    )
  })
  b.bench(name="lens/lazy_cached", fn() {
    b.keep(
      (try! encode_complex_with_lenses(lazy_lenses.force(), value), lazy_unused),
    )
  })
}
