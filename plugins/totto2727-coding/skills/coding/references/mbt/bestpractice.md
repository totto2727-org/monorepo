# MoonBit Coding Standards

## Related Skills

- [docs-moonbit](../../../docs-moonbit/SKILL.md) — MoonBit language reference (syntax, types, functions, methods, deriving). Use for language questions and debugging.

## Detail Files

- [cli-application.md](./cli-application.md) — CLI application implementation rules for `admiral` option definitions, typed options, request body `ToJson`, and JSON response handling.

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
- **Immutable operations use the past-participle form**. The bare verb (`sort`, `reverse`, `push`, `append`) denotes the **mutating** form; the past participle (`sorted`, `reversed`, `pushed`, `appended`) denotes the **non-mutating** form that returns a new value and leaves the receiver untouched. This rule applies to every method that has a mutable / immutable pair, including array helpers, collection wrappers, and in-place vs. value-object updates. Examples:
  - `array.sort()` (mutates) ↔ `array.sorted()` (returns sorted copy)
  - `array.push(x)` (mutates) ↔ `array.pushed(x)` (returns extended copy)
  - `polygon.push_interior(ring)` (mutating) ↔ `polygon.pushed_interior(ring)` (returns new `Polygon`)

  Do NOT name an immutable operation with the bare verb. Do NOT name a mutating operation with the past participle.

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
- **Updating**: Use dedicated update functions/methods to modify values. Pick the naming based on whether the type is **immutable (value object)** or **mutable**:
  - **Immutable update — wither pattern (`with_hoge`)**: For value types (`derive(Eq, Hash)`, no externally observable identity), define `with_<field>` methods that return a **new instance** with the named field **wholly replaced** by the argument. The receiver is never mutated. This composes well with `let`-binding and pipe-style code, and keeps `Eq`/`Hash` invariants intact.

    ```mbt check
    pub fn Point::with_x(self : Point, x : Double) -> Point {
      Point::new(x, self.y())
    }

    pub fn Point::with_y(self : Point, y : Double) -> Point {
      Point::new(self.x(), y)
    }

    // Usage: chains naturally; original `p` is unchanged.
    let q = p.with_x(5.0).with_y(3.0)
    ```

    Use the wither pattern as the default whenever possible. It is the only safe shape for types that derive `Hash` (or are otherwise stored in keyed collections) — a setter would silently corrupt the hash.

    **`with_*` is reserved strictly for pure field replacement.** If the operation transforms an existing field rather than overwriting it (e.g. "append one element to an array field", "remove an entry by predicate", "increment a counter"), do NOT name it `with_*`. Use the past-participle naming rule above instead — the operation is still immutable, but it is _not_ a wither.

    | Operation                                                  | Naming                             | Why                                                                                                                 |
    | ---------------------------------------------------------- | ---------------------------------- | ------------------------------------------------------------------------------------------------------------------- |
    | Replace the entire `x` field                               | `point.with_x(5.0)`                | Pure replacement — wither                                                                                           |
    | Replace the entire `interiors` array                       | `polygon.with_interiors([r1, r2])` | Pure replacement — wither                                                                                           |
    | Append one ring to `interiors` (returning a new `Polygon`) | `polygon.pushed_interior(r)`       | Not pure replacement — past-participle verb at the front, noun at the back                                          |
    | Remove an interior matching a predicate                    | `polygon.filtered_interiors(pred)` | Not pure replacement                                                                                                |
    | Mutating counterpart on a genuinely mutable type           | `builder.push_interior(r)`         | Bare verb at the front. Only acceptable on a mutable type; on an immutable type, use the past-participle form above |

  - **Mutable update — setter pattern (`set_hoge`)**: For genuinely mutable types (builders, in-place collection wrappers, types with externally observable identity), define `set_<field>` methods that mutate `self` in place and return `Unit`. The setter pattern is reserved for cases where allocation cost or in-place semantics are part of the intended contract.

    ```mbt check
    pub fn Builder::set_capacity(self : Builder, capacity : Int) -> Unit {
      self.capacity = capacity
    }

    // Usage: receiver is mutated; chain via the cascade operator (..) when needed.
    let b = Builder::Builder()..set_capacity(64)..set_label("foo")
    ```

    Setters MUST NOT be defined on a type that derives `Hash` or is otherwise compared structurally for keying purposes — mutating a keyed value is undefined behaviour at the data-structure level.

  - **Mixing the two on the same type is forbidden.** A type is either an immutable value object (only withers) or a mutable type (only setters). If both kinds of updates are conceptually needed, split the type into two — typically a `Builder` (mutable, setters) that produces a finalised value object (immutable, withers).

- **Struct Update Syntax**: Avoid using Struct Update Syntax (e.g., `{ ..base, field: value }`) whenever possible, as it may bypass validation logic or constraints. Withers should always go through the canonical constructor.
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
  // Eager: builds Array immutably via Array::makei (size known up-front).
  // Avoid `for + push`. See §3.13 for the immutable-array rule.
  pub fn LineString::lines(self : LineString) -> Array[Line] {
    let n = self.coords.length()
    if n < 2 {
      return []
    }
    Array::makei(n - 1, i => Line::Line(self.coords[i], self.coords[i + 1]))
  }

  // Lazy: independent Iter; no Array allocated.
  // Iter naturally requires a captured cursor (`mut i`), which is acceptable
  // because the mutation is encapsulated inside the closure and never escapes.
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

  Note: the eager form intentionally uses `Array::makei`, never `Array::new(capacity=…)` followed by a `for` + `push` loop. When the output length is known ahead of time, `makei` is both shorter and the immutable canonical form (see §3.13). The lazy form is the only place where local mutation (the `mut i` cursor) is appropriate, because that mutation is encapsulated inside the iterator closure and cannot be observed from outside.

### 3.3 Structural APIs and Boundaries

Use structural APIs for structured data. Do not assemble paths, JSON, shell fragments, or domain payloads with string concatenation when a typed API exists.

For paths, use `@path.Path::join` instead of joining strings by hand. For paths with more than two segments, write the construction as a pipeline so each segment is visible and ordered:

```mbt check
let skill_dir = root
  |> @path.Path::join(".agents")
  |> @path.Path::join("skills")
  |> @path.Path::join(skill_name)
```

For JSON, work with `Json` values and `ToJson`. Never build JSON by concatenating strings. Prefer direct `Json::object({ ... })` construction, pattern matching for variants, and explicit `ToJson` implementations for boundary types.

Use `Map[String, Json]` only when the wire format distinguishes omitted fields from explicit `Json::null()` values, or when a dynamic key set cannot be expressed directly with `Json::object({ ... })`. When omission is required by an external API, keep the map inside the one `to_json` implementation that needs it.

Avoid meaningless thin wrappers. A helper that only renames one standard call, hides no domain rule, and has one call site should not exist. Keep a wrapper only when it captures a real invariant, owns domain discovery, or gives callers a typed boundary they could not otherwise express.

Push domain discovery and resolution into libraries. CLIs, scripts, and application entry points should ask a library for resolved concepts rather than reimplementing filesystem walks, lock-file lookup, package discovery, or naming rules inline.

### 3.4 Error Handling

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
- Generic failure: `fail("message")`. Prefer `fail(...)` for generic failures because it uses the standard failure output and reports the call-site source location. Use it directly, never as `raise fail(...)`.

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

- Prefer `raise` effect over `Result` for synchronous code.
- Use `fail("message")` for generic failures. It uses the standard failure output and reports the call-site source location.
- Catch only failures the current scope can recover from. If the caller can make a better decision, let the error propagate.
- In tests, let errors propagate or use `guard` to assert success.

### 3.5 Pattern Matching & Guards

- **Avoid `if` for Validation**: Use `guard` instead:

  ```mbt check
  guard array.length() > 0 else { raise Error("Empty") }
  ```

- Use `guard` for assertions, early returns, or unwrapping:
  - **General Code**: Always provide an explicit fallback using `else`:

    ```mbt check
    guard hoge is Hoge(fuga) else { fail("Message") }
    ```

  - **Tests**: Use `guard` without fallback for better readability:

    ```mbt check
    guard feature.geometry is Some(@geojson.Geometry::Polygon(poly))
    ```

- Use `match` for exhaustive handling of Enums.
- Model finite states as enums with `derive(Eq)` when equality is meaningful, then compare states directly. Do not replace a finite state with strings, booleans, or wrapper structs unless the domain has extra data to carry.
- Use **Labeled Arguments/Punners** (`~`) in patterns and constructors when variable names match field names:

  ```mbt check
  match geometry {
    Polygon(coordinates~) => coordinates
  }
  ```

### 3.6 Functions

- **Anonymous Functions**: Prefer arrow syntax `args => body` over `fn` keyword `fn(args) { body }`.
- **Local `fn` annotation**: Local `fn` definitions must explicitly annotate `raise`/`async` effects. Inference for local `fn` is deprecated. Arrow functions are unaffected.

  ```mbt check
  fn outer() -> Unit raise {
    fn local_fn() -> Unit raise { fail("err") }
    let arrow_fn = () => { fail("err") }
  }
  ```

### 3.7 Structs & Enums

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

- **Constructor qualified names**: Built-in constructors require qualified names. Constructors with arguments cannot be used as higher-order functions; use a wrapper:

  ```mbt check
  let f = x => Some(x)
  ```

### 3.8 Traits

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

### 3.9 Cascade Operator

`x..f()` is equivalent to `{ x.f(); x }` — for methods returning `Unit`.

```mbt check
let result = StringBuilder::new()
  ..write_char('a')
  ..write_object(1001)
  ..write_string("abcdef")
  .to_string()
```

Enables chaining mutable operations without modifying return types. Compiler warns if result is ignored.

### 3.10 Range Syntax

- `a..<b`: exclusive upper bound (increasing)
- `a..<=b`: inclusive upper bound (increasing) — replaces deprecated `a..=b`
- `a>..b`: exclusive lower bound (decreasing)
- `a>=..b`: inclusive lower bound (decreasing)

```mbt check
for i in 0..<10 { ... }
for i in 10>=..0 { ... }
```

### 3.11 Loop `nobreak`

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

### 3.12 `declare` Keyword

Similar to Rust's `todo!` macro. Use `declare` before function definitions to indicate specification-only declarations. Missing implementations generate warnings (not errors).

```mbt check
declare fn add(x : Int, y : Int) -> Int
```

### 3.13 Array & Collection Operations

`Array[T]` in MoonBit is a growable, mutable buffer (Rust `Vec` equivalent). Its API exposes both mutating helpers (`push`, `append`, `sort`, `reverse`, `clear`, ...) and non-mutating helpers (`map`, `filter`, `iter()`, `Array::makei`, spread literals `[..a, x]`, etc.). **Default to the immutable form everywhere.** Mutation is a last-resort optimisation, not a default mode.

#### Build new arrays without mutation

Pick the right immutable constructor for the situation. There is essentially always one — `for` + `push` is almost never the right answer.

- **Spread / concatenation literals** for combining existing arrays:

  ```mbt check
  let extended = [..a, 1]            // append-one
  let prepended = [0, ..a]           // prepend-one
  let merged = [..a, ..b]            // concat
  let with_sentinel = [..a, a[0]]    // close-ring style
  ```

- **`Array::makei(n, i => …)`** for building an array of known length from per-index logic. This replaces every `Array::new(capacity=n)` + `for i { push(...) }` loop:

  ```mbt check
  // Replacement for the classic windows(2) loop.
  let lines = Array::makei(coords.length() - 1, i =>
    Line::Line(coords[i], coords[i + 1])
  )
  ```

- **Iterator chains** (`iter().map().filter()...`) when length is unknown or the per-element logic chains:

  ```mbt check
  let positives = coords.iter().filter(c => c.x() > 0.0).collect()
  ```

  These are immutable by construction: `.collect()` allocates exactly once at the end and never touches the source.

- **Pair-wise / index-shifted iteration via `iter().zip(iter().drop(k))`** when the size-1 helpers above don't fit:

  ```mbt check
  let edges = coords.iter()
    .zip(coords.iter().drop(1))
    .map(p => Line::Line(p.0, p.1))
    .collect()
  ```

  Use this only when `Array::makei` is awkward (e.g. operating on two different source arrays). For the simple "adjacent pair from one array" case, `Array::makei` is shorter and avoids intermediate iterators.

#### Never mutate arrays that crossed a function boundary

MoonBit shares array references, so any caller still holding the reference will observe your mutation. This is a silent correctness bug, not a style preference.

```mbt check
// BAD — `coords` may be aliased by callers; appending corrupts their view.
fn append_origin(coords : Array[Coord]) -> Unit {
  coords.push(Coord::new(0.0, 0.0))
}

// GOOD — return a new array via spread; original `coords` stays untouched.
fn appended_origin(coords : Array[Coord]) -> Array[Coord] {
  [..coords, Coord::new(0.0, 0.0)]
}
```

The same rule covers `append` / `sort` / `reverse` / `clear` / `swap` / `remove*` / etc. Treat any array reaching your function as **read-only** unless the function is documented to mutate it (and the caller has clearly opted in by ownership transfer).

#### Avoid mutation even on local copies

If you find yourself reaching for `let result = arr.copy()` followed by `result.push(...)` or `result.sort()`, look for the immutable form first. The two examples below produce the same final array:

```mbt check
// Don't — uses a mutating push even after copying.
fn close_ring_v1(coords : Array[Coord]) -> Array[Coord] {
  let result = coords.copy()
  if result.length() > 0 && result[0] != result[result.length() - 1] {
    result.push(result[0])
  }
  result
}

// Prefer — single immutable expression; no copy + mutate dance.
fn close_ring(coords : Array[Coord]) -> Array[Coord] {
  let n = coords.length()
  if n == 0 || coords[0] == coords[n - 1] {
    coords
  } else {
    [..coords, coords[0]]
  }
}
```

For sorting, prefer `array.sorted()` (or `iter().collect()` + a sorted-by combinator) over `let result = array.copy(); result.sort()`. The past-participle form (§2) is always available somewhere in the standard library; if it isn't, define one — `fn[T : Compare] Array::sorted(self : Array[T]) -> Array[T]` is one line.

#### When mutation is genuinely necessary

Mutation is only legitimate inside **encapsulated, single-owner** contexts where it cannot escape:

- **Iterator cursors** (e.g. `let mut i = 0` captured by a closure inside `Iter::new`). The mutation lives entirely inside the closure and is invisible to callers.
- **Builder types** with mutable internals that only expose `set_*` (per section 3.1) and a finalising `build()`. The mutable buffer is owned by the builder and never leaks.
- **Measured hot paths** where profiling has shown that `Array::makei` + spread literals are too slow for the workload. Document the reason in a one-line comment, copy the input, mutate the copy, return the result, and never let the mutable buffer cross another function boundary.

Outside these three cases, default to the immutable construction patterns above. **`for i = 0; i < n; i = i + 1 { result.push(...) }` is almost always rewritable with `Array::makei`**. Reach for `makei` first and only fall back to a loop when the per-step logic genuinely cannot be expressed as a function of the index.

#### Immutable collection refactor review checklist

When reviewing MoonBit collection code, the smell is not `for` by itself. The
review finding is a loop paired with mutable flags, mutable result arrays,
`push`, `append`, local copies that are mutated, or array element reassignment
to express a routine collection transformation.

Use this checklist before approving collection refactors:

- Simple transformation: use `map` or `Array::makei` when the output length is
  known.
- Simple filtering: use `filter`; use `filter_map` when the code maps and drops
  missing values in one pass.
- Membership checks: use `any`, `all`, or `contains`; never keep a manual
  `mut found` flag for an existence test.
- Accumulation, grouping, upsert, and merge: use `fold` plus small pure helpers
  such as `upsert_*`, `append_*`, or `merge_*` that return new values.
- Flattening nested arrays: use `flat_map`, `flatten`, or iterator
  concatenation followed by `collect`.
- Order preservation: when replacing upsert or merge logic, preserve
  first-seen outer order and per-item order explicitly in tests or examples.

Manual upsert flags are review findings. Code shaped like `let mut found =
false`, a loop that toggles it, and a trailing `if !found { ... }` should become
a pure helper that either maps over the existing collection or appends a new
item when `any` reports no match.

Array element reassignment is also a review finding when it implements a
collection update, for example `items[index] = updated`. Prefer `map` for
same-length replacement and `fold` for replacement plus conditional append.
Index assignment is acceptable only for genuinely mutable algorithms where the
array is the algorithm's working state and an immutable rewrite would obscure
the logic.

Effectful traversal is not a blanket exception. Calling an async operation
directly inside `for` waits for each iteration before starting the next one.
Classify the operations by dependency: keep genuinely dependent work
sequential, but execute independent filesystem, process, and network operations
with the structured-concurrency rules in section 3.14. Do not replace an async
loop with a recursive helper; that preserves the same sequential execution.

Algorithmic state machines are the other exception. Local `mut` state may remain
for wildcard matchers, parsers, graph walks, geometric kernels, or similar
algorithms where the state is intrinsic and a functional rewrite would reduce
clarity. Keep the mutable state local, document the reason when it is not
obvious, and avoid letting mutable arrays cross function boundaries.

For a structural review, start with this scan and classify every remaining hit:

```bash
rg -n '\bmut\b|\bfor\b|\.push\(|\[[^]]+\]\s*=' mbt --glob '*.mbt'
```

Classify each hit as one of: simple transformation needing refactor, effectful
traversal, algorithmic state machine, unavoidable mutable library object
construction, or test-only imperative setup. Do not approve an unclassified
`mut found`, `push`-based map/filter/fold, or array reassignment used for a
collection update.

### 3.14 Async I/O and Structured Concurrency

An async call blocks its caller until it returns. Async syntax alone therefore
does not make repeated I/O concurrent. Before writing a loop or a sequence of
async calls, identify which operations are independent and start those
operations together.

The rules below follow the official `moonbitlang/async` implementation pinned
by this repository:

- [`all` implementation and contract](https://github.com/moonbitlang/async/blob/v0.19.2/src/async.mbt)
- [`all` ordering, concurrency-limit, failure, and cancellation tests](https://github.com/moonbitlang/async/blob/v0.19.2/src/all_any_test.mbt)

#### Use `@async.all` for homogeneous independent work

Map each input to an `async () -> T` task and pass the tasks to `@async.all`.
It starts every task concurrently by default and returns results in input order,
even when completion order differs.

```mbt check
async fn read_documents(paths : Array[String]) -> Array[String] {
  @async.all(
    paths.map(path => () => @fs.read_file(path).text()),
  )
}
```

Use this shape for independent file reads or writes, directory checks, HTTP
requests, subprocesses operating on distinct resources, and per-entry
resolution. Flatten or filter the ordered result after `@async.all`; do not
mutate a shared result array from the tasks.

#### Use a task group for heterogeneous independent work

When independent operations have different result types, spawn them in one
`@async.with_task_group` and wait for each handle before returning from the
group.

```mbt check
async fn load_inputs(
  config_path : String,
  lock_path : String,
) -> (String, Bool) {
  @async.with_task_group(group => {
    let config_task = group.spawn(() => @fs.read_file(config_path).text())
    let lock_task = group.spawn(() => @fs.exists(lock_path))
    (config_task.wait(), lock_task.wait())
  })
}
```

Do not use a background task for work whose result or failure belongs to the
current operation. Structured tasks must finish or be cancelled before their
owning scope returns.

#### Keep real dependencies sequential

Parallelism is incorrect when one operation supplies state required by the
next operation. Keep such steps visibly ordered:

```mbt check
async fn resolve_revision(source : String) -> String {
  let repo_dir = ensure_repo(source)
  commit_hash(repo_dir)
}
```

Typical dependencies include creating a directory before writing inside it,
cloning a repository before reading its revision, and writing a lock file
before invoking a consumer that reads that file.

#### Prevent shared-resource races

Tasks may run concurrently only when their writes cannot target the same
mutable resource. Before creating tasks:

- deduplicate identical output paths
- resolve and merge data concurrently, then apply deterministic conflict rules
  such as first-wins or last-wins before writing
- partition work by output directory, lock file, Git checkout, or cache entry
- serialize only the conflicting partition when order is part of the contract

Use `max_concurrent` to limit resource pressure or to serialize a known
conflicting batch:

```mbt check
@async.all(tasks, max_concurrent=8) |> ignore
```

Do not use a concurrency limit as a substitute for identifying races. A limit
greater than one still permits conflicting tasks to overlap; a limit of one is
appropriate only when the original order must be retained and the batch cannot
be partitioned safely.

#### Preserve failure and cancellation semantics

`@async.all` propagates the first task failure and cancels other running tasks.
Do not catch and discard cancellation while implementing per-item recovery.

```mbt check
let result = resolve_item(item) catch {
  err if @async.is_being_cancelled() => raise err
  err => {
    println("Skipped \{item}: \{err}")
    None
  }
}
```

Catch an ordinary item failure only when skipping that item is part of the
operation's contract. Otherwise, let the error propagate so sibling tasks are
cancelled and the caller observes the failure.

#### Review and test the concurrency contract

For every async traversal, verify all of the following:

- independent work uses `@async.all` or a task group instead of sequential
  `for` or recursive traversal
- dependent work remains sequential
- result ordering matches the input contract
- duplicate or shared targets cannot race
- concurrency is capped when the task count can be large or the external
  resource has a known limit
- failure propagation and cancellation are preserved

Tests should cover observable ordering, duplicate-target resolution, failure
propagation, and any conflict path that intentionally falls back to sequential
execution.

## 4. Performance Optimization

- **Lazy evaluation with Iterator**: For array processing where the size is unknown or potentially large, prefer `iter()` for lazy evaluation to avoid intermediate array allocations. This is especially effective for fold operations like `minimum()`/`maximum()`:

  ```mbt check
  let min_x = coords.iter().map(c => c.x()).minimum().unwrap()
  ```

- **Flattening**: Use `flatten()` instead of manual loops with `append` when merging nested collections.

## 5. Toolchain

- `moon.pkg` DSL replaces deprecated `moon.pkg.json`.

## 6. Testing

See [MoonBit Testing Standards](../../../test/references/mbt/bestpractice.md) for detailed testing guidelines.

## 7. CLI Applications

See [MoonBit CLI Application Implementation](./cli-application.md) for the required command structure and JSON/request-body rules. The current `totto2727/admiral` API and the repository's Admiral-based implementations take priority over older rules and examples. Do not reintroduce direct `argparse` parsing or dispatch in `main.mbt`.
