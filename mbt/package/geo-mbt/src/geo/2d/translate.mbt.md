# translate.mbt

Pure translation of geometries by `(xoff, yoff)`. The public surface is the unified `translate_geometry` entry point and `AffineTransform::translate_xy().transform(...)` for callers that already work with concrete `MapCoords` types.

## Public API

- `translate_geometry`

## Test

### `translate_geometry`

- Dispatches over the `Geometry` enum and shifts the underlying coords

```mbt check
///|
test "translate_geometry - shifts a Point variant" {
  let g = @type.Geometry::Point(@type.Point::Point(1.0, 2.0))
  let extracted = try! translate_geometry(g, 10.0, 20.0).try_into_point()
  @test.assert_eq(extracted, @type.Point::Point(11.0, 22.0))
}
```

- Shifts every coordinate of a `Polygon` variant

```mbt check
///|
test "translate_geometry - shifts all coords of a Polygon variant" {
  let exterior = @type.LineString::from_tuples([
    (0.0, 0.0),
    (1.0, 0.0),
    (1.0, 1.0),
    (0.0, 1.0),
  ])
  let polygon = @type.Polygon::Polygon(exterior, [])
  let translated = try! translate_geometry(
      @type.Geometry::Polygon(polygon),
      10.0,
      20.0,
    ).try_into_polygon()
  let coords = translated.exterior().coords()
  @test.assert_eq(coords[0], @type.Coord::Coord(10.0, 20.0))
  @test.assert_eq(coords[1], @type.Coord::Coord(11.0, 20.0))
  @test.assert_eq(coords[2], @type.Coord::Coord(11.0, 21.0))
}
```

### `AffineTransform::translate_xy().transform`

- Direct `MapCoords`-typed entry point (no `Geometry` wrapping)

```mbt check
///|
test "AffineTransform::translate_xy().transform - direct typed entry point" {
  let p = @type.Point::Point(1.0, 2.0)
  @test.assert_eq(
    AffineTransform::translate_xy(10.0, 20.0).transform(p),
    @type.Point::Point(11.0, 22.0),
  )
}
```
