# MoonBit Markdown Tests

> Document type: concrete MoonBit test implementation guidance.

## File format

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
