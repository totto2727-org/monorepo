# validation.mbt

Reports `ValidationProblem`s detected on a `Geometry` (e.g. fewer-than-2 coords on a `LineString`, non-closed polygon ring, non-finite coord). `is_valid` returns `true` when no problems are detected.

## Public API

- `ValidationProblem`
- `validation_problems`
- `is_valid`

## Test

### `validation_problems` / `is_valid`

| Variable | State                                     | Note                   |  1  |  2  |  3  |  4  |  5  |
| :------- | :---------------------------------------- | :--------------------- | :-: | :-: | :-: | :-: | :-: |
| `g`      | `Polygon (4-coord exterior, auto-closed)` | valid                  |  ✓  |     |     |     |     |
| `g`      | `LineString with 1 coord`                 | invalid (too few)      |     |  ✓  |     |     |     |
| `g`      | `LineString with 2 coords`                | valid                  |     |     |  ✓  |     |     |
| `g`      | `Point with NaN coord`                    | invalid (non-finite)   |     |     |     |  ✓  |     |
| `g`      | `Polygon with 2-coord exterior`           | invalid (ring too few) |     |     |     |     |  ✓  |

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

- A `Point` with a NaN coord reports `NonFiniteCoord`

```mbt check
///|
test "validation_problems - Point with NaN reports NonFiniteCoord" {
  let g = @type.Geometry::Point(@type.Point::Point(0.0 / 0.0, 0.0))
  @test.assert_eq(validation_problems(g), [ValidationProblem::NonFiniteCoord])
}
```

- A 2-coord exterior auto-closes to 3 coords and reports `RingTooFewPoints`

```mbt check
///|
test "validation_problems - 2-coord exterior reports RingTooFewPoints" {
  // A 2-coord input auto-closes to start, mid, start → still < 4.
  let exterior = @type.LineString::from_tuples([(0.0, 0.0), (1.0, 1.0)])
  let g = @type.Geometry::Polygon(@type.Polygon::Polygon(exterior, []))
  @test.assert_eq(validation_problems(g), [ValidationProblem::RingTooFewPoints])
}
```
