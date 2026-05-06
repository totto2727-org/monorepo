# MoonBit Coding Standards

## Related Skills

- [docs-moonbit](../../docs-moonbit/SKILL.md) — MoonBit language reference (syntax, types, functions, methods, deriving). Use for language questions and debugging.

## 1. Documentation

- Use `///|` for documentation comments on top-level definitions (functions, structs, enums, traits, tests). This is the output format of `moon fmt`.
- Ensure public APIs are documented.

## 2. Naming Conventions

- **Types (Structs, Enums) & Traits**: PascalCase (e.g., `Position`, `GeoJSONObject`, `ToBBox`).
- **Abbreviations**: Abbreviations other than those at the beginning (such as JSON or ID) should generally be all uppercase (e.g. `FromJSON`, `JSONToMap`).
- **Functions & Methods**: snake_case (e.g., `from_json`, `to_geometry`, `boolean_point_in_polygon`).
- **Variables & Parameters**: snake_case (e.g., `coordinates`, `shifted_poly`).
- **No Abbreviations**: Do not abbreviate variable names unless they are common abbreviations (e.g., `id`, `json`). Avoid `p` for `point`, `ls` for `line_string`, etc.
- **Collections**: Use the `_array` suffix for array arguments/variables instead of plural names (e.g., `polygon_array` instead of `polygons`).
- **Constructors**: Always define the default constructor as a toplevel `fn TypeName::TypeName(...)` (the constructor's own name is the type name itself). The deprecated `fn new(..)` declaration inside the struct body must not be used. Factory functions use `new_hoge`/`from_hoge` naming — never `::new`.

## 3. Idioms & Best Practices

### 3.1 Constructors & Instance Initialization

- **Default constructor**: Define the default constructor as a toplevel `fn TypeName::TypeName(...)` — the constructor's name is the type name itself. This is the canonical entry point and must contain any validation logic; `raise` is supported and validation must live here so every instance is in a valid state. After this declaration, values are constructed via `TypeName(...)` (the short form) or `TypeName::TypeName(...)` (the qualified form).

  **OK**:

  ```mbt check
  struct MyStruct {
    x : Int
    y : Int
  }

  pub fn MyStruct::MyStruct(x~ : Int, y~ : Int) -> MyStruct {
    MyStruct::{ x, y }
  }
  ```

  **NG (deprecated `fn new` declaration inside struct body)**:

  ```mbt check
  struct MyStruct {
    x : Int
    y : Int

    fn new(x~ : Int, y~ : Int) -> MyStruct
  }
  ```

  **NG (`fn TypeName::new` implementation without the in-name approach)**:

  ```mbt check
  fn MyStruct::new(x~ : Int, y~ : Int) -> MyStruct {
    { x, y }
  }
  ```

- **Factory functions**: Define separate static functions with names like `new_hoge`, `from_hoge`, etc. Never name them `::new`. Factory functions must generate values via the canonical `TypeName(...)` constructor:

  ```mbt check
  struct Rect {
    x : Double
    y : Double
    width : Double
    height : Double
  }

  // Validation in the default constructor ensures every Rect instance has valid size
  pub fn Rect::Rect(x~ : Double, y~ : Double, width~ : Double, height~ : Double) -> Rect raise {
    Rect::{ x, y, width, height }
  }

  // Conversion: create from a different representation
  pub fn Rect::from_corners(x1~ : Double, y1~ : Double, x2~ : Double, y2~ : Double) -> Rect raise {
    Rect(x=x1, y=y1, width=x2 - x1, height=y2 - y1)
  }

  // Specific state: create a type with optional fields in a predetermined state
  pub fn Rect::new_unit(x~ : Double, y~ : Double) -> Rect raise {
    Rect(x~, y~, width=1.0, height=1.0)
  }
  ```

- **Initialization**: Struct literal syntax (`TypeName::{...}`) should ONLY be used strictly within the canonical `TypeName::TypeName(...)` constructor. All other code (including factory functions and tests) must use the constructor short form (`TypeName(...)`).
- **Updating**: Use dedicated update functions/methods to modify values.
- **Struct Update Syntax**: Avoid using Struct Update Syntax (e.g., `{ ..base, field: value }`) whenever possible, as it may bypass validation logic or constraints.
- **Ignore Usage**: Use proper pipeline style when ignoring return values: `expr |> ignore`.

### 3.2 Sequence-returning functions (Array vs Iter)

A library function that returns a sequence of transformed elements should choose its return shape according to the predicted output size:

- **Predictable, small element count** (e.g. `Line` always yields 2 endpoints, `Triangle` always yields 3 vertices): **return `Array[T]` only.** A lazy `Iter[T]` form does not earn its complexity at this size.
- **Variable, or predictable but large**, element count (e.g. `LineString::lines`, `LineString::points`, anything walking a polygon's coords): **provide both an `Array[T]` form and an `Iter[T]` form**, where the `Iter[T]` form is named with an `_iter` suffix.

  The two forms must be **independent implementations**. Do NOT implement one in terms of the other:
  - The eager form must build the `Array` directly (e.g. `Array::new(capacity=n)` + `push` in a loop).
  - The lazy form must construct an `Iter` directly (e.g. `Iter::new(fn() -> T?)` with a captured cursor).

  Going through `Iter -> Array` (`iter().collect()`) defeats the laziness; going through `Array -> Iter` (`array.iter()`) forces the allocation that the caller may have wanted to avoid. Either direction adds avoidable overhead at the call site, so each shape is implemented from scratch.

  Common per-element logic MAY be extracted into a private helper used by both forms.

  **Example** (LineString):

  ```mbt check
  // Eager: builds Array directly
  pub fn LineString::lines(self : LineString) -> Array[Line] {
    let n = self.coords.length()
    if n < 2 {
      return []
    }
    let result = Array::new(capacity=n - 1)
    for i = 0; i < n - 1; i = i + 1 {
      result.push(Line::Line(self.coords[i], self.coords[i + 1]))
    }
    result
  }

  // Lazy: independent Iter; no Array allocated
  pub fn LineString::lines_iter(self : LineString) -> Iter[Line] {
    let n = self.coords.length()
    let mut i = 0
    Iter::new(fn() -> Line? {
      if n >= 2 && i < n - 1 {
        let line = Line::Line(self.coords[i], self.coords[i + 1])
        i = i + 1
        Some(line)
      } else {
        None
      }
    })
  }
  ```

### 3.3 Error Handling

Use the `raise` effect for functions that can fail instead of returning `Result` types for synchronous logic.

**Defining error types:**

```mbt check
suberror DivError { DivError(String) }

suberror E3 {
  A
  B(String)
  C(Int, loc~ : SourceLoc)
}
```

`suberror` uses enum-like constructor syntax. The older `suberror A B` syntax is deprecated. Always use `suberror A { A(B) }` with explicit constructors.

**Raising errors:**

- Custom error: `raise DivError("division by zero")`
- Generic failure: `fail("message")` — convenience function that raises `Failure` type with source location

**Function signatures:**

```mbt check
fn div(x : Int, y : Int) -> Int raise DivError { ... }

fn f() -> Unit raise { ... }

fn add(a : Int, b : Int) -> Int noraise { a + b }
```

- `raise CustomError`: function may raise a specific error type
- `raise` or `raise Error`: function may raise any error
- `noraise`: function guaranteed not to raise

**Handling errors:**

```mbt check
try div(42, 0) catch {
  DivError(msg) => println(msg)
} noraise {
  v => println(v)
}

let a = div(42, 0) catch { _ => 0 }

let res = try? (div(6, 0) * div(6, 3))

try! div(42, 0)
```

- `try { expr } catch { pattern => handler } noraise { v => ... }`: full error handling
- `let a = expr catch { _ => default }`: simplified inline catch
- `try? expr`: convert to `Result[T, Error]`
- `try! expr`: panic on error

**Error polymorphism:**

Use `raise?` for higher-order functions that conditionally throw:

```mbt check
fn[T] map(
  array : Array[T],
  f : (T) -> T raise?
) -> Array[T] raise? { ... }
```

When `f` is `noraise`, `map` is also `noraise`. When `f` raises, `map` raises.

**Best practices:**

- Prefer `raise` effect over `Result` for synchronous code
- In tests, let errors propagate or use `guard` to assert success

### 3.4 Pattern Matching & Guards

- **Avoid `if` for Validation**: Use `guard` instead:

  ```mbt check
  guard array.length() > 0 else { raise Error("Empty") }
  ```

- Use `guard` for assertions, early returns, or unwrapping:
  - **General Code**: Always provide an explicit fallback using `else`:

    ```mbt check
    guard hoge is Hoge(fuga) else { raise fail("Message") }
    ```

  - **Tests**: Use `guard` without fallback for better readability:

    ```mbt check
    guard feature.geometry is Some(@geojson.Geometry::Polygon(poly))
    ```

- Use `match` for exhaustive handling of Enums.
- Use **Labeled Arguments/Punners** (`~`) in patterns and constructors when variable names match field names:

  ```mbt check
  match geometry {
    Polygon(coordinates~) => coordinates
  }
  ```

### 3.5 Functions

- **Anonymous Functions**: Prefer arrow syntax `args => body` over `fn` keyword `fn(args) { body }`.
- **Local `fn` annotation**: Local `fn` definitions must explicitly annotate `raise`/`async` effects. Inference for local `fn` is deprecated. Arrow functions are unaffected.

  ```mbt check
  fn outer() -> Unit raise {
    fn local_fn() -> Unit raise { fail("err") }
    let arrow_fn = () => { fail("err") }
  }
  ```

### 3.6 Structs & Enums

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
- **Standard traits**: `Debug`, `Eq`, `Compare`, `ToJson`, `FromJson`, `Hash` (note: types containing `Json` cannot derive `Hash`).
- **`Debug` trait**: Always derive `Debug` instead of `Show`. `Debug` replaces `Show` as the standard trait for structural formatting. Uses `debug_inspect()` for output.

  ```mbt check
  struct MyStruct { ... } derive(Debug, Eq)
  ```

- **Constructor qualified names**: Built-in constructors require qualified names (e.g., `Failure::Failure`). Constructors with arguments cannot be used as higher-order functions; use a wrapper:

  ```mbt check
  let f = x => Some(x)
  ```

### 3.7 Traits

- **Definition Notation**:

  ```mbt check
  pub trait ToGeoJSON {
    to_geojson(Self) -> GeoJSON
  }
  ```

- **Performance Overrides**: Always override default trait methods if a more efficient implementation is possible for the specific type.

- **Implementation Rules**:
  1. **Default Implementation**: If a method's return value is not `Self` and it can be implemented solely using other methods, provide a default implementation.
  2. **Trait Object Delegation**: When implementing a super-trait for a type that also implements a sub-trait, define the logic as a static function on the sub-trait's object and relay to it.
  3. **Direct Implementation**: If delegation is not possible or creates circular dependencies, implement the method directly on the type.

### 3.8 Cascade Operator

`x..f()` is equivalent to `{ x.f(); x }` — for methods returning `Unit`.

```mbt check
let result = StringBuilder::new()
  ..write_char('a')
  ..write_object(1001)
  ..write_string("abcdef")
  .to_string()
```

Enables chaining mutable operations without modifying return types. Compiler warns if result is ignored.

### 3.9 Range Syntax

- `a..<b`: exclusive upper bound (increasing)
- `a..<=b`: inclusive upper bound (increasing) — replaces deprecated `a..=b`
- `a>..b`: exclusive lower bound (decreasing)
- `a>=..b`: inclusive lower bound (decreasing)

```mbt check
for i in 0..<10 { ... }
for i in 10>=..0 { ... }
```

### 3.10 Loop `nobreak`

Replaces old loop `else`. Executes when the loop condition becomes false.

```mbt check
let r = while i > 0 {
  if cond { break 42 }
  i = i - 1
} nobreak {
  7
}
```

`break` must provide a value matching the `nobreak` return type.

### 3.11 `declare` Keyword

Similar to Rust's `todo!` macro. Use `declare` before function definitions to indicate specification-only declarations. Missing implementations generate warnings (not errors).

```mbt check
declare fn add(x : Int, y : Int) -> Int
```

## 4. Performance Optimization

- **Lazy evaluation with Iterator**: For array processing where the size is unknown or potentially large, prefer `iter()` for lazy evaluation to avoid intermediate array allocations. This is especially effective for fold operations like `minimum()`/`maximum()`:

  ```mbt check
  let min_x = coords.iter().map(c => c.x()).minimum().unwrap()
  ```

- **Flattening**: Use `flatten()` instead of manual loops with `append` when merging nested collections.

## 5. Toolchain

- `moon.pkg` DSL replaces deprecated `moon.pkg.json`.

## 6. Testing

See [MoonBit Testing Standards](../../test/references/mbt-bestpractice.md) for detailed testing guidelines.
