# MoonBit Testing Standards

## 1. General Rules

- Use `test "description" { ... }` blocks for all tests.
- Do not ignore compilation warnings; fix them (e.g., unused variables).
- Group related tests in the same file or dedicated `_test.mbt` files.
- **Ambiguity Resolution**: If a method call in a test is ambiguous (e.g. `to_json` which exists in both a Trait and as a struct method), use the fully qualified Trait syntax: `TraitName::method_name(object, ...)`.
- **Constructor Calls in Doctests**: In `.mbt.md` doctest scope, the bare-name call `Foo(args)` for a constructor `Foo::Foo` is unresolved (`The value identifier Foo is unbound`). Use the fully qualified `Foo::Foo(args)` form. `Foo::method(...)` calls and instance method dispatch (`x.method()`) work with the bare names.

## 2. Assertion Function Selection

Pick assertion APIs deliberately. Mixing styles without a rule produces tests that hide intent.

### 2.1 Decision table

| Use case                                                            | API                                            | Notes                                                                                         |
| :------------------------------------------------------------------ | :--------------------------------------------- | :-------------------------------------------------------------------------------------------- |
| Primary constructor — verify struct layout at a glance              | `debug_inspect(value, content="...")`          | Snapshot the literal struct so the field order and types are visible without leaving the test |
| Large / complex object — happy-path verification                    | `debug_inspect(value, content="...")`          | Use when the type has many properties, changes often, or individual asserts would miss fields |
| `ToJson` derive — snapshot the serialized form                      | `json_inspect(value, content=...)`             | Preferred over manual string comparison                                                       |
| Equality of two values where the type derives `Eq + Debug`          | `@test.assert_eq(actual, expected)`            | Failure message prints both sides                                                             |
| Inequality of two values where the type derives `Eq + Debug`        | `@test.assert_not_eq(actual, expected)`        | Same diagnostics as `assert_eq`                                                               |
| Bool predicate (`is_X`, `has_X`, `contains_X`, derived `==` / `!=`) | `assert_true(predicate)` / `assert_false(...)` | Reads as "the predicate holds"                                                                |
| Equality of a value whose type lacks `Show` and `Debug` derives     | `assert_true(actual == expected)`              | Last resort; prefer adding `Debug` to the type if you control it                              |
| Function intended to panic / abort                                  | `panic_` test prefix + `expr \|> ignore`       | The runner only passes if the panic actually fires                                            |

### 2.2 Deprecation: prelude `assert_eq` / `assert_not_eq`

The prelude versions (`Eq + Show` constraint) are **deprecated** in `moonbitlang/core`:

```text
#deprecated("use `using @test {assert_eq}` instead", skip_current_package=true)
pub fn[T : Eq + Show] assert_eq(...)
```

Use `@test.assert_eq` / `@test.assert_not_eq` (`Eq + Debug` constraint) instead. The `Debug` requirement is satisfied by `derive(Debug)`, which is far more common than `derive(Show)` on data types.

### 2.3 `debug_inspect` usage discipline

- Always pass the **direct return value** of the function under test. Do not obscure it via derived properties.
  - Bad: `debug_inspect(array.length(), content="3")`
  - Good: `debug_inspect(array, content="[A, B, C]")`
- For the _primary constructor_ test, snapshot the constructed value so the struct shape is visible inline. This is the one place where snapshotting beats `@test.assert_eq` on readability.
- For large objects (many fields, frequently mutated, easy to forget asserts), prefer one snapshot over many separate `assert_eq`s — the snapshot guarantees no field is silently dropped from the test, and `moon test --update` keeps it in sync.

### 2.4 Required `moon.pkg` setup for `@test`

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

## 3. Test Naming

- Use the pattern `test "[Target] [Method] - [Scenario]"` to ensure clarity.
  - **Target**: The struct or function being tested.
  - **Method**: The specific method being tested (optional for simple functions).
  - **Scenario**: The condition or specific case being verified.
  - **Note**: If the test expects a panic, the name **must** start with `panic_` (e.g., `test "panic_[Target] [Method] - [Scenario]"`).
  - **Trait Implementation**: If the method belongs to a trait, use `TraitName::method_name` (e.g., `test "StructName TraitName::method_name - Scenario"`).
  - **Natural English in Descriptions**: The scenario/description part should use natural English phrasing. Avoid CamelCase and ensure the text is readable.
    - Bad: `test "StructName Method - WithoutBbox"`
    - Good: `test "StructName Method - without BBox"`

  ```moonbit
  test "Point to_bbox - without BBox" { ... }
  test "orient2d - clockwise" { ... }
  test "panic_Polygon from_json - invalid type" { ... }
  ```

## 4. Test File Format (.mbt.md)

All tests when rewritten should be drafted in `.mbt.md` files (e.g., `multi_geometry.mbt.md`), except for `wbtest.mbt` which must remain as is due to constraints.

**Note on Filename**: The test file should be named `[Implementation File Name].md`. Do NOT include `_test` in the filename (e.g., `xy.mbt.md`, not `xy_test.mbt.md`).

### Code Blocks in Markdown

- `mbt`: Highlighting only (not compiled).
- `mbt check`: Highlighting and compiled. Use with explicit `test "title" { ... }` blocks.
- `mbt test(async)`: Wrapper for async tests.

**Important**: Code blocks **must not be indented**. Even when included in a list item, the code block fence (\`\`\`) and its content must start at the beginning of the line.

### File Structure Definition

For `.mbt.md` files, follow the structure below.

**Organization Rules:**

- Organize tests by function using **H3 headers**.
- For **Trait implementations**:
  - Use **H3** for the Trait name (if grouping by trait) or the Function Name directly.
  - Use nested **H4 headers** for methods if needed.
- **Top-Level "Public API" Section**:
  - Nest trait implementations under the type they belong to using a bulleted list.
  - Only list traits that are explicitly implemented in the file (ignore defaults).
- Each section should contain:
  1. **Test Case Matrix**: A table summarizing conditions and cases. **(Optional if there is only 1 test case)**
     - **Variable**: Must use the **Argument Name** of the function (e.g., `arg1`, `arg2`). For instance methods, use `self`.
     - **NO Method Row**: Do not include a row identifying the method itself used as a condition. The H3 header already serves this purpose.
  2. **Implementation**: Code blocks with test implementations.
- **Order matching**: The order of tests in the `## Test` section must strictly follow the order of the corresponding items in the `## Public API` section.

#### Template

````markdown
# [Implementation File Name] (e.g., xy.mbt)

[Feature Summary / Documentation]
(Describe the core functionality provided by this implementation. **Do NOT mention that this file contains tests.**)

## Public API

- `func1`
- `func2`
- `TraitName`
  - `method_name`

## Test

### [Function Name]

| Variable | State   | Note |  1  |  2  |  3  |
| :------- | :------ | :--- | :-: | :-: | :-: |
| `arg1`   | `Empty` |      |  ✓  |     |  -  |
| `arg1`   | `Valid` |      |     |  ✓  |  -  |
| `arg2`   | `True`  |      |  -  |  -  |  ✓  |
| `arg2`   | `False` |      |  -  |  -  |     |

```mbt check
test "Function Name - scenario 1" {
  // Primary constructor → debug_inspect to surface the struct shape
  let value = StructName::StructName(1.0, 2.0)
  debug_inspect(
    value,
    content=(
      #|{ x: 1, y: 2 }
    ),
  )
}

test "Function Name - scenario 2" {
  // Equality of Eq + Debug values → @test.assert_eq
  @test.assert_eq(func1(arg), expected)
}

test "Function Name - scenario 3" {
  // Bool predicate → assert_true / assert_false
  assert_true(value.is_zero())
}

test "panic_Function Name - invalid input" {
  // Panic path → panic_ prefix + |> ignore
  func1(invalid) |> ignore
}
```

### [TraitName]

#### [method_name]

```mbt check
test "StructName TraitName::method_name - scenario" {
  @test.assert_eq(trait_method(...), expected)
}
```
````
