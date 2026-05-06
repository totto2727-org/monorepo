# line.mbt

A line segment defined by exactly two `Coord`s — `start` and `end`. Provides accessors, `Point` views, vector deltas (`delta` / `dx` / `dy`), `slope`, `determinant`, and `reverse` (a geo-mbt addition that swaps endpoints).

## Public API

- `Line::Line`
- `Line::from_tuples`
- `Line::start`
- `Line::end`
- `Line::start_point`
- `Line::end_point`
- `Line::points`
- `Line::delta`
- `Line::dx`
- `Line::dy`
- `Line::slope`
- `Line::determinant`
- `Line::reverse`
- `Eq` (derived)

## Test

### `Line::Line`

- Simple initialization

```mbt check
///|
test "Line::Line - simple initialization" {
  let line = Line::Line(Coord::Coord(0.0, 0.0), Coord::Coord(1.0, 2.0))
  debug_inspect(
    line,
    content=(
      #|{ start: { x: 0, y: 0 }, end: { x: 1, y: 2 } }
    ),
  )
}
```

### `Line::from_tuples`

- Construct from `(x, y)` tuple pair

```mbt check
///|
test "Line::from_tuples - construct from tuple pair" {
  let line = Line::from_tuples((1.0, 2.0), (3.0, 4.0))
  @test.assert_eq(
    line,
    Line::Line(Coord::Coord(1.0, 2.0), Coord::Coord(3.0, 4.0)),
  )
}
```

### `Line::start`

- Returns the start `Coord`

```mbt check
///|
test "Line start - returns start coord" {
  let line = Line::Line(Coord::Coord(0.0, 0.0), Coord::Coord(1.0, 2.0))
  @test.assert_eq(line.start(), Coord::Coord(0.0, 0.0))
}
```

### `Line::end`

- Returns the end `Coord`

```mbt check
///|
test "Line end - returns end coord" {
  let line = Line::Line(Coord::Coord(0.0, 0.0), Coord::Coord(1.0, 2.0))
  @test.assert_eq(line.end(), Coord::Coord(1.0, 2.0))
}
```

### `Line::start_point`

- Returns the start as a `Point`

```mbt check
///|
test "Line start_point - returns start as Point" {
  let line = Line::Line(Coord::Coord(0.0, 0.0), Coord::Coord(3.0, 4.0))
  @test.assert_eq(line.start_point(), Point::Point(0.0, 0.0))
}
```

### `Line::end_point`

- Returns the end as a `Point`

```mbt check
///|
test "Line end_point - returns end as Point" {
  let line = Line::Line(Coord::Coord(0.0, 0.0), Coord::Coord(3.0, 4.0))
  @test.assert_eq(line.end_point(), Point::Point(3.0, 4.0))
}
```

### `Line::points`

- Returns `(start_point, end_point)` pair

```mbt check
///|
test "Line points - returns start_point, end_point pair" {
  let line = Line::Line(Coord::Coord(0.0, 0.0), Coord::Coord(3.0, 4.0))
  @test.assert_eq(
    line.points(),
    (Point::Point(0.0, 0.0), Point::Point(3.0, 4.0)),
  )
}
```

### `Line::delta`

- Returns `(Δx, Δy)` as a `Coord`

```mbt check
///|
test "Line delta - difference Δx, Δy" {
  let line = Line::Line(Coord::Coord(4.0, -12.0), Coord::Coord(0.0, 9.0))
  @test.assert_eq(line.delta(), Coord::Coord(-4.0, 21.0))
}
```

### `Line::dx`

- Difference in `x` components

```mbt check
///|
test "Line dx - difference in x" {
  let line = Line::Line(Coord::Coord(4.0, -12.0), Coord::Coord(0.0, 9.0))
  @test.assert_eq(line.dx(), -4.0)
}
```

### `Line::dy`

- Difference in `y` components

```mbt check
///|
test "Line dy - difference in y" {
  let line = Line::Line(Coord::Coord(4.0, -12.0), Coord::Coord(0.0, 9.0))
  @test.assert_eq(line.dy(), 21.0)
}
```

### `Line::slope`

| Variable | State             | Note                               |  1  |  2  |
| :------- | :---------------- | :--------------------------------- | :-: | :-: |
| `self`   | `Forward (a, b)`  | basic Δy / Δx                      |  ✓  |     |
| `self`   | `Reversed (b, a)` | direction-independent (same slope) |     |  ✓  |

- Basic Δy / Δx

```mbt check
///|
test "Line slope - basic Δy over Δx" {
  let line = Line::Line(Coord::Coord(4.0, -12.0), Coord::Coord(0.0, 9.0))
  @test.assert_eq(line.slope(), 21.0 / -4.0)
}
```

- Direction-independent

```mbt check
///|
test "Line slope - direction-independent" {
  let a = Coord::Coord(4.0, -12.0)
  let b = Coord::Coord(0.0, 9.0)
  @test.assert_eq(Line::Line(a, b).slope(), Line::Line(b, a).slope())
}
```

### `Line::determinant`

| Variable | State             | Note        |  1  |  2  |
| :------- | :---------------- | :---------- | :-: | :-: |
| `self`   | `Forward (a, b)`  | basic value |  ✓  |     |
| `self`   | `Reversed (b, a)` | sign flips  |     |  ✓  |

- Basic `start.x * end.y − start.y * end.x`

```mbt check
///|
test "Line determinant - basic" {
  let line = Line::Line(Coord::Coord(4.0, -12.0), Coord::Coord(0.0, 9.0))
  @test.assert_eq(line.determinant(), 4.0 * 9.0 - -12.0 * 0.0)
}
```

- Sign flips on swapped endpoints

```mbt check
///|
test "Line determinant - flips sign on reversal" {
  let a = Coord::Coord(4.0, -12.0)
  let b = Coord::Coord(0.0, 9.0)
  @test.assert_eq(
    Line::Line(a, b).determinant(),
    -Line::Line(b, a).determinant(),
  )
}
```

### `Line::reverse`

| Variable | State     | Note                                                  |  1  |  2  |  3  |
| :------- | :-------- | :---------------------------------------------------- | :-: | :-: | :-: |
| `self`   | `Once`    | swaps start and end                                   |  ✓  |     |     |
| `self`   | `Twice`   | involutive (`reverse().reverse() == self`)            |     |  ✓  |     |
| `self`   | `vs swap` | matches `Line::Line(b, a)` and flips determinant sign |     |     |  ✓  |

- Swaps start and end

```mbt check
///|
test "Line reverse - swaps start and end" {
  let line = Line::from_tuples((1.0, 2.0), (3.0, 4.0))
  let r = line.reverse()
  @test.assert_eq(r, Line::Line(Coord::Coord(3.0, 4.0), Coord::Coord(1.0, 2.0)))
}
```

- Involutive (`reverse().reverse() == self`)

```mbt check
///|
test "Line reverse - involutive" {
  let line = Line::from_tuples((-2.5, 7.0), (8.0, -1.5))
  @test.assert_eq(line.reverse().reverse(), line)
}
```

- Matches `Line::Line(b, a)` and flips determinant sign

```mbt check
///|
test "Line reverse - flips determinant and matches reversed-construct" {
  let a = Coord::Coord(4.0, -12.0)
  let b = Coord::Coord(0.0, 9.0)
  let forward = Line::Line(a, b)
  let reversed = forward.reverse()
  @test.assert_eq(reversed.determinant(), -forward.determinant())
  @test.assert_eq(reversed, Line::Line(b, a))
}
```

### `Eq` (derived)

#### `op_equal`

- Equal and unequal lines

```mbt check
///|
test "Line Eq::op_equal - equal and unequal" {
  let a = Line::from_tuples((0.0, 0.0), (1.0, 1.0))
  let b = Line::from_tuples((0.0, 0.0), (1.0, 1.0))
  let c = Line::from_tuples((0.0, 0.0), (1.0, 2.0))
  @test.assert_eq(a, b)
  @test.assert_not_eq(a, c)
}
```
