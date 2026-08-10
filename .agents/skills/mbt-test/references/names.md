# MoonBit Test Names

> Document type: concrete MoonBit test implementation guidance.

## Rules

- Use the pattern `test "[Target] [Method] - [Scenario]"` when no test-design ID is assigned.
- For a function-scoped test-design flow, restart case numbering from `1` in each function section and use `test "[Target] [Method] N - [Scenario]"`.
- Separate the function or method name and case number with a space, never a hyphen.
- When a complex function is split into multiple flowcharts, hierarchical numbers are allowed as `test "[Target] [Method] N-N - [Scenario]"`. The first number must identify the corresponding split flowchart.
  - **Target**: The struct or function being tested.
  - **Method**: The specific method being tested (optional for simple functions).
  - **Scenario**: The condition or specific case being verified.
  - **Note**: If the test expects a panic, the name **must** start with `panic_` (e.g., `test "panic_[Target] [Method] - [Scenario]"`). For a numbered case, use `test "panic_[Target] [Method] N - [Scenario]"`. This prefix declares that panic is the expected behavior, and the test passes only when panic occurs.
  - **Trait Implementation**: If the method belongs to a trait, use `TraitName::method_name` (e.g., `test "StructName TraitName::method_name - Scenario"`).
  - **Natural English in Descriptions**: The scenario/description part should use natural English phrasing. Avoid CamelCase and ensure the text is readable.
    - Bad: `test "StructName Method - WithoutBbox"`
    - Good: `test "StructName Method - without BBox"`

  ```moonbit
  test "Point to_bbox - without BBox" { ... }
  test "orient2d 1 - clockwise" { ... }
  test "Polygon from_json 1-2 - invalid field value" { ... }
  test "panic_Polygon from_json 2-1 - invalid type" { ... }
  ```
