# scale.mbt

Geometry scaling. `scale_geometry` applies a uniform factor around the origin; `scale_geometry_around` scales by separate `xfact` / `yfact` around an arbitrary pivot.

## Public API

- `scale_geometry`
- `scale_geometry_around`

## Test

### `scale_geometry`

- Uniform 2× scale around origin doubles each coordinate

```mbt check
///|
test "scale_geometry - uniform 2x around origin" {
  let g = @type.Geometry::Point(@type.Point::Point(1.0, 2.0))
  let extracted = try! scale_geometry(g, 2.0).try_into_point()
  @test.assert_eq(extracted, @type.Point::Point(2.0, 4.0))
}
```

### `scale_geometry_around`

- 2× × 2× scale around origin pivot doubles each coordinate (matches `scale_geometry`)

```mbt check
///|
test "scale_geometry_around - 2x around origin pivot" {
  let g = @type.Geometry::Point(@type.Point::Point(1.0, 2.0))
  let scaled = scale_geometry_around(g, 2.0, 2.0, @type.Coord::Coord(0.0, 0.0))
  let extracted = try! scaled.try_into_point()
  @test.assert_eq(extracted, @type.Point::Point(2.0, 4.0))
}
```
