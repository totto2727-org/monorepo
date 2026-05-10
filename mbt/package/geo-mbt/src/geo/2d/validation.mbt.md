# validation.mbt

Reports `ValidationProblem`s detected on a `Geometry` (e.g. fewer-than-2 coords on a `LineString`, non-closed polygon ring, non-finite coord, self-intersection). `is_valid` returns `true` when no problems are detected. Each problem carries positional information: `RingRole` for polygon rings, `CoordIndex` for coordinate-level issues, and `GeometryIndex` for multi-geometry child problems.

## Public API

- `RingRole`
- `CoordIndex`
- `GeometryIndex`
- `ValidationProblem`
- `validation_problems`
- `is_valid`

## Test

### `validation_problems` / `is_valid`

| Variable | State                                     | Note                   |  1  |  2  |  3  |  4  |  5  |  6  |  7  |  8  |
| :------- | :---------------------------------------- | :--------------------- | :-: | :-: | :-: | :-: | :-: | :-: | :-: | :-: |
| `g`      | `Polygon (4-coord exterior, auto-closed)` | valid                  |  ✓  |     |     |     |     |     |     |     |
| `g`      | `LineString with 1 coord`                 | invalid (too few)      |     |  ✓  |     |     |     |     |     |     |
| `g`      | `LineString with 2 coords`                | valid                  |     |     |  ✓  |     |     |     |     |     |
| `g`      | `Point with NaN coord`                    | invalid (non-finite)   |     |     |     |  ✓  |     |     |     |     |
| `g`      | `Polygon with 2-coord exterior`           | invalid (ring too few) |     |     |     |     |  ✓  |     |     |     |
| `g`      | `Line with identical coords`              | invalid (identical)    |     |     |     |     |     |  ✓  |     |     |
| `g`      | `Polygon ring with self-intersection`     | invalid (self-inters.) |     |     |     |     |     |     |  ✓  |     |
| `g`      | `Triangle with collinear coords`          | invalid (collinear)    |     |     |     |     |     |     |     |  ✓  |

- A 4-coord exterior auto-closes to 5 coords and validates

```mbt check
///|
test "is_valid - 4-coord exterior auto-closes and validates" {
  let exterior = @type.LineString::from_tuples([
    (0.0, 0.0),
    (1.0, 0.0),
    (1.0, 1.0),
    (0.0, 1.0),
  ])
  let g = @type.Geometry::Polygon(@type.Polygon::Polygon(exterior, []))
  assert_true(is_valid(g))
  @test.assert_eq(validation_problems(g), [])
}
```

- A 1-coord LineString is invalid (`TooFewPoints`)

```mbt check
///|
test "validation_problems - 1-coord LineString reports TooFewPoints" {
  let g = @type.Geometry::LineString(
    @type.LineString::from_tuples([(0.0, 0.0)]),
  )
  assert_false(is_valid(g))
  @test.assert_eq(validation_problems(g), [ValidationProblem::TooFewPoints])
}
```

- A 2-coord LineString is valid

```mbt check
///|
test "is_valid - 2-coord LineString is valid" {
  let g = @type.Geometry::LineString(
    @type.LineString::from_tuples([(0.0, 0.0), (1.0, 1.0)]),
  )
  assert_true(is_valid(g))
}
```

- A `Point` with a NaN coord reports `NonFinitePointCoord`

```mbt check
///|
test "validation_problems - Point with NaN reports NonFinitePointCoord" {
  let g = @type.Geometry::Point(@type.Point::Point(0.0 / 0.0, 0.0))
  @test.assert_eq(validation_problems(g), [
    ValidationProblem::NonFinitePointCoord,
  ])
}
```

- A 2-coord exterior auto-closes and reports `RingTooFewPoints(Exterior)`

```mbt check
///|
test "validation_problems - 2-coord exterior reports RingTooFewPoints" {
  let exterior = @type.LineString::from_tuples([(0.0, 0.0), (1.0, 1.0)])
  let g = @type.Geometry::Polygon(@type.Polygon::Polygon(exterior, []))
  @test.assert_eq(validation_problems(g), [
    ValidationProblem::RingTooFewPoints(RingRole::Exterior),
  ])
}
```

- A `Line` with identical start and end reports `LineIdenticalCoords`

```mbt check
///|
test "validation_problems - Line identical coords reports LineIdenticalCoords" {
  let g = @type.Geometry::Line(
    @type.Line::Line(@type.Coord::Coord(0.0, 0.0), @type.Coord::Coord(0.0, 0.0)),
  )
  @test.assert_eq(validation_problems(g), [
    ValidationProblem::LineIdenticalCoords,
  ])
}
```

- A polygon ring with self-intersection (bow-tie) reports `SelfIntersection(Exterior)`

```mbt check
///|
test "validation_problems - self-intersecting ring reports SelfIntersection" {
  // Bow-tie shape: (0,0) → (1,1) → (1,0) → (0,1) → (0,0) — segments cross
  let ring = @type.LineString::from_tuples([
    (0.0, 0.0),
    (1.0, 1.0),
    (1.0, 0.0),
    (0.0, 1.0),
    (0.0, 0.0),
  ])
  let g = @type.Geometry::Polygon(@type.Polygon::Polygon(ring, []))
  let ps = validation_problems(g)
  // Should include SelfIntersection(Exterior)
  assert_true(
    ps
    .iter()
    .any(fn(p) { p == ValidationProblem::SelfIntersection(RingRole::Exterior) }),
  )
}
```

- Collinear triangle coords report `TriangleCollinearCoords`

```mbt check
///|
test "validation_problems - collinear triangle reports TriangleCollinearCoords" {
  let t = @type.Triangle::Triangle(
    @type.Coord::Coord(0.0, 0.0),
    @type.Coord::Coord(0.5, 0.5),
    @type.Coord::Coord(1.0, 1.0),
  )
  let g = @type.Geometry::Triangle(t)
  @test.assert_eq(validation_problems(g), [
    ValidationProblem::TriangleCollinearCoords,
  ])
}
```
