# lens

Reusable typed access and aggregate validation for MoonBit JSON values.

The package keeps static types on `Lens[T]`, while `ObjectLens` reads selected objects as `Map[String, Json]`. The returned map is copied so top-level mutations do not change the source document; nested `Json` values retain their normal sharing semantics. Validation only reports whether every requested read succeeds; it does not infer or construct application types from runtime definitions. After successful validation, read values through the original lenses.

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

`LensTrait` exposes only the type-erased `check` operation required by aggregate validation. `Lens[T]` and `ObjectLens` implement it, so heterogeneous lenses can be passed directly to `validate`. Every check runs, and failures are returned in input order.

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

The API supports object-property traversal; `String`, `Bool`, `Double`, standard-converted `Int`, and raw `Json` values; typed arrays; and nullable, optional, and nullish values. Refinements, alternatives, and mutation such as `set` are reserved for later phases.

See [the design document](docs/design.md) for the detailed contract and roadmap. A Japanese translation is available at [docs/design.ja.md](docs/design.ja.md).
