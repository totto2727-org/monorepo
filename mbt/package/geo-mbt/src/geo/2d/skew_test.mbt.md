# skew.mbt

Geometry skew (shear). `skew_geometry` applies the shear around the origin; `skew_geometry_around` shears around an arbitrary pivot.

## Public API

- `skew_geometry`
- `skew_geometry_around`

## Test

### `skew_geometry`

- 45° X-skew shifts a `(1, 1)` point onto `(2, 1)` (since `tan(45°) = 1` so `x' = x + 1·y`)

```mbt check
///|
test "skew_geometry - 45 deg X-skew shifts (1,1) to (2,1)" {
  let g = @type.Geometry::Point(@type.Point::Point(1.0, 1.0))
  let pt = try! skew_geometry(g, 45.0, 0.0).try_into_point()
  // Up to floating-point round-off the result is (2, 1).
  assert_true((pt.x() - 2.0).abs() < 1.0e-9)
  assert_true((pt.y() - 1.0).abs() < 1.0e-9)
}
```

### `skew_geometry_around`

- Skewing a point around itself leaves it unchanged

```mbt check
///|
test "skew_geometry_around - pivot at the point leaves it unchanged" {
  let g = @type.Geometry::Point(@type.Point::Point(3.0, 4.0))
  let sheared = skew_geometry_around(
    g,
    45.0,
    30.0,
    @type.Coord::Coord(3.0, 4.0),
  )
  let pt = try! sheared.try_into_point()
  assert_true((pt.x() - 3.0).abs() < 1.0e-9)
  assert_true((pt.y() - 4.0).abs() < 1.0e-9)
}
```
