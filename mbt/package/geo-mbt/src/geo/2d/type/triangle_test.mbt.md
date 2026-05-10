# triangle.mbt

A bounded 2D area defined by three `Coord` vertices `v0` / `v1` / `v2`. Provides accessors, conversion to its three boundary `Line` segments (`to_lines`), and conversion to a closed `Polygon` (`to_polygon`).

## Public API

- `Triangle::Triangle`
- `Triangle::v0`
- `Triangle::v1`
- `Triangle::v2`
- `Triangle::to_lines`
- `Triangle::to_polygon`
- `Eq` (derived)

## Test

### `Triangle::Triangle`

- Simple initialization

```mbt check
///|
test "Triangle::Triangle - simple initialization" {
  let t = Triangle::Triangle(
    Coord::Coord(0.0, 0.0),
    Coord::Coord(10.0, 0.0),
    Coord::Coord(0.0, 10.0),
  )
  debug_inspect(
    t,
    content=(
      #|{ v0: { x: 0, y: 0 }, v1: { x: 10, y: 0 }, v2: { x: 0, y: 10 } }
    ),
  )
}
```

### `Triangle::v0`

- Returns the first vertex

```mbt check
///|
test "Triangle v0 - returns first vertex" {
  let t = Triangle::Triangle(
    Coord::Coord(0.0, 0.0),
    Coord::Coord(10.0, 0.0),
    Coord::Coord(0.0, 10.0),
  )
  @test.assert_eq(t.v0(), Coord::Coord(0.0, 0.0))
}
```

### `Triangle::v1`

- Returns the second vertex

```mbt check
///|
test "Triangle v1 - returns second vertex" {
  let t = Triangle::Triangle(
    Coord::Coord(0.0, 0.0),
    Coord::Coord(10.0, 0.0),
    Coord::Coord(0.0, 10.0),
  )
  @test.assert_eq(t.v1(), Coord::Coord(10.0, 0.0))
}
```

### `Triangle::v2`

- Returns the third vertex

```mbt check
///|
test "Triangle v2 - returns third vertex" {
  let t = Triangle::Triangle(
    Coord::Coord(0.0, 0.0),
    Coord::Coord(10.0, 0.0),
    Coord::Coord(0.0, 10.0),
  )
  @test.assert_eq(t.v2(), Coord::Coord(0.0, 10.0))
}
```

### `Triangle::to_lines`

- Three segments in `(v0→v1, v1→v2, v2→v0)` order

```mbt check
///|
test "Triangle to_lines - 3 segments in v0→v1, v1→v2, v2→v0 order" {
  let v0 = Coord::Coord(0.0, 0.0)
  let v1 = Coord::Coord(10.0, 0.0)
  let v2 = Coord::Coord(0.0, 10.0)
  let t = Triangle::Triangle(v0, v1, v2)
  @test.assert_eq(t.to_lines(), [
    Line::Line(v0, v1),
    Line::Line(v1, v2),
    Line::Line(v2, v0),
  ])
}
```

### `Triangle::to_polygon`

- Four-coord closed exterior ring (`v0, v1, v2, v0`)

```mbt check
///|
test "Triangle to_polygon - closed four-coord ring" {
  let t = Triangle::Triangle(
    Coord::Coord(0.0, 0.0),
    Coord::Coord(10.0, 0.0),
    Coord::Coord(0.0, 10.0),
  )
  let p = t.to_polygon()
  @test.assert_eq(p.exterior().length(), 4)
  assert_true(p.exterior().is_closed())
}
```

### `Eq` (derived)

#### `op_equal`

- Equal and unequal triangles

```mbt check
///|
test "Triangle Eq::op_equal - equal and unequal" {
  let a = Triangle::Triangle(
    Coord::Coord(0.0, 0.0),
    Coord::Coord(1.0, 0.0),
    Coord::Coord(0.0, 1.0),
  )
  let b = Triangle::Triangle(
    Coord::Coord(0.0, 0.0),
    Coord::Coord(1.0, 0.0),
    Coord::Coord(0.0, 1.0),
  )
  let c = Triangle::Triangle(
    Coord::Coord(0.0, 0.0),
    Coord::Coord(2.0, 0.0),
    Coord::Coord(0.0, 2.0),
  )
  @test.assert_eq(a, b)
  @test.assert_not_eq(a, c)
}
```
