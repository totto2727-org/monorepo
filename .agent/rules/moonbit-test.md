---
trigger: model_decision
description: Moonbit Testing Standards
---

# Moonbit Testing Standards

## 1. General Rules

- **Tests vs Code**: Split testing rules from general coding style to keep documents manageable.
- Use `test "description" { ... }` blocks for standard `.mbt` files (legacy/constrained).
- Use `inspect(value, content="expected_string")` for snapshot-style testing of complex data structures.
  - **Inspect usage**: When using `inspect`, always pass the direct return value of the function under test. Do not obscure it by inspecting derived properties like `.length()` unless absolutely necessary.
    - Bad: `inspect(array.length(), content="3")`
    - Good: `inspect(array, content="[A, B, C]")`
  - For `ToJson` tests, use `@json.inspect` as much as possible.
- Use `assert_eq(actual, expected)` for value equality.
- Do not ignore compilation warnings; fix them (e.g., unused variables).
- Group related tests in the same file or dedicated `_test.mbt` files.

## 2. Test Naming

- Use the pattern `test "[Target] [Method] - [Scenario]"` to ensure clarity.
  - **Target**: The struct or function being tested.
  - **Method**: The specific method being tested (optional for simple functions).
  - **Scenario**: The condition or specific case being verified.
  - **Note**: If the test expects a panic, the name **must** start with `panic_` (e.g., `test "panic_[Target] [Method] - [Scenario]"`).

  ```moonbit
  test "Point to_bbox - without bbox" { ... }
  test "orient2d - clockwise" { ... }
  test "panic_Polygon from_json - invalid type" { ... }
  ```

## 3. Test File Format (.mbt.md)

All tests when rewritten should be drafted in `.mbt.md` files (e.g., `multi_geometry.mbt.md`), except for `wbtest.mbt` which must remain as is due to constraints.

**Note on Filename**: The test file should be named `[Implementation File Name].md`. Do NOT include `_test` in the filename (e.g., `xy.mbt.md`, not `xy_test.mbt.md`).

### Code Blocks in Markdown

- `mbt`: Highlighting only (not compiled).
- `mbt check`: Highlighting and checked (compiled).
- `mbt test`: Highlighting, checked, and wrapped in a test block (manual `test { ... }` not needed).
- `mbt test(async)`: Wrapper for async tests.

### File Structure Definition

For `.mbt.md` files, follow the structure below.

**Organization Rules:**

- Organize tests by function using **H3 headers**.
- For **Trait implementations**:
  - Use **H3** for the Trait name (if grouping by trait) or the Function Name directly.
  - Use nested **H4 headers** for methods if needed.
- Each section should contain:
  1. **Test Case Matrix**: A table summarizing conditions and cases. **(Optional if there is only 1 test case)**
      - **Variable**: Must use the **Argument Name** of the function (e.g., `arg1`, `arg2`). For instance methods, use `self`.
      - **NO Method Row**: Do not include a row identifying the method itself used as a condition. The H3 header already serves this purpose.
  2. **Implementation**: A list of test implementations, with descriptions as bullet points and code blocks.

#### Template

```markdown
# [Implementation File Name] (e.g., xy.mbt)

[Feature Summary / Documentation]
(Describe the core functionality provided by this implementation. **Do NOT mention that this file contains tests.**)

## Public API

- `func1`
- `func2`

## Test

### [Function Name]

| Variable | State | Note | 1 | 2 | 3 |
| :--- | :--- | :--- | :---: | :---: | :---: |
| `arg1` | `Empty` | | ✓ | | - |
| `arg1` | `Valid` | | | ✓ | - |
| `arg2` | `True` | | - | - | ✓ |
| `arg2` | `False`| | - | - | |

- Test Title 1

  ```mbt test
  inspect(func1(...), content="...")
  ```

### [TraitName]

#### [method_name]

- Test Title

  ```mbt test
  inspect(trait_method(...), content="...")
  ```

```
