# MoonBit Variants

> Document type: concrete MoonBit implementation guidance.

## Representation

- **Enum Wrapping Structs**: Define independent Structs for each variant, then wrap them in the Enum. Use the same name for the Variant and the Struct.

  ```mbt check
  pub struct Point { ... }

  pub enum Geometry {
    Point(Point)
    MultiPoint(MultiPoint)
  } derive(Debug, Eq)
  ```

- **Delegation**: When implementing traits for such Enums, pattern match on `self` and delegate to the inner struct's method.
- Prefer distinct Structs for complex data wrapped in Enums if polymorphic behavior is needed.

## Extraction

Use exhaustive pattern matching when the caller handles every variant. Provide a typed `try_into_<variant>` operation that raises a domain error when the caller needs to extract one variant or stop. Do not discard the failure reason behind `Option` or a string error.
