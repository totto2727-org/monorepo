# centroid.mbt

Geometric centroid (centre of mass) of every geometry. Polygon centroids weight by signed area (interior holes contribute negatively); linestring centroids weight by segment length; collections weight by their natural mass. Exposed via the `HasCentroid::centroid` trait.

## Public API

- `HasCentroid` — `centroid` (impls in this file)

## Test

### `HasCentroid`

#### `centroid`

| Variable | State                   | Note                                |  1  |  2  |  3  |
| :------- | :---------------------- | :---------------------------------- | :-: | :-: | :-: |
| `self`   | `Polygon (unit square)` | centre at `(0.5, 0.5)`              |  ✓  |     |     |
| `self`   | `Triangle (right)`      | centre at average of three vertices |     |  ✓  |     |
| `self`   | `Rect`                  | matches `Rect::center`              |     |     |  ✓  |

- Polygon: unit square centroid is at `(0.5, 0.5)`

```mbt check
///|
test "HasCentroid::centroid - unit square Polygon centroid is (0.5, 0.5)" {
  let exterior = @type.LineString::from_tuples([
    (0.0, 0.0),
    (1.0, 0.0),
    (1.0, 1.0),
    (0.0, 1.0),
    (0.0, 0.0),
  ])
  let polygon = @type.Polygon::Polygon(exterior, [])
  let c = match HasCentroid::centroid(polygon) {
    Some(p) => p
    None => abort("expected centroid for non-empty polygon")
  }
  assert_true((c.x() - 0.5).abs() < TOLERANCE)
  assert_true((c.y() - 0.5).abs() < TOLERANCE)
}
```

- LineString and MultiPolygon: direct trait dispatch

```mbt check
///|
test "HasCentroid::centroid - LineString and MultiPolygon direct dispatch" {
  let ls = @type.LineString::from_tuples([(0.0, 0.0), (10.0, 0.0)])
  @test.assert_eq(HasCentroid::centroid(ls), Some(@type.Point::Point(5.0, 0.0)))
  let polygon = @type.Polygon::Polygon(
    @type.LineString::from_tuples([
      (0.0, 0.0),
      (4.0, 0.0),
      (4.0, 4.0),
      (0.0, 4.0),
    ]),
    [],
  )
  let mp = @type.MultiPolygon::MultiPolygon([polygon])
  @test.assert_eq(HasCentroid::centroid(mp), Some(@type.Point::Point(2.0, 2.0)))
}
```

- Triangle: centroid is `(avg(x), avg(y))` of the three vertices

```mbt check
///|
test "HasCentroid::centroid - Triangle centroid is the average of its vertices" {
  let t = @type.Triangle::Triangle(
    @type.Coord::Coord(0.0, 0.0),
    @type.Coord::Coord(6.0, 0.0),
    @type.Coord::Coord(0.0, 9.0),
  )
  let c = match HasCentroid::centroid(@type.Geometry::Triangle(t)) {
    Some(p) => p
    None => abort("expected centroid for non-degenerate triangle")
  }
  @test.assert_eq(c, @type.Point::Point(2.0, 3.0))
}
```

- Rect: centroid matches `Rect::center`

```mbt check
///|
test "HasCentroid::centroid - Rect centroid is Rect::center" {
  let r = @type.Rect::Rect(
    @type.Coord::Coord(0.0, 0.0),
    @type.Coord::Coord(10.0, 20.0),
  )
  let c = match HasCentroid::centroid(@type.Geometry::Rect(r)) {
    Some(p) => p
    None => abort("expected centroid for non-degenerate rect")
  }
  @test.assert_eq(c, @type.Point::from_coord(r.center()))
}
```

- Every `Geometry` variant dispatches to a sensible centroid

```mbt check
///|
test "HasCentroid::centroid - dispatch covers every Geometry variant" {
  // Point: centroid is the point itself.
  @test.assert_eq(
    HasCentroid::centroid(@type.Geometry::Point(@type.Point::Point(3.0, 4.0))),
    Some(@type.Point::Point(3.0, 4.0)),
  )
  // Line: centroid is the midpoint.
  @test.assert_eq(
    HasCentroid::centroid(
      @type.Geometry::Line(@type.Line::from_tuples((0.0, 0.0), (10.0, 20.0))),
    ),
    Some(@type.Point::Point(5.0, 10.0)),
  )
  // LineString: weighted by segment length.
  let ls = @type.LineString::from_tuples([(0.0, 0.0), (10.0, 0.0)])
  @test.assert_eq(
    HasCentroid::centroid(@type.Geometry::LineString(ls)),
    Some(@type.Point::Point(5.0, 0.0)),
  )
  // MultiPoint: average of points.
  let mp = @type.MultiPoint::from_tuples([(0.0, 0.0), (4.0, 0.0), (2.0, 6.0)])
  @test.assert_eq(
    HasCentroid::centroid(@type.Geometry::MultiPoint(mp)),
    Some(@type.Point::Point(2.0, 2.0)),
  )
  // MultiLineString: length-weighted across components.
  let mls = @type.MultiLineString::MultiLineString([
    @type.LineString::from_tuples([(0.0, 0.0), (10.0, 0.0)]),
  ])
  @test.assert_eq(
    HasCentroid::centroid(@type.Geometry::MultiLineString(mls)),
    Some(@type.Point::Point(5.0, 0.0)),
  )
  // MultiPolygon: area-weighted across polygons.
  let mp_poly = @type.MultiPolygon::MultiPolygon([
    @type.Polygon::Polygon(
      @type.LineString::from_tuples([
        (0.0, 0.0),
        (4.0, 0.0),
        (4.0, 4.0),
        (0.0, 4.0),
      ]),
      [],
    ),
  ])
  @test.assert_eq(
    HasCentroid::centroid(@type.Geometry::MultiPolygon(mp_poly)),
    Some(@type.Point::Point(2.0, 2.0)),
  )
  // GeometryCollection: arithmetic mean of component centroids.
  let gc = @type.GeometryCollection::GeometryCollection([
    @type.Geometry::Point(@type.Point::Point(0.0, 0.0)),
    @type.Geometry::Point(@type.Point::Point(4.0, 0.0)),
  ])
  @test.assert_eq(
    HasCentroid::centroid(@type.Geometry::GeometryCollection(gc)),
    Some(@type.Point::Point(2.0, 0.0)),
  )
}
```

- Edge cases: empty / degenerate inputs return `None`

```mbt check
///|
test "HasCentroid::centroid - degenerate inputs return None" {
  @test.assert_eq(
    HasCentroid::centroid(
      @type.Geometry::MultiPolygon(@type.MultiPolygon::empty()),
    ),
    None,
  )
  @test.assert_eq(
    HasCentroid::centroid(@type.Geometry::LineString(@type.LineString::empty())),
    None,
  )
  @test.assert_eq(
    HasCentroid::centroid(
      @type.Geometry::GeometryCollection(@type.GeometryCollection::empty()),
    ),
    None,
  )
  @test.assert_eq(
    HasCentroid::centroid(
      @type.Geometry::MultiLineString(@type.MultiLineString::empty()),
    ),
    None,
  )
}
```
