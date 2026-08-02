# lens

Reusable typed access, construction, and aggregate validation for MoonBit JSON values.

The package keeps static types on `Lens[T]`, while `ObjectLens` reads selected objects as `Map[String, Json]`. The returned map is copied so top-level mutations do not change the source document; nested `Json` values retain their normal sharing semantics. A `JsonBuilder` accepts typed values through the same lenses and implements `ToJson`. Validation only reports whether every requested read succeeds; it does not infer or construct application types from runtime definitions. After successful validation, read values through the original lenses.

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

`nullable(None)` writes JSON `null`, while `optional(None)` omits the property and removes a previous value at the same pointer. `nullish(None)` omits the property by default; pass `encode_mode=NullishEncodeMode::Null` to write JSON `null` instead. Omission inside an array is rejected; use `Null` mode or a nullable item lens when JSON `null` is intended.

`Lens::set` raises `JsonBuildError(JsonBuildIssue)` for an encoded leaf that blocks a nested object path or an omission requested inside an array. The issue contains the exact output pointer and a structured `JsonBuildIssueCode`. The builder is unchanged when value encoding fails.

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

## Validation

`LensTrait` exposes the type-erased operations required by aggregate validation and JSON Schema generation. `Lens[T]` and `ObjectLens` implement it, so heterogeneous lenses can be passed directly to `validate` and `json_schema`. Every validation check runs, and failures are returned in input order.

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

## JSON Schema

Every `Lens[T]` and `ObjectLens` implements `LensTrait::to_json_schema`. The result is a Draft 2020-12 schema fragment that includes the lens's complete path. Pass the same heterogeneous lens array accepted by `validate` to `json_schema` to produce one object schema. Compatible paths are merged recursively, required names retain their first-seen order, and incompatible declarations at the same path produce a `false` property schema.

```mbt check
test {
  let user = object("user")
  let schema = json_schema([
    user.string("name"),
    user.int("age"),
    user.string("tags").array().optional(),
  ])

  inspect(schema is Json::Object(_), content="true")
}
```

The generated schema includes only the constraints represented by the current lens API: object paths, primitive JSON kinds, array items, missing-property requirements, and nullable values. A raw `json` lens contributes an unconstrained `{}` value schema. An `int` lens contributes `{ "type": "number" }` because the current decoder accepts every JSON number and applies `Double::to_int`; emitting `integer` would be stricter than runtime validation. Unknown object properties remain allowed.

## Numeric behavior

`number` returns the existing `Double` stored in `Json::Number` without further validation, including non-finite values. `int` delegates directly to MoonBit's standard `Double::to_int` conversion without package-level validation, inheriting its truncation, saturation, and special-value behavior. The package never reparses the retained JSON number text.

## Current scope

The API supports object-property traversal and builder construction; `String`, `Bool`, `Double`, standard-converted `Int`, and raw `Json` values; typed arrays; nullable, optional, and nullish values; aggregate validation; and minimal JSON Schema generation. `Lens::set` writes to `JsonBuilder`; it does not mutate or copy an existing JSON document. Refinements, alternatives, descriptions, and source-document mutation remain outside the current scope.

See [the design document](docs/design.md) for the detailed contract and roadmap. A Japanese translation is available at [docs/design.ja.md](docs/design.ja.md).
