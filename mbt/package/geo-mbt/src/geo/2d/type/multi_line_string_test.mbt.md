# multi_line_string.mbt

A collection of `LineString`s. Provides constructors (from a `LineString` array, empty), the `line_strings` accessor, and trait impls for `HasLength` / `IsEmpty` / `IsClosed` (callable via dot syntax such as `mls.length()` because the impls live next to the struct). The `IsClosed` impl treats an empty collection as vacuously closed and otherwise requires every component to be closed.

## Public API

- `MultiLineString::MultiLineString`
- `MultiLineString::empty`
- `MultiLineString::line_strings`
- `HasLength`
  - `length`
- `IsEmpty`
  - `is_empty`
- `IsClosed`
  - `is_closed`
- `Eq` (derived)
- `Default` (derived)

## Test

### `MultiLineString::MultiLineString`

- Simple initialization

```mbt check
///|
test "MultiLineString::MultiLineString - simple initialization" {
  let mls = MultiLineString::MultiLineString([
    LineString::from_tuples([(0.0, 0.0), (1.0, 1.0)]),
  ])
  debug_inspect(
    mls,
    content=(
      #|{ line_strings: [{ coords: [{ x: 0, y: 0 }, { x: 1, y: 1 }] }] }
    ),
  )
}
```

### `MultiLineString::empty`

- Equivalent to `MultiLineString::MultiLineString([])`

```mbt check
///|
test "MultiLineString::empty - equivalent to MultiLineString([])" {
  @test.assert_eq(
    MultiLineString::empty(),
    MultiLineString::MultiLineString([]),
  )
}
```

### `MultiLineString::line_strings`

- Returns the underlying line-string array

```mbt check
///|
test "MultiLineString line_strings - returns underlying array" {
  let ls1 = LineString::from_tuples([(0.0, 0.0), (1.0, 1.0)])
  let ls2 = LineString::from_tuples([(2.0, 0.0), (3.0, 1.0)])
  let mls = MultiLineString::MultiLineString([ls1, ls2])
  @test.assert_eq(mls.line_strings(), [ls1, ls2])
}
```

### `HasLength`

#### `length`

- Returns the number of line strings (callable as `mls.length()` via dot syntax)

```mbt check
///|
test "MultiLineString HasLength::length - returns number of line strings" {
  let mls = MultiLineString::MultiLineString([
    LineString::from_tuples([(0.0, 0.0), (1.0, 1.0)]),
    LineString::from_tuples([(2.0, 0.0), (3.0, 1.0)]),
  ])
  @test.assert_eq(mls.length(), 2)
  @test.assert_eq(HasLength::length(mls), 2)
}
```

### `IsEmpty`

| Variable | State       | Note |  1  |  2  |
| :------- | :---------- | :--- | :-: | :-: |
| `self`   | `Non-empty` |      |  ✓  |     |
| `self`   | `Empty`     |      |     |  ✓  |

#### `is_empty`

- False when non-empty

```mbt check
///|
test "MultiLineString IsEmpty::is_empty - false when non-empty" {
  let mls = MultiLineString::MultiLineString([
    LineString::from_tuples([(0.0, 0.0), (1.0, 1.0)]),
  ])
  assert_false(mls.is_empty())
}
```

- True when empty

```mbt check
///|
test "MultiLineString IsEmpty::is_empty - true when empty" {
  assert_true(MultiLineString::empty().is_empty())
}
```

### `IsClosed`

| Variable | State                        | Note                     |  1  |  2  |  3  |  4  |  5  |
| :------- | :--------------------------- | :----------------------- | :-: | :-: | :-: | :-: | :-: |
| `self`   | `Empty`                      | vacuously closed         |  ✓  |     |     |     |     |
| `self`   | `All closed`                 | true                     |     |  ✓  |     |     |     |
| `self`   | `Single closed`              | true                     |     |     |  ✓  |     |     |
| `self`   | `Mixed (closed first, open)` | false (any open ⇒ false) |     |     |     |  ✓  |     |
| `self`   | `Single open`                | false                    |     |     |     |     |  ✓  |

#### `is_closed`

- Empty is vacuously closed

```mbt check
///|
test "MultiLineString IsClosed::is_closed - empty is vacuously closed" {
  assert_true(MultiLineString::empty().is_closed())
}
```

- All components closed → true

```mbt check
///|
test "MultiLineString IsClosed::is_closed - all components closed" {
  let closed1 = LineString::from_tuples([
    (0.0, 0.0),
    (1.0, 0.0),
    (1.0, 1.0),
    (0.0, 0.0),
  ])
  let closed2 = LineString::from_tuples([
    (10.0, 10.0),
    (12.0, 10.0),
    (10.0, 10.0),
  ])
  let mls = MultiLineString::MultiLineString([closed1, closed2])
  assert_true(mls.is_closed())
}
```

- Single closed component → true

```mbt check
///|
test "MultiLineString IsClosed::is_closed - single closed" {
  let closed = LineString::from_tuples([(0.0, 0.0), (1.0, 0.0), (0.0, 0.0)])
  assert_true(MultiLineString::MultiLineString([closed]).is_closed())
}
```

- Any open component → false (regardless of order)

```mbt check
///|
test "MultiLineString IsClosed::is_closed - any open component yields false" {
  let closed = LineString::from_tuples([
    (0.0, 0.0),
    (1.0, 0.0),
    (1.0, 1.0),
    (0.0, 0.0),
  ])
  let open_ls = LineString::from_tuples([(0.0, 0.0), (1.0, 1.0)])
  assert_false(MultiLineString::MultiLineString([closed, open_ls]).is_closed())
  assert_false(MultiLineString::MultiLineString([open_ls, closed]).is_closed())
}
```

- Single open component → false

```mbt check
///|
test "MultiLineString IsClosed::is_closed - single open" {
  let open_ls = LineString::from_tuples([(0.0, 0.0), (1.0, 1.0)])
  assert_false(MultiLineString::MultiLineString([open_ls]).is_closed())
}
```

### `Eq` (derived)

#### `op_equal`

- Equal and unequal multi line strings

```mbt check
///|
test "MultiLineString Eq::op_equal - equal and unequal" {
  let ls1 = LineString::from_tuples([(0.0, 0.0), (1.0, 1.0)])
  let ls2 = LineString::from_tuples([(2.0, 0.0), (3.0, 1.0)])
  let a = MultiLineString::MultiLineString([ls1, ls2])
  let b = MultiLineString::MultiLineString([ls1, ls2])
  let c = MultiLineString::MultiLineString([ls1])
  @test.assert_eq(a, b)
  @test.assert_not_eq(a, c)
}
```

### `Default` (derived)

#### `default`

- Default is empty

```mbt check
///|
test "MultiLineString Default::default - is empty" {
  let d : MultiLineString = MultiLineString::default()
  @test.assert_eq(d, MultiLineString::empty())
}
```
