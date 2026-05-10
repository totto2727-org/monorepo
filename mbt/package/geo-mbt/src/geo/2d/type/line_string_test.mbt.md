# line_string.mbt

An ordered sequence of `Coord`s representing a path. Provides constructors (from coord array, from tuple array, empty), eager and lazy iteration over coords / points / line segments (forward and reversed), trait-backed accessors (`HasLength` / `IsEmpty` / `IsClosed` — usable via dot syntax such as `ls.length()` because the impls live next to the struct), and an immutable `closed` variant that returns a self-closed copy.

## Public API

- `LineString::LineString`
- `LineString::from_tuples`
- `LineString::empty`
- `LineString::coords`
- `LineString::points`
- `LineString::points_iter`
- `LineString::lines`
- `LineString::lines_iter`
- `LineString::rev_lines`
- `LineString::rev_lines_iter`
- `LineString::closed`
- `HasLength`
  - `length`
- `IsEmpty`
  - `is_empty`
- `IsClosed`
  - `is_closed`
- `Eq` (derived)
- `Default` (derived)

## Test

### `LineString::LineString`

- Simple initialization

```mbt check
///|
test "LineString::LineString - simple initialization" {
  let ls = LineString::LineString([
    Coord::Coord(0.0, 0.0),
    Coord::Coord(1.0, 2.0),
  ])
  debug_inspect(
    ls,
    content=(
      #|{ coords: [{ x: 0, y: 0 }, { x: 1, y: 2 }] }
    ),
  )
}
```

### `LineString::from_tuples`

- Builds from `(x, y)` tuple array

```mbt check
///|
test "LineString::from_tuples - builds from tuple array" {
  let ls = LineString::from_tuples([(0.0, 0.0), (1.0, 1.0), (2.0, 2.0)])
  @test.assert_eq(
    ls,
    LineString::LineString([
      Coord::Coord(0.0, 0.0),
      Coord::Coord(1.0, 1.0),
      Coord::Coord(2.0, 2.0),
    ]),
  )
}
```

### `LineString::empty`

- Equivalent to `LineString::LineString([])`

```mbt check
///|
test "LineString::empty - equivalent to LineString([])" {
  @test.assert_eq(LineString::empty(), LineString::LineString([]))
}
```

### `LineString::coords`

- Returns the underlying coord array

```mbt check
///|
test "LineString coords - returns underlying coord array" {
  let ls = LineString::from_tuples([(0.0, 0.0), (1.0, 2.0)])
  @test.assert_eq(ls.coords(), [Coord::Coord(0.0, 0.0), Coord::Coord(1.0, 2.0)])
}
```

### `LineString::points`

| Variable | State       | Note |  1  |  2  |
| :------- | :---------- | :--- | :-: | :-: |
| `self`   | `Non-empty` |      |  ✓  |     |
| `self`   | `Empty`     |      |     |  ✓  |

- Maps each coord to a `Point`

```mbt check
///|
test "LineString points - maps each coord to Point" {
  let ls = LineString::from_tuples([(0.0, 0.0), (1.0, 2.0), (3.0, 4.0)])
  @test.assert_eq(ls.points(), [
    Point::Point(0.0, 0.0),
    Point::Point(1.0, 2.0),
    Point::Point(3.0, 4.0),
  ])
}
```

- Empty input yields empty array

```mbt check
///|
test "LineString points - empty yields empty array" {
  let ls = LineString::LineString([])
  @test.assert_eq(ls.points(), [])
}
```

### `LineString::points_iter`

- Collects to the same array as `points()`

```mbt check
///|
test "LineString points_iter - matches eager points()" {
  let ls = LineString::from_tuples([(0.0, 0.0), (1.0, 2.0), (3.0, 4.0)])
  @test.assert_eq(ls.points_iter().collect(), ls.points())
}
```

- `take(1)` short-circuits without materialising the rest

```mbt check
///|
test "LineString points_iter - take short-circuits" {
  let ls = LineString::from_tuples([(0.0, 0.0), (1.0, 2.0), (3.0, 4.0)])
  @test.assert_eq(ls.points_iter().take(1).collect(), [Point::Point(0.0, 0.0)])
}
```

### `LineString::lines`

| Variable | State       | Note           |  1  |  2  |  3  |
| :------- | :---------- | :------------- | :-: | :-: | :-: |
| `self`   | `Non-empty` | basic segments |  ✓  |     |     |
| `self`   | `Empty`     | n < 2 guard    |     |  ✓  |     |
| `self`   | `Single`    | n < 2 guard    |     |     |  ✓  |

- Yields each consecutive pair as a `Line`

```mbt check
///|
test "LineString lines - yields consecutive segments" {
  let ls = LineString::from_tuples([(0.0, 0.0), (1.0, 1.0), (2.0, 0.0)])
  @test.assert_eq(ls.lines(), [
    Line::from_tuples((0.0, 0.0), (1.0, 1.0)),
    Line::from_tuples((1.0, 1.0), (2.0, 0.0)),
  ])
}
```

- Empty input yields empty array

```mbt check
///|
test "LineString lines - empty yields empty array" {
  @test.assert_eq(LineString::empty().lines(), [])
}
```

- Single-coord input yields empty array

```mbt check
///|
test "LineString lines - single coord yields empty array" {
  @test.assert_eq(LineString::from_tuples([(1.0, 2.0)]).lines(), [])
}
```

### `LineString::lines_iter`

- Collects to the same array as `lines()`

```mbt check
///|
test "LineString lines_iter - matches eager lines()" {
  let ls = LineString::from_tuples([(0.0, 0.0), (1.0, 1.0), (2.0, 0.0)])
  @test.assert_eq(ls.lines_iter().collect(), ls.lines())
}
```

- Empty / single-coord yields no elements

```mbt check
///|
test "LineString lines_iter - empty or single yields no elements" {
  @test.assert_eq(LineString::empty().lines_iter().collect(), [])
  @test.assert_eq(
    LineString::from_tuples([(1.0, 2.0)]).lines_iter().collect(),
    [],
  )
}
```

- `take(1)` short-circuits without materialising the rest

```mbt check
///|
test "LineString lines_iter - take short-circuits" {
  let ls = LineString::from_tuples([
    (0.0, 0.0),
    (1.0, 1.0),
    (2.0, 0.0),
    (3.0, 5.0),
  ])
  @test.assert_eq(ls.lines_iter().take(1).collect(), [
    Line::from_tuples((0.0, 0.0), (1.0, 1.0)),
  ])
}
```

### `LineString::rev_lines`

| Variable | State       | Note                                  |  1  |  2  |  3  |
| :------- | :---------- | :------------------------------------ | :-: | :-: | :-: |
| `self`   | `Non-empty` | reversed order with swapped endpoints |  ✓  |     |     |
| `self`   | `Empty`     | n < 2 guard                           |     |  ✓  |     |
| `self`   | `Single`    | n < 2 guard                           |     |     |  ✓  |

- Reversed order with each segment's endpoints swapped

```mbt check
///|
test "LineString rev_lines - reversed order with swapped endpoints" {
  let ls = LineString::from_tuples([(0.0, 0.0), (5.0, 0.0), (7.0, 9.0)])
  @test.assert_eq(ls.rev_lines(), [
    Line::from_tuples((7.0, 9.0), (5.0, 0.0)),
    Line::from_tuples((5.0, 0.0), (0.0, 0.0)),
  ])
}
```

- Empty / single-coord yields empty array

```mbt check
///|
test "LineString rev_lines - empty or single yields empty array" {
  @test.assert_eq(LineString::empty().rev_lines(), [])
  @test.assert_eq(LineString::from_tuples([(1.0, 2.0)]).rev_lines(), [])
}
```

- Each `rev_lines[i]` is the reverse of `lines[n − 1 − i]`

```mbt check
///|
test "LineString rev_lines - is reverse of lines with swapped endpoints" {
  let ls = LineString::from_tuples([
    (0.0, 0.0),
    (1.0, 1.0),
    (2.0, 0.0),
    (3.0, 5.0),
  ])
  let forward = ls.lines()
  let reverse = ls.rev_lines()
  let n = forward.length()
  let expected = Array::makei(n, fn(i) {
    let f = forward[n - 1 - i]
    Line::Line(f.end(), f.start())
  })
  @test.assert_eq(reverse, expected)
}
```

### `LineString::rev_lines_iter`

- Collects to the same array as `rev_lines()`

```mbt check
///|
test "LineString rev_lines_iter - matches eager rev_lines()" {
  let ls = LineString::from_tuples([(0.0, 0.0), (5.0, 0.0), (7.0, 9.0)])
  @test.assert_eq(ls.rev_lines_iter().collect(), ls.rev_lines())
}
```

- Empty / single-coord yields no elements

```mbt check
///|
test "LineString rev_lines_iter - empty or single yields no elements" {
  @test.assert_eq(LineString::empty().rev_lines_iter().collect(), [])
  @test.assert_eq(
    LineString::from_tuples([(1.0, 2.0)]).rev_lines_iter().collect(),
    [],
  )
}
```

- `take(1)` returns the last forward segment with endpoints swapped

```mbt check
///|
test "LineString rev_lines_iter - take short-circuits" {
  let ls = LineString::from_tuples([
    (0.0, 0.0),
    (1.0, 1.0),
    (2.0, 0.0),
    (3.0, 5.0),
  ])
  @test.assert_eq(ls.rev_lines_iter().take(1).collect(), [
    Line::from_tuples((3.0, 5.0), (2.0, 0.0)),
  ])
}
```

### `LineString::closed`

| Variable | State            | Note                                        |  1  |  2  |  3  |
| :------- | :--------------- | :------------------------------------------ | :-: | :-: | :-: |
| `self`   | `Open`           | returns a closed copy without mutating self |  ✓  |     |     |
| `self`   | `Already closed` | returns `self` directly (no allocation)     |     |  ✓  |     |
| `self`   | `Empty`          | returns `self` directly                     |     |     |  ✓  |

- Open input → closed copy, original untouched

```mbt check
///|
test "LineString closed - open input returns closed copy without mutating self" {
  let ls = LineString::from_tuples([(0.0, 0.0), (1.0, 1.0), (2.0, 0.0)])
  let len_before = ls.length()
  let was_closed_before = ls.is_closed()
  let c = ls.closed()
  assert_true(c.is_closed())
  @test.assert_eq(c.length(), 4)
  // Original is untouched (immutable semantics).
  @test.assert_eq(ls.length(), len_before)
  @test.assert_eq(ls.is_closed(), was_closed_before)
}
```

- Already-closed input is returned unchanged

```mbt check
///|
test "LineString closed - already closed input returns self" {
  let already_closed = LineString::from_tuples([
    (0.0, 0.0),
    (1.0, 1.0),
    (2.0, 0.0),
    (0.0, 0.0),
  ])
  @test.assert_eq(already_closed.closed(), already_closed)
}
```

- Empty input is returned unchanged

```mbt check
///|
test "LineString closed - empty input returns self" {
  let empty = LineString::empty()
  @test.assert_eq(empty.closed(), empty)
}
```

### `HasLength`

#### `length`

- Returns the number of coords (callable as `ls.length()` via dot syntax)

```mbt check
///|
test "LineString HasLength::length - returns number of coords" {
  let ls = LineString::from_tuples([(0.0, 0.0), (1.0, 1.0), (2.0, 2.0)])
  @test.assert_eq(ls.length(), 3)
  @test.assert_eq(HasLength::length(ls), 3)
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
test "LineString IsEmpty::is_empty - false when non-empty" {
  let ls = LineString::from_tuples([(0.0, 0.0), (1.0, 1.0)])
  assert_false(ls.is_empty())
}
```

- True when empty

```mbt check
///|
test "LineString IsEmpty::is_empty - true when empty" {
  assert_true(LineString::empty().is_empty())
}
```

### `IsClosed`

| Variable | State                         | Note         |  1  |  2  |  3  |  4  |
| :------- | :---------------------------- | :----------- | :-: | :-: | :-: | :-: |
| `self`   | `Open` (≥ 2 coords, ends ≠)   | basic open   |  ✓  |     |     |     |
| `self`   | `Closed` (≥ 2 coords, ends =) | basic closed |     |  ✓  |     |     |
| `self`   | `Empty`                       | n < 2 guard  |     |     |  ✓  |     |
| `self`   | `Single coord`                | n < 2 guard  |     |     |     |  ✓  |

#### `is_closed`

- False when first ≠ last

```mbt check
///|
test "LineString IsClosed::is_closed - false when open" {
  let ls = LineString::from_tuples([(0.0, 0.0), (1.0, 1.0), (2.0, 2.0)])
  assert_false(ls.is_closed())
}
```

- True when first = last

```mbt check
///|
test "LineString IsClosed::is_closed - true when closed" {
  let ls = LineString::from_tuples([
    (0.0, 0.0),
    (1.0, 1.0),
    (2.0, 0.0),
    (0.0, 0.0),
  ])
  assert_true(ls.is_closed())
}
```

- False on empty input (n < 2 guard)

```mbt check
///|
test "LineString IsClosed::is_closed - false on empty" {
  assert_false(LineString::empty().is_closed())
}
```

- False on single-coord input (n < 2 guard)

```mbt check
///|
test "LineString IsClosed::is_closed - false on single coord" {
  let ls = LineString::from_tuples([(1.0, 2.0)])
  assert_false(ls.is_closed())
}
```

### `Eq` (derived)

#### `op_equal`

- Equal and unequal line strings

```mbt check
///|
test "LineString Eq::op_equal - equal and unequal" {
  let a = LineString::from_tuples([(0.0, 0.0), (1.0, 1.0)])
  let b = LineString::from_tuples([(0.0, 0.0), (1.0, 1.0)])
  let c = LineString::from_tuples([(0.0, 0.0), (1.0, 2.0)])
  @test.assert_eq(a, b)
  @test.assert_not_eq(a, c)
}
```

### `Default` (derived)

#### `default`

- Default is empty

```mbt check
///|
test "LineString Default::default - is empty" {
  let d : LineString = LineString::default()
  @test.assert_eq(d, LineString::empty())
}
```
