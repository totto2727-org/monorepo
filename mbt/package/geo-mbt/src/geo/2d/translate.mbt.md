# translate.mbt

Pure translation of geometries by `(xoff, yoff)`. Each entry point delegates to `AffineTransform::translate_xy`'s `transform` over the corresponding `MapCoords` instance.

## Public API

- `translate_geometry`
- `translate_polygon`
- `translate_point`

## Test

### `translate_polygon`

- Shifts every coordinate by `(xoff, yoff)`

```mbt check
///|
test "translate_polygon - shifts all coords" {
  let exterior = @type.LineString::from_tuples([
    (0.0, 0.0),
    (1.0, 0.0),
    (1.0, 1.0),
    (0.0, 1.0),
  ])
  let polygon = @type.Polygon::Polygon(exterior, [])
  let translated = translate_polygon(polygon, 10.0, 20.0)
  let coords = translated.exterior().coords()
  @test.assert_eq(coords[0], @type.Coord::Coord(10.0, 20.0))
  @test.assert_eq(coords[1], @type.Coord::Coord(11.0, 20.0))
  @test.assert_eq(coords[2], @type.Coord::Coord(11.0, 21.0))
}
```

### `translate_point`

- Shifts the point's coordinate

```mbt check
///|
test "translate_point - shifts the coord" {
  let p = @type.Point::Point(1.0, 2.0)
  @test.assert_eq(
    translate_point(p, 10.0, 20.0),
    @type.Point::Point(11.0, 22.0),
  )
}
```

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
