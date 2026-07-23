# MoonBit Test Assertions

> Document type: concrete MoonBit test implementation guidance.

## General rules

- Use `test "description" { ... }` blocks for all tests.
- Do not ignore compilation warnings; fix them (e.g., unused variables).
- Group related tests in the same file or dedicated `_test.mbt` files.
- **Ambiguity Resolution**: If a method call in a test is ambiguous (e.g. `to_json` which exists in both a Trait and as a struct method), use the fully qualified Trait syntax: `TraitName::method_name(object, ...)`.
- **Constructor Calls in Doctests**: In `.mbt.md` doctest scope, the bare-name call `Foo(args)` for a constructor `Foo::Foo` is unresolved (`The value identifier Foo is unbound`). Use the fully qualified `Foo::Foo(args)` form. `Foo::method(...)` calls and instance method dispatch (`x.method()`) work with the bare names.

## Assertion selection

Pick assertion APIs deliberately. Mixing styles without a rule produces tests that hide intent.

### Decision table

| Use case                                                            | API                                            | Notes                                                                                         |
| :------------------------------------------------------------------ | :--------------------------------------------- | :-------------------------------------------------------------------------------------------- |
| Direct function return value                                        | `inspect`, `debug_inspect`, or `json_inspect`  | Select the inspection API supported by the returned type                                      |
| Primary constructor — verify struct layout at a glance              | `debug_inspect(value, content="...")`          | Snapshot the literal struct so the field order and types are visible without leaving the test |
| Large / complex object — happy-path verification                    | `debug_inspect(value, content="...")`          | Use when the type has many properties, changes often, or individual asserts would miss fields |
| `ToJson` derive — snapshot the serialized form                      | `json_inspect(value, content=...)`             | Preferred over manual string comparison                                                       |
| Equality of two secondary observations with `Eq + Debug`            | `@test.assert_eq(actual, expected)`            | Use after one invocation when comparing derived observations; failure prints both sides       |
| Inequality of two values where the type derives `Eq + Debug`        | `@test.assert_not_eq(actual, expected)`        | Same diagnostics as `assert_eq`                                                               |
| Bool predicate (`is_X`, `has_X`, `contains_X`, derived `==` / `!=`) | `assert_true(predicate)` / `assert_false(...)` | Reads as "the predicate holds"                                                                |
| Equality of a value whose type lacks `Show` and `Debug` derives     | `assert_true(actual == expected)`              | Last resort; prefer adding `Debug` to the type if you control it                              |
| Function intended to panic / abort                                  | `panic_` test prefix + `expr \|> ignore`       | The runner only passes if the panic actually fires                                            |
| Raising function expected to fail                                   | `panic_` prefix + `try! (expr \|> ignore)`     | `try!` converts the raised error to the panic required by the test runner                      |

### Direct results and raised errors

- Verify a function's direct input/output behavior with the appropriate `inspect`, `debug_inspect`, or `json_inspect` API. This rule takes precedence over the equality and predicate rows when the expression is the direct return value.
- Verify that a raising function fails with `try!` inside a test whose title starts with `panic_`. The `try!` converts the raised error into the panic required for the test to pass.
- Do not implement an occurrence-only error check with mutable sentinel state such as `let mut raised = false`, `try`/`catch`, and `inspect(raised, ...)`.
- Use `try`/`catch` only when the error identity, variant, payload, or message is itself part of the observable contract. Convert the error to an inspectable value and assert that value directly.
- In a documented family-conformance test that must continue after each expected error, handle every call with `try`/`catch`/`noraise`: return `Unit` from `catch` and panic from `noraise`. This verifies each family member without temporary mutable state; do not use it for a single expected error.

```moonbit
///|
test "Context get_value - invalid input" {
  // Bad: mutable state and catch-only bookkeeping obscure the expected failure.
  let mut raised = false
  try context.get_value(invalid_definition) |> ignore catch {
    _ => raised = true
  }
  inspect(raised, content="true")
}

///|
test "panic_Context get_value - invalid input panics" {
  // Good: try! converts the raised error into the panic required by the test.
  try! (context.get_value(invalid_definition) |> ignore)
}
```

### `debug_inspect`

- Always pass the **direct return value** of the function under test. Do not obscure it via derived properties.
  - Bad: `debug_inspect(array.length(), content="3")`
  - Good: `debug_inspect(array, content="[A, B, C]")`
- For the _primary constructor_ test, snapshot the constructed value so the struct shape is visible inline. This is the one place where snapshotting beats `@test.assert_eq` on readability.
- For large objects (many fields, frequently mutated, easy to forget asserts), prefer one snapshot over many separate `assert_eq`s — the snapshot guarantees no field is silently dropped from the test, and `moon test --update` keeps it in sync.

### `@test` package setup

`moonbitlang/core/test` must be added as a test-only import in each package whose tests use `@test.assert_eq` etc.:

```text
import {
  // production imports
}

import {
  "moonbitlang/core/test",
} for "test"
```

Without the test-only import, `@test.assert_eq` triggers `Warning [0071] core_package_not_imported`.
