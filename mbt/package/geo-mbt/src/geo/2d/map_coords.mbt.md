# map_coords.mbt

Per-`Coord` transformation lifted over every geometry shape via the `MapCoords::map_coords` trait. The structural skeleton (which polygons have which holes, which line strings live in which collection) is preserved exactly; only the coord values change. Trait impls live alongside the definition.

## Public API

- `MapCoords` — `map_coords` (impls in this file)

## Test

### `MapCoords`

#### `map_coords`

| Variable | State                        | Note                                  |  1  |  2  |  3  |
| :------- | :--------------------------- | :------------------------------------ | :-: | :-: | :-: |
| `self`   | `Point` + shift `f`          | applies `f` to the single coord       |  ✓  |     |     |
| `self`   | `Polygon` + scale `f`        | applies `f` to every ring's coords    |     |  ✓  |     |
| `self`   | `Geometry::Point` + identity | round-trip (`map_coords(g, id) == g`) |     |     |  ✓  |

- `Point` shifts the underlying coord

```mbt check
///|
test "MapCoords::map_coords - Point shifts the coord" {
  let p = @type.Point::Point(1.0, 2.0)
  @test.assert_eq(
    MapCoords::map_coords(p, fn(c) {
      @type.Coord::Coord(c.x() + 10.0, c.y() + 20.0)
    }),
    @type.Point::Point(11.0, 22.0),
  )
}
```

- `Polygon` transforms every ring's coords

```mbt check
///|
test "MapCoords::map_coords - Polygon transforms every ring's coords" {
  let exterior = @type.LineString::from_tuples([
    (0.0, 0.0),
    (1.0, 0.0),
    (1.0, 1.0),
    (0.0, 1.0),
  ])
  let polygon = @type.Polygon::Polygon(exterior, [])
  let scaled = MapCoords::map_coords(polygon, fn(c) { c.mul(2.0) })
  let scaled_coords = scaled.exterior().coords()
  @test.assert_eq(scaled_coords[1], @type.Coord::Coord(2.0, 0.0))
  @test.assert_eq(scaled_coords[2], @type.Coord::Coord(2.0, 2.0))
}
```

- Direct dispatch on every concrete type (identity round-trip)

```mbt check
///|
test "MapCoords::map_coords - direct dispatch on every concrete type" {
  let identity = fn(c : @type.Coord) -> @type.Coord { c }
  let pt = @type.Point::Point(1.0, 2.0)
  let l = @type.Line::from_tuples((0.0, 0.0), (1.0, 1.0))
  let ls = @type.LineString::from_tuples([(0.0, 0.0), (1.0, 1.0)])
  let mp = @type.MultiPoint::from_tuples([(0.0, 0.0)])
  let mls = @type.MultiLineString::MultiLineString([ls])
  let polygon = @type.Polygon::Polygon(
    @type.LineString::from_tuples([
      (0.0, 0.0),
      (4.0, 0.0),
      (4.0, 4.0),
      (0.0, 4.0),
    ]),
    [],
  )
  let mpoly = @type.MultiPolygon::MultiPolygon([polygon])
  let r = @type.Rect::Rect(
    @type.Coord::Coord(0.0, 0.0),
    @type.Coord::Coord(1.0, 1.0),
  )
  let tri = @type.Triangle::Triangle(
    @type.Coord::Coord(0.0, 0.0),
    @type.Coord::Coord(1.0, 0.0),
    @type.Coord::Coord(0.0, 1.0),
  )
  let gc = @type.GeometryCollection::GeometryCollection([
    @type.Geometry::Point(pt),
  ])
  @test.assert_eq(MapCoords::map_coords(pt, identity), pt)
  @test.assert_eq(MapCoords::map_coords(l, identity), l)
  @test.assert_eq(MapCoords::map_coords(ls, identity), ls)
  @test.assert_eq(MapCoords::map_coords(mp, identity), mp)
  @test.assert_eq(MapCoords::map_coords(mls, identity), mls)
  @test.assert_eq(MapCoords::map_coords(polygon, identity), polygon)
  @test.assert_eq(MapCoords::map_coords(mpoly, identity), mpoly)
  @test.assert_eq(MapCoords::map_coords(r, identity), r)
  @test.assert_eq(MapCoords::map_coords(tri, identity), tri)
  @test.assert_eq(MapCoords::map_coords(gc, identity), gc)
}
```

- `Geometry::Point` round-trip with identity

```mbt check
///|
test "MapCoords::map_coords - Geometry::Point round-trip with identity" {
  let p = @type.Point::Point(3.5, 7.0)
  let g = @type.Geometry::Point(p)
  @test.assert_eq(MapCoords::map_coords(g, fn(c) { c }), g)
}
```
