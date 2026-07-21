# MoonBit Test Names

> Document type: concrete MoonBit test implementation guidance.

## Rules

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
