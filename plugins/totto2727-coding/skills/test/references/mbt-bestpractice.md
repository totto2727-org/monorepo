# MoonBit Testing Standards

## 1. General Rules

- Use `test "description" { ... }` blocks for all tests.
- Use `debug_inspect(value, content="expected_string")` for snapshot-style testing of complex data structures. `inspect` is deprecated; always use `debug_inspect` or `json_inspect` instead.
  - **Inspect usage**: When using `debug_inspect`, always pass the direct return value of the function under test. Do not obscure it by inspecting derived properties like `.length()` unless absolutely necessary.
    - Bad: `debug_inspect(array.length(), content="3")`
    - Good: `debug_inspect(array, content="[A, B, C]")`
  - For `ToJson` tests, use `json_inspect` as much as possible.
- Use `assert_eq(actual, expected)` for value equality.
- Do not ignore compilation warnings; fix them (e.g., unused variables).
- Group related tests in the same file or dedicated `_test.mbt` files.
- **Ambiguity Resolution**: If a method call in a test is ambiguous (e.g. `to_json` which exists in both a Trait and as a struct method), use the fully qualified Trait syntax: `TraitName::method_name(object, ...)`.

## 2. Test Naming

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

## 3. Test File Format (.mbt.md)

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
  debug_inspect(func1(...), content="...")
}
```

### [TraitName]

#### [method_name]

```mbt check
test "StructName TraitName::method_name - scenario" {
  debug_inspect(trait_method(...), content="...")
}
```
````
