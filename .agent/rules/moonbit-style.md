---
trigger: model_decision
description: Moonbit(.mbt) Coding Standards
---

# Moonbit Coding Standards

## 1. Documentation

- Use `///|` for documentation comments on top-level definitions (functions, structs, enums, traits, tests).
- Ensure public APIs are documented.

## 2. Naming Conventions

- **Types (Structs, Enums) & Traits**: PascalCase (e.g., `Position`, `GeoJSONObject`, `ToBBox`).
- **Abbreviations**: Abbreviations other than those at the beginning (such as JSON or ID) should generally be all uppercase (e.g. `FromJSON`, `JSONToMap`).
- **Functions & Methods**: snake_case (e.g., `from_json`, `to_geometry`, `boolean_point_in_polygon`).
- **Variables & Parameters**: snake_case (e.g., `coordinates`, `shifted_poly`).
- **Constructors**: Use `new` as a static function on the type (e.g., `pub fn Polygon::new(...)`).

## 3. Idioms & Best Practices

### Instance Initialization & Updates

- **Initialization**: Struct literal syntax (`StructName::{...}`) should ONLY be used strictly within constructor functions like `new` or `newStructName`.
- **Updating**: Use dedicated update functions/methods to modify values.
- **Struct Update Syntax**: Avoid using Struct Update Syntax (e.g., `{ ..base, field: value }`) whenever possible, as it may bypass validation logic or constraints.

### Error Handling

- Use **Error Types** and the `raise` effect for functions that can fail (instead of returning `Result` types for synchronous logic).
  - When using **suberror**: usage is `raise fail(CustomError("Message"))`
  - When using **standard Error**: usage is `raise fail("Message")`
- Use `try { expression } catch { error => handler }` for handling errors.
- In tests, avoid excessive `try/catch` blocks wrapping code that fails. Allow the error to propagate or use `guard` to assert success if immediate failure is desired.

### Pattern Matching & Guards

- **Avoid `if` for Validation**: Instead of using an `if` statement to check for an error condition and verify failure (raise/fail), use a `guard` clause to assert the success condition. This improves readability by making the happy path explicit.

  ```moonbit
  // Bad
  if array.length() == 0 { raise Error("Empty") }
  // Good
  guard array.length() > 0 else { raise Error("Empty") }
  ```

- Use `guard` statement for assertions, early returns, or unwrapping specific enum variants/options.
  - **General Code**: Always provide a explicit fallback using `else`.

    ```moonbit
    guard hoge is Hoge(fuga) else { raise fail("Message") }
    ```

  - **Tests**: Use `guard` without fallback for better readability.

    ```moonbit
    guard feature.geometry is Some(@geojson.Geometry::Polygon(poly))
    ```

- Use `match` for exhaustive handling of Enums.
- Use **Labeled Arguments/Punners** (`~`) in patterns and constructors when variable names match field names:

  ```moonbit
  match geometry {
    Polygon(coordinates~) => coordinates
  }
  ```

### Structs & Enums

- **Enum Wrapping Structs**: When defining an Enum that aggregates multiple types (e.g., `Geometry`), define independent Structs for each variant first, then wrap them in the Enum. Use the same name for the Variant and the Struct.

  ```moonbit
  pub struct Point { ... }

  pub enum Geometry {
    Point(Point)
    MultiPoint(MultiPoint)
  } derive(Show, Eq, Compare, Hash)
  ```

- **Delegation**: When implementing traits for such Enums, pattern match on `self` and delegate to the inner struct's method.
- Prefer distinct Structs for complex data (`Position2D`, `Position3D`) wrapped in Enums (`Position`) if polymorphic behavior is needed.
- Implement standard traits: `Show`, `Eq`, `Compare`, `ToJson`, `FromJson`.
  - Also derive `Hash` whenever possible (note: types containing `Json` cannot derive `Hash`).

### Traits

- **Definition Notation**:

  ```moonbit
  pub trait ToGeoJSON {
    to_geojson(Self) -> GeoJSON
  }
  ```

## 4. Testing

- Use `test "description" { ... }` blocks.
- Use `inspect(value, content="expected_string")` for snapshot-style testing of complex data structures.
  - For `ToJson` tests, use `@json.inspect` as much as possible.
- Use `assert_eq(actual, expected)` for value equality.
- Do not ignore compilation warnings; fix them (e.g., unused variables).
- Group related tests in the same file or dedicated `_test.mbt` files.
