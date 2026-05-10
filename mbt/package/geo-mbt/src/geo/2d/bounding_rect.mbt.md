# bounding_rect.mbt

Axis-aligned bounding rectangle of a coordinate set or geometry. Exposed via the `Bounded::bbox` trait alongside its impls (the per-type `bounding_rect_of_*` helpers are private).

## Public API

- `Bounded` — `bbox` (impls in this file)

## Test

### `Bounded`

#### `bbox`

| Variable | State                   | Note                               |  1  |  2  |  3  |
| :------- | :---------------------- | :--------------------------------- | :-: | :-: | :-: |
| `self`   | `LineString (3 coords)` | tight rect over (min, max) corners |  ✓  |     |     |
| `self`   | `Point`                 | degenerate zero-size rect at coord |     |  ✓  |     |
| `self`   | `Empty LineString`      | `None`                             |     |     |  ✓  |

- LineString: tight rect over its coords

```mbt check
///|
test "Bounded::bbox - LineString tight rect over its coords" {
  let ls = @type.LineString::from_tuples([
    (40.02, 116.34),
    (42.02, 116.34),
    (42.02, 118.34),
  ])
  @test.assert_eq(
    Bounded::bbox(ls),
    Some(
      @type.Rect::Rect(
        @type.Coord::Coord(40.02, 116.34),
        @type.Coord::Coord(42.02, 118.34),
      ),
    ),
  )
}
```

- Point: degenerate zero-size rect at the coord

```mbt check
///|
test "Bounded::bbox - Point is degenerate zero-size rect" {
  let p = @type.Point::Point(1.0, 2.0)
  let r = match Bounded::bbox(p) {
    Some(r) => r
    None => abort("Point always has a bounding rect")
  }
  @test.assert_eq(r.width(), 0.0)
  @test.assert_eq(r.height(), 0.0)
}
```

- Empty LineString: `None`

```mbt check
///|
test "Bounded::bbox - empty LineString returns None" {
  @test.assert_eq(Bounded::bbox(@type.LineString::empty()), None)
}
```

- Dispatch sweep across every Geometry variant

```mbt check
///|
test "Bounded::bbox - dispatch covers every Geometry variant" {
  // Line: rect over its endpoints.
  @test.assert_eq(
    Bounded::bbox(
      @type.Geometry::Line(@type.Line::from_tuples((0.0, 0.0), (3.0, 4.0))),
    ),
    Some(
      @type.Rect::Rect(
        @type.Coord::Coord(0.0, 0.0),
        @type.Coord::Coord(3.0, 4.0),
      ),
    ),
  )
  // MultiLineString: rect over all coords.
  let mls = @type.MultiLineString::MultiLineString([
    @type.LineString::from_tuples([(0.0, 0.0), (10.0, 5.0)]),
    @type.LineString::from_tuples([(-2.0, 3.0), (4.0, 8.0)]),
  ])
  @test.assert_eq(
    Bounded::bbox(@type.Geometry::MultiLineString(mls)),
    Some(
      @type.Rect::Rect(
        @type.Coord::Coord(-2.0, 0.0),
        @type.Coord::Coord(10.0, 8.0),
      ),
    ),
  )
  // Polygon: rect over the exterior coords.
  let polygon = @type.Polygon::Polygon(
    @type.LineString::from_tuples([
      (0.0, 0.0),
      (10.0, 0.0),
      (10.0, 10.0),
      (0.0, 10.0),
    ]),
    [],
  )
  @test.assert_eq(
    Bounded::bbox(@type.Geometry::Polygon(polygon)),
    Some(
      @type.Rect::Rect(
        @type.Coord::Coord(0.0, 0.0),
        @type.Coord::Coord(10.0, 10.0),
      ),
    ),
  )
  // MultiPolygon: rect over every exterior.
  @test.assert_eq(
    Bounded::bbox(
      @type.Geometry::MultiPolygon(@type.MultiPolygon::MultiPolygon([polygon])),
    ),
    Some(
      @type.Rect::Rect(
        @type.Coord::Coord(0.0, 0.0),
        @type.Coord::Coord(10.0, 10.0),
      ),
    ),
  )
  // Triangle: rect over its three vertices.
  let tri = @type.Triangle::Triangle(
    @type.Coord::Coord(0.0, 0.0),
    @type.Coord::Coord(6.0, 0.0),
    @type.Coord::Coord(3.0, 9.0),
  )
  @test.assert_eq(
    Bounded::bbox(@type.Geometry::Triangle(tri)),
    Some(
      @type.Rect::Rect(
        @type.Coord::Coord(0.0, 0.0),
        @type.Coord::Coord(6.0, 9.0),
      ),
    ),
  )
  // Rect dispatch: itself.
  let r = @type.Rect::Rect(
    @type.Coord::Coord(0.0, 0.0),
    @type.Coord::Coord(7.0, 4.0),
  )
  @test.assert_eq(Bounded::bbox(@type.Geometry::Rect(r)), Some(r))
  // GeometryCollection: rect over all collected coords.
  let gc = @type.GeometryCollection::GeometryCollection([
    @type.Geometry::Point(@type.Point::Point(0.0, 0.0)),
    @type.Geometry::Point(@type.Point::Point(5.0, 5.0)),
  ])
  @test.assert_eq(
    Bounded::bbox(@type.Geometry::GeometryCollection(gc)),
    Some(
      @type.Rect::Rect(
        @type.Coord::Coord(0.0, 0.0),
        @type.Coord::Coord(5.0, 5.0),
      ),
    ),
  )
}
```

- Direct dispatch on every concrete type

```mbt check
///|
test "Bounded::bbox - direct dispatch on every concrete type" {
  let pt = @type.Point::Point(0.0, 0.0)
  let l = @type.Line::from_tuples((0.0, 0.0), (1.0, 1.0))
  let ls = @type.LineString::from_tuples([(0.0, 0.0), (1.0, 1.0)])
  let mp = @type.MultiPoint::from_tuples([(0.0, 0.0), (3.0, 4.0)])
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
  assert_true(Bounded::bbox(pt) is Some(_))
  assert_true(Bounded::bbox(l) is Some(_))
  assert_true(Bounded::bbox(ls) is Some(_))
  assert_true(Bounded::bbox(mp) is Some(_))
  assert_true(Bounded::bbox(mls) is Some(_))
  assert_true(Bounded::bbox(polygon) is Some(_))
  assert_true(Bounded::bbox(mpoly) is Some(_))
  assert_true(Bounded::bbox(r) is Some(_))
  assert_true(Bounded::bbox(tri) is Some(_))
  assert_true(Bounded::bbox(gc) is Some(_))
}
```

- `Coord` impl: degenerate zero-size rect at the coord

```mbt check
///|
test "Bounded::bbox - Coord is a degenerate zero-size rect at itself" {
  let c = @type.Coord::Coord(3.0, 4.0)
  @test.assert_eq(Bounded::bbox(c), Some(@type.Rect::Rect(c, c)))
}
```
