# lens

Reusable typed access and aggregate validation for MoonBit JSON values.

The package keeps static types on `Lens[T]`. Validation only reports whether every requested read succeeds; it does not infer or construct application types from runtime definitions. After successful validation, read values through the original typed lenses.

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

## Validation

Convert heterogeneous typed lenses to `Check` values when only success or failure is needed. Every check runs, and failures are returned in input order.

```mbt check
test {
  let document = @json.parse(
    "{\"user\":{\"name\":\"Ada\",\"age\":37}}",
  )
  let user = object("user")
  let name_lens = user.string("name")
  let age_lens = user.int("age")

  match validate(document, [name_lens.check(), age_lens.check()]) {
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

`number` reads the existing `Double` stored in `Json::Number` and rejects non-finite values. `int` uses MoonBit's standard `Double::to_int` and `Int::to_double` conversions together with the standard `Int` bounds; it rejects fractional and out-of-range values. The package never reparses the retained JSON number text.

## Current scope

The initial API supports object-property traversal and `String`, `Bool`, finite `Double`, exact `Int`, and raw `Json` values. Array traversal, refinements, alternatives, optional and nullable combinators, and mutation such as `set` are reserved for later phases.

See [the design document](docs/design.md) for the detailed contract and roadmap. A Japanese translation is available at [docs/design.ja.md](docs/design.ja.md).
