# lines_iter.mbt

Per-geometry edge-iteration trait. `LinesCarrier::lines` returns the line segments composing the geometry: a single segment for `Line`, the `n − 1` segments of a `LineString`, the four edges of a `Rect` / three of a `Triangle`, and concatenations across `MultiLineString` / `Polygon` / `MultiPolygon` / `GeometryCollection`. `Point` / `MultiPoint` produce no segments.

## Public API

- `LinesCarrier` — `lines` (impls for `Line` / `LineString` / `MultiLineString` / `Polygon` / `MultiPolygon` / `Rect` / `Triangle` / `GeometryCollection` / `Geometry`)

## Test

### `LinesCarrier`

#### `lines`

| Variable | State             | Note                |  1  |  2  |  3  |
| :------- | :---------------- | :------------------ | :-: | :-: | :-: |
| `self`   | `LineString`      | `n − 1` segments    |  ✓  |     |     |
| `self`   | `Rect`            | 4 CCW edges         |     |  ✓  |     |
| `self`   | `Geometry::Point` | empty (no segments) |     |     |  ✓  |

- LineString of `n` coords yields `n − 1` segments

```mbt check
///|
test "LinesCarrier::lines - LineString yields n-1 segments" {
  let ls = @type.LineString::from_tuples([(0.0, 0.0), (1.0, 1.0), (2.0, 2.0)])
  @test.assert_eq(LinesCarrier::lines(ls).length(), 2)
}
```

- Rect yields the four CCW edges

```mbt check
///|
test "LinesCarrier::lines - Rect yields 4 edges" {
  let r = @type.Rect::Rect(
    @type.Coord::Coord(0.0, 0.0),
    @type.Coord::Coord(1.0, 1.0),
  )
  @test.assert_eq(LinesCarrier::lines(r).length(), 4)
}
```

- `Geometry::Point` yields no segments

```mbt check
///|
test "LinesCarrier::lines - Geometry::Point yields no segments" {
  @test.assert_eq(
    LinesCarrier::lines(@type.Geometry::Point(@type.Point::Point(1.0, 2.0))),
    [],
  )
}
```

- Direct dispatch on every concrete type (sweep)

```mbt check
///|
test "LinesCarrier::lines - direct dispatch on every concrete type" {
  let l = @type.Line::from_tuples((0.0, 0.0), (1.0, 1.0))
  let ls = @type.LineString::from_tuples([(0.0, 0.0), (1.0, 1.0), (2.0, 2.0)])
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
    @type.Geometry::LineString(ls),
  ])
  @test.assert_eq(LinesCarrier::lines(l), [l])
  @test.assert_eq(LinesCarrier::lines(ls).length(), 2)
  @test.assert_eq(LinesCarrier::lines(mls).length(), 2)
  @test.assert_eq(LinesCarrier::lines(polygon).length(), 4)
  @test.assert_eq(LinesCarrier::lines(mpoly).length(), 4)
  @test.assert_eq(LinesCarrier::lines(r).length(), 4)
  @test.assert_eq(LinesCarrier::lines(tri).length(), 3)
  @test.assert_eq(LinesCarrier::lines(gc).length(), 2)
}
```

- `Geometry` dispatch hits every `match` arm (Point and MultiPoint return empty; the rest delegate to the per-type impl)

```mbt check
///|
test "LinesCarrier::lines - Geometry dispatch hits every match arm" {
  let pt = @type.Geometry::Point(@type.Point::Point(0.0, 0.0))
  let mp = @type.Geometry::MultiPoint(
    @type.MultiPoint::from_tuples([(0.0, 0.0), (1.0, 1.0)]),
  )
  let l = @type.Geometry::Line(@type.Line::from_tuples((0.0, 0.0), (1.0, 1.0)))
  let ls = @type.Geometry::LineString(
    @type.LineString::from_tuples([(0.0, 0.0), (1.0, 1.0)]),
  )
  let mls = @type.Geometry::MultiLineString(
    @type.MultiLineString::MultiLineString([
      @type.LineString::from_tuples([(0.0, 0.0), (1.0, 1.0)]),
    ]),
  )
  let polygon = @type.Polygon::Polygon(
    @type.LineString::from_tuples([
      (0.0, 0.0),
      (4.0, 0.0),
      (4.0, 4.0),
      (0.0, 4.0),
    ]),
    [],
  )
  let g_polygon = @type.Geometry::Polygon(polygon)
  let g_mpoly = @type.Geometry::MultiPolygon(
    @type.MultiPolygon::MultiPolygon([polygon]),
  )
  let g_rect = @type.Geometry::Rect(
    @type.Rect::Rect(@type.Coord::Coord(0.0, 0.0), @type.Coord::Coord(1.0, 1.0)),
  )
  let g_tri = @type.Geometry::Triangle(
    @type.Triangle::Triangle(
      @type.Coord::Coord(0.0, 0.0),
      @type.Coord::Coord(1.0, 0.0),
      @type.Coord::Coord(0.0, 1.0),
    ),
  )
  let g_gc = @type.Geometry::GeometryCollection(
    @type.GeometryCollection::GeometryCollection([
      @type.Geometry::LineString(
        @type.LineString::from_tuples([(0.0, 0.0), (1.0, 1.0)]),
      ),
    ]),
  )
  @test.assert_eq(LinesCarrier::lines(pt), [])
  @test.assert_eq(LinesCarrier::lines(mp), [])
  @test.assert_eq(LinesCarrier::lines(l).length(), 1)
  @test.assert_eq(LinesCarrier::lines(ls).length(), 1)
  @test.assert_eq(LinesCarrier::lines(mls).length(), 1)
  @test.assert_eq(LinesCarrier::lines(g_polygon).length(), 4)
  @test.assert_eq(LinesCarrier::lines(g_mpoly).length(), 4)
  @test.assert_eq(LinesCarrier::lines(g_rect).length(), 4)
  @test.assert_eq(LinesCarrier::lines(g_tri).length(), 3)
  @test.assert_eq(LinesCarrier::lines(g_gc).length(), 1)
}
```
