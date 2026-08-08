# lens

Reusable typed access, construction, and aggregate validation for MoonBit JSON values.

The package keeps static types on `Lens[T]`. Applying `nullable`, `optional`, or `nullish` produces `PresenceLens[T]`, whose reads and writes use `T?` without nesting options. `ObjectLens` reads selected objects as `Map[String, Json]`. The returned map is copied so top-level mutations do not change the source document; nested `Json` values retain their normal sharing semantics. A `JsonBuilder` accepts typed values through the same lenses and implements `ToJson`. Validation only reports whether every requested read succeeds; it does not infer or construct application types from runtime definitions. After successful validation, read values through the original lenses.

## Typed access

```mbt check
test {
  let document = @json.parse(
    "{\"user\":{\"name\":\"Ada\",\"age\":37,\"active\":true}}",
  )
  let user = object("user")
  let name_lens = user.string("name")
  let age_lens = user.int("age")
  let active_lens = user.bool("active")

  inspect(name_lens.get(document), content="Ada")
  inspect(age_lens.get(document), content="37")
  inspect(active_lens.get(document), content="true")
}
```

`Lens::get` raises `LensError(Issue)` when traversal or decoding fails. Each `Issue` contains an RFC 6901 pointer, a structured `IssueCode`, and optional diagnostic context.

```mbt check
test {
  let document = @json.parse("{\"user\":{}}")
  try {
    object("user").string("name").get(document) |> ignore
    fail("expected LensError")
  } catch {
    LensError(issue) =>
      inspect(issue.pointer.to_string(), content="/user/name")
    _ => fail("unexpected error")
  }
}
```

A raw JSON lens can decode any type implementing the standard `FromJson` trait while preserving the selected path in nested decode errors.

```mbt check
struct Repository {
  owner : String
} derive(FromJson)

fn decode_repository(
  document : Json,
  path : @json.JsonPath,
) -> Repository raise @json.JsonDecodeError {
  root().json("repository").decode_from_json(document, path)
}
```

## Typed construction

`JsonBuilder` constructs an output object without requiring an existing `Json` document. `Lens::set` encodes its typed value, creates missing object parents, and writes it at the lens pointer. Repeated writes to the same pointer use the latest value.

```mbt check
test {
  let builder = JsonBuilder::JsonBuilder()
  let user = object("user")
  user.string("name").set(builder, "Ada")
  user.int("age").set(builder, 37)
  user.bool("active").set(builder, true)
  user.string("roles").array().set(builder, ["admin", "reviewer"])

  @json.json_inspect(builder, content={
    "user": {
      "name": "Ada",
      "age": 37,
      "active": true,
      "roles": ["admin", "reviewer"],
    },
  })
}
```

`nullable(None)` writes JSON `null`, while `optional(None)` omits the property and removes a previous value at the same pointer. `nullish(None)` omits the property by default; pass `encode_mode=NullishEncodeMode::Null` to write JSON `null` instead. Repeated presence combinators use the last call, so both `optional().nullable()` and `nullish().nullable()` have nullable semantics: `None` writes JSON `null`, and a missing property remains an error. Array items cannot be omitted without changing later indices, so `PresenceLens::array()` always treats its items as nullable for both encoding and decoding.

`Lens::set` raises `JsonBuildError(JsonBuildIssue)` when an encoded leaf blocks a nested object path. The issue contains the exact output pointer and a structured `JsonBuildIssueCode`. The builder is unchanged when construction fails.

## Arrays and presence

Compose an item lens with `array` to decode every array element. Item failures include their zero-based index in the reported JSON Pointer.

```mbt check
test {
  let document = @json.parse("{\"names\":[\"Ada\",\"Grace\"]}")
  debug_inspect(
    root().string("names").array().get(document),
    content="[\"Ada\", \"Grace\"]",
  )
}
```

`nullable`, `optional`, and `nullish` keep missing properties distinct from explicit JSON `null`:

| Input state | Required string | `nullable` | `optional` | `nullish` |
| ----------- | --------------: | ---------: | ---------: | --------: |
| Missing     |           error |      error |     `None` |    `None` |
| `null`      |      type error |     `None` | type error |    `None` |
| String      |           value |  `Some(T)` |  `Some(T)` | `Some(T)` |

Here, missing means that the selected leaf property is absent. A missing intermediate object remains an error so optional values cannot hide an invalid surrounding structure.

`PresenceLens::array()` is a normalization boundary: regardless of whether it was created from `optional`, `nullable`, or `nullish`, every item uses nullable semantics. JSON `null` decodes to `None`, and `None` encodes as JSON `null`, preserving array indices and matching JavaScript JSON array serialization. This differs from `primitive.array().optional()`, where `optional` applies to the whole array property rather than its items.

Presence combinators can be replaced without changing the value type. Each call returns `PresenceLens[T]`, and the final call determines both decoding and encoding behavior. For example, `nullable().optional()` accepts a missing property but rejects JSON `null`, while `optional().nullable()` rejects a missing property but accepts and writes JSON `null`.

## Validation

`LensTrait` exposes only the type-erased `check` operation required by aggregate validation. `Lens[T]`, `PresenceLens[T]`, and `ObjectLens` implement it, so heterogeneous lenses can be passed directly to `validate`. Every check runs, and failures are returned in input order.

```mbt check
test {
  let document = @json.parse(
    "{\"user\":{\"name\":\"Ada\",\"age\":37}}",
  )
  let user = object("user")
  let name_lens = user.string("name")
  let age_lens = user.int("age")

  match validate(document, [user, name_lens, age_lens]) {
    Valid => {
      let name : String = name_lens.get(document)
      let age : Int = age_lens.get(document)
      inspect((name, age), content="(Ada, 37)")
    }
    Invalid(issues) => fail("unexpected issues: \{issues}")
  }
}
```

`Validation::Valid` carries no decoded value. `Validation::Invalid` carries only `Array[Issue]`.

## Numeric behavior

`number` returns the existing `Double` stored in `Json::Number` without further validation, including non-finite values. `int` delegates directly to MoonBit's standard `Double::to_int` conversion without package-level validation, inheriting its truncation, saturation, and special-value behavior. The package never reparses the retained JSON number text.

## Current scope

The API supports object-property traversal and builder construction; `String`, `Bool`, `Double`, standard-converted `Int`, and raw `Json` values; typed arrays; and nullable, optional, and nullish values. `Lens::set` writes to `JsonBuilder`; it does not mutate or copy an existing JSON document. Refinements, alternatives, and source-document mutation remain outside the current scope.

See [the design document](docs/design.md) for the detailed contract and roadmap. A Japanese translation is available at [docs/design.ja.md](docs/design.ja.md).
