# traits.mbt

Constraint-only traits aggregating per-type inherent methods into reusable behavioural contracts (`CoordsCarrier`, `Bounded`, `HasArea`, `HasCentroid`, `HasEuclideanLength`, `LinesCarrier`, `HasDimensions`, `HasExtremes`, `ExteriorCoordsCarrier`, `HasConvexHull`, `ClosestPoint`, `CoordPositionFor`, `Simplify`, `Densify`, `MapCoords`). Per-trait behavioural tests live in the corresponding algorithm test file; this file exercises trait-level smoke checks plus the generic-constraint use case that motivates the abstraction.

## Public API

- `CoordsCarrier`
- `Bounded`
- `HasArea`
- `HasCentroid`
- `HasEuclideanLength`
- `LinesCarrier`
- `HasDimensions`
- `HasExtremes`
- `ExteriorCoordsCarrier`
- `HasConvexHull`
- `ClosestPoint`
- `CoordPositionFor`
- `Simplify`
- `Densify`
- `MapCoords`

## Test

### `CoordsCarrier`

- Trait dispatch on `Point`

```mbt check
///|
test "CoordsCarrier - dispatches to per-type coords()" {
  let p : @type.Point = @type.Point::Point(1.0, 2.0)
  @test.assert_eq(CoordsCarrier::coords(p), [@type.Coord::Coord(1.0, 2.0)])
}
```

### `Bounded`

| Variable | State              | Note                          |  1  |  2  |
| :------- | :----------------- | :---------------------------- | :-: | :-: |
| `self`   | `Point`            | `Some(...)` (degenerate rect) |  ✓  |     |
| `self`   | `Empty MultiPoint` | `None`                        |     |  ✓  |

- Per-variant dispatch

```mbt check
///|
test "Bounded - returns Some for non-empty, None for empty" {
  let pt : @type.Point = @type.Point::Point(1.0, 2.0)
  let mp_empty = @type.MultiPoint::empty()
  assert_true(Bounded::bbox(pt) is Some(_))
  @test.assert_eq(Bounded::bbox(mp_empty), None)
}
```

- Heterogeneous variants share the same trait surface (`Bounded::bbox` works on both `Point` and `LineString` via the same call site)

```mbt check
///|
test "Bounded - same trait call site works on different types" {
  let pt : @type.Point = @type.Point::Point(3.0, 4.0)
  let ls : @type.LineString = @type.LineString::from_tuples([
    (0.0, 0.0),
    (3.0, 4.0),
  ])
  @test.assert_eq(
    Bounded::bbox(pt),
    Some(
      @type.Rect::Rect(
        @type.Coord::Coord(3.0, 4.0),
        @type.Coord::Coord(3.0, 4.0),
      ),
    ),
  )
  @test.assert_eq(
    Bounded::bbox(ls),
    Some(
      @type.Rect::Rect(
        @type.Coord::Coord(0.0, 0.0),
        @type.Coord::Coord(3.0, 4.0),
      ),
    ),
  )
}
```

### `HasArea`

- Trait dispatch on `Rect`

```mbt check
///|
test "HasArea - dispatches to Rect::width * Rect::height" {
  let r = @type.Rect::Rect(
    @type.Coord::Coord(0.0, 0.0),
    @type.Coord::Coord(3.0, 4.0),
  )
  @test.assert_eq(HasArea::signed_area(r), 12.0)
  @test.assert_eq(HasArea::unsigned_area(r), 12.0)
}
```

### `HasCentroid`

- Trait dispatch on `Polygon`

```mbt check
///|
test "HasCentroid - dispatches to per-type centroid()" {
  let p = @type.Polygon::Polygon(
    @type.LineString::from_tuples([
      (0.0, 0.0),
      (4.0, 0.0),
      (4.0, 4.0),
      (0.0, 4.0),
    ]),
    [],
  )
  let c = match HasCentroid::centroid(p) {
    Some(c) => c
    None => abort("expected centroid for non-degenerate polygon")
  }
  assert_true((c.x() - 2.0).abs() < TOLERANCE)
  assert_true((c.y() - 2.0).abs() < TOLERANCE)
}
```

### `HasEuclideanLength`

- Trait dispatch on `LineString`

```mbt check
///|
test "HasEuclideanLength - dispatches to LineString length sum" {
  let ls = @type.LineString::from_tuples([(0.0, 0.0), (3.0, 0.0), (3.0, 4.0)])
  @test.assert_eq(HasEuclideanLength::euclidean_length(ls), 7.0)
}
```

### `LinesCarrier`

| Variable | State             | Note             |  1  |  2  |  3  |
| :------- | :---------------- | :--------------- | :-: | :-: | :-: |
| `self`   | `LineString`      | `n - 1` segments |  ✓  |     |     |
| `self`   | `Rect`            | 4 edges          |     |  ✓  |     |
| `self`   | `Geometry::Point` | empty            |     |     |  ✓  |

- LineString of `n` coords yields `n - 1` segments

```mbt check
///|
test "LinesCarrier - LineString yields n-1 segments" {
  let ls = @type.LineString::from_tuples([(0.0, 0.0), (1.0, 1.0), (2.0, 2.0)])
  @test.assert_eq(LinesCarrier::lines(ls).length(), 2)
}
```

- Rect yields the four CCW edges

```mbt check
///|
test "LinesCarrier - Rect yields 4 edges" {
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
test "LinesCarrier - Geometry::Point yields no segments" {
  let g = @type.Geometry::Point(@type.Point::Point(1.0, 2.0))
  @test.assert_eq(LinesCarrier::lines(g), [])
}
```

### `HasDimensions`

Behavioural coverage in `dimensions_test.mbt.md`.

### `HasExtremes`

Behavioural coverage in `extremes_test.mbt.md`.

### `ExteriorCoordsCarrier`

Behavioural coverage in `coords_iter_test.mbt.md`.

### `HasConvexHull`

Behavioural coverage in `convex_hull_test.mbt.md`.

### `ClosestPoint`

Behavioural coverage in `closest_point_test.mbt.md`.

### `CoordPositionFor`

Behavioural coverage in `coordinate_position_test.mbt.md`.

### `Simplify`

Behavioural coverage in `simplify_test.mbt.md`.

### `Densify`

Behavioural coverage in `densify_test.mbt.md`.

### `MapCoords`

Behavioural coverage in `map_coords_test.mbt.md`.

## Direct trait-impl dispatch sweeps

Each trait has at least one impl per concrete geometry type. The behavioural tests above (and per-algorithm test files) typically call `Trait::method(geometry)` indirectly via the `Geometry` dispatch arm, which only exercises the `Trait for @type.Geometry` impl. The tests below ensure every per-type impl is also reachable through its direct trait call site.

### Direct `Bounded::bbox` impls

```mbt check
///|
test "Bounded - direct dispatch on every concrete type" {
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
  // Each direct call hits `Bounded for @type.<T>` rather than `Bounded for Geometry`.
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

### Direct `HasExtremes::extremes` impls

```mbt check
///|
test "HasExtremes - direct dispatch on every concrete type" {
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
  assert_true(HasExtremes::extremes(pt) is Some(_))
  assert_true(HasExtremes::extremes(l) is Some(_))
  assert_true(HasExtremes::extremes(ls) is Some(_))
  assert_true(HasExtremes::extremes(mp) is Some(_))
  assert_true(HasExtremes::extremes(mls) is Some(_))
  assert_true(HasExtremes::extremes(polygon) is Some(_))
  assert_true(HasExtremes::extremes(mpoly) is Some(_))
  assert_true(HasExtremes::extremes(r) is Some(_))
  assert_true(HasExtremes::extremes(tri) is Some(_))
  assert_true(HasExtremes::extremes(gc) is Some(_))
}
```

### Direct `LinesCarrier::lines` impls

```mbt check
///|
test "LinesCarrier - direct dispatch on every concrete type" {
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
  // Each call hits the per-type `LinesCarrier` impl directly.
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

### Direct `HasArea`, `HasCentroid`, `HasEuclideanLength` impls

```mbt check
///|
test "HasArea / HasCentroid / HasEuclideanLength - direct concrete-type dispatch" {
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
  let tri = @type.Triangle::Triangle(
    @type.Coord::Coord(0.0, 0.0),
    @type.Coord::Coord(4.0, 0.0),
    @type.Coord::Coord(0.0, 3.0),
  )
  // HasArea impls for every supported type.
  @test.assert_eq(HasArea::signed_area(polygon), 16.0)
  @test.assert_eq(HasArea::unsigned_area(polygon), 16.0)
  @test.assert_eq(HasArea::signed_area(mpoly), 16.0)
  @test.assert_eq(HasArea::unsigned_area(mpoly), 16.0)
  @test.assert_eq(HasArea::unsigned_area(tri), 6.0)
  // HasCentroid direct impls for every supported type.
  assert_true(HasCentroid::centroid(polygon) is Some(_))
  assert_true(HasCentroid::centroid(mpoly) is Some(_))
  assert_true(
    HasCentroid::centroid(
      @type.LineString::from_tuples([(0.0, 0.0), (1.0, 1.0)]),
    )
    is Some(_),
  )
  // HasEuclideanLength direct impls.
  let l = @type.Line::from_tuples((0.0, 0.0), (3.0, 4.0))
  let ls = @type.LineString::from_tuples([(0.0, 0.0), (3.0, 4.0)])
  let mls = @type.MultiLineString::MultiLineString([ls])
  @test.assert_eq(HasEuclideanLength::euclidean_length(l), 5.0)
  @test.assert_eq(HasEuclideanLength::euclidean_length(ls), 5.0)
  @test.assert_eq(HasEuclideanLength::euclidean_length(mls), 5.0)
}
```

### Direct `HasDimensions` impls

```mbt check
///|
test "HasDimensions - direct dispatch on every concrete type" {
  let r = @type.Rect::Rect(
    @type.Coord::Coord(0.0, 0.0),
    @type.Coord::Coord(1.0, 1.0),
  )
  let ls = @type.LineString::from_tuples([(0.0, 0.0), (1.0, 1.0)])
  @test.assert_eq(HasDimensions::dimensions(r), Dimensions::TwoDimensional)
  @test.assert_eq(HasDimensions::dimensions(ls), Dimensions::OneDimensional)
}
```

### Direct `HasConvexHull` impls

```mbt check
///|
test "HasConvexHull - direct dispatch on every concrete type" {
  let mp = @type.MultiPoint::from_tuples([(0.0, 0.0), (1.0, 0.0), (0.0, 1.0)])
  let ls = @type.LineString::from_tuples([
    (0.0, 0.0),
    (1.0, 0.0),
    (1.0, 1.0),
    (0.0, 1.0),
  ])
  let polygon = @type.Polygon::Polygon(ls, [])
  // Hull of n distinct points is closed, so length ≥ 3.
  assert_true(HasConvexHull::convex_hull(mp).exterior().length() >= 3)
  assert_true(HasConvexHull::convex_hull(ls).exterior().length() >= 3)
  assert_true(HasConvexHull::convex_hull(polygon).exterior().length() >= 3)
}
```

### Direct `ClosestPoint` impls

```mbt check
///|
test "ClosestPoint - direct dispatch on every concrete type" {
  let l = @type.Line::from_tuples((0.0, 0.0), (10.0, 0.0))
  let ls = @type.LineString::from_tuples([(0.0, 0.0), (10.0, 0.0)])
  let target = @type.Coord::Coord(5.0, 5.0)
  // Both impls return SinglePoint for an off-line target above the segment.
  assert_true(ClosestPoint::closest_point(l, target) is SinglePoint(_))
  assert_true(ClosestPoint::closest_point(ls, target) is SinglePoint(_))
}
```

### Direct `CoordPositionFor` impls

```mbt check
///|
test "CoordPositionFor - direct dispatch on every concrete type" {
  let l = @type.Line::from_tuples((0.0, 0.0), (10.0, 0.0))
  let ls = @type.LineString::from_tuples([(0.0, 0.0), (10.0, 0.0)])
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
    @type.Coord::Coord(4.0, 4.0),
  )
  let tri = @type.Triangle::Triangle(
    @type.Coord::Coord(0.0, 0.0),
    @type.Coord::Coord(4.0, 0.0),
    @type.Coord::Coord(0.0, 4.0),
  )
  let inside = @type.Coord::Coord(2.0, 1.0)
  @test.assert_eq(
    CoordPositionFor::coord_position(l, @type.Coord::Coord(5.0, 0.0)),
    CoordPos::Inside,
  )
  @test.assert_eq(
    CoordPositionFor::coord_position(ls, @type.Coord::Coord(5.0, 0.0)),
    CoordPos::Inside,
  )
  @test.assert_eq(
    CoordPositionFor::coord_position(polygon, inside),
    CoordPos::Inside,
  )
  @test.assert_eq(
    CoordPositionFor::coord_position(mpoly, inside),
    CoordPos::Inside,
  )
  @test.assert_eq(CoordPositionFor::coord_position(r, inside), CoordPos::Inside)
  @test.assert_eq(
    CoordPositionFor::coord_position(tri, @type.Coord::Coord(1.0, 1.0)),
    CoordPos::Inside,
  )
}
```

### Direct `Simplify` / `Densify` impls

```mbt check
///|
test "Simplify / Densify - direct dispatch on every concrete type" {
  let ls = @type.LineString::from_tuples([(0.0, 0.0), (5.0, 0.001), (10.0, 0.0)])
  let polygon = @type.Polygon::Polygon(
    @type.LineString::from_tuples([
      (0.0, 0.0),
      (5.0, 0.001),
      (10.0, 0.0),
      (10.0, 5.0),
      (0.0, 5.0),
    ]),
    [],
  )
  // Simplify: per-type impls drop nearly-collinear interior coords.
  @test.assert_eq(Simplify::simplify(ls, 0.01).coords().length(), 2)
  let _ = Simplify::simplify(polygon, 0.01)
  // Densify: per-type impls subdivide long segments.
  let densified_ls = Densify::densify(ls, 5.0)
  assert_true(densified_ls.coords().length() >= ls.coords().length())
  let _ = Densify::densify(polygon, 5.0)
}
```

### `Geometry` variant dispatch sweep — every match arm in every trait

```mbt check
///|
test "Geometry variant dispatch - LinesCarrier hits every match arm" {
  let pt = @type.Geometry::Point(@type.Point::Point(0.0, 0.0))
  let mp = @type.Geometry::MultiPoint(
    @type.MultiPoint::from_tuples([(0.0, 0.0), (1.0, 1.0)]),
  )
  let mls = @type.Geometry::MultiLineString(
    @type.MultiLineString::MultiLineString([
      @type.LineString::from_tuples([(0.0, 0.0), (1.0, 1.0)]),
    ]),
  )
  // Point / MultiPoint variants return empty.
  @test.assert_eq(LinesCarrier::lines(pt), [])
  @test.assert_eq(LinesCarrier::lines(mp), [])
  // MultiLineString variant flattens segments across components.
  @test.assert_eq(LinesCarrier::lines(mls).length(), 1)
}
```

```mbt check
///|
test "Geometry variant dispatch - HasDimensions hits every match arm" {
  // Line variant — degenerate (start==end) collapses to ZeroDimensional.
  let degenerate = @type.Geometry::Line(
    @type.Line::from_tuples((1.0, 1.0), (1.0, 1.0)),
  )
  @test.assert_eq(
    HasDimensions::dimensions(degenerate),
    Dimensions::ZeroDimensional,
  )
  // Line variant — non-degenerate is OneDimensional.
  let segment = @type.Geometry::Line(
    @type.Line::from_tuples((0.0, 0.0), (1.0, 1.0)),
  )
  @test.assert_eq(
    HasDimensions::dimensions(segment),
    Dimensions::OneDimensional,
  )
  // Polygon variant — exterior dimension drives the result.
  let polygon = @type.Geometry::Polygon(
    @type.Polygon::Polygon(
      @type.LineString::from_tuples([
        (0.0, 0.0),
        (4.0, 0.0),
        (4.0, 4.0),
        (0.0, 4.0),
      ]),
      [],
    ),
  )
  @test.assert_eq(
    HasDimensions::dimensions(polygon),
    Dimensions::TwoDimensional,
  )
  // MultiPoint with content is ZeroDimensional.
  let mp = @type.Geometry::MultiPoint(
    @type.MultiPoint::from_tuples([(0.0, 0.0)]),
  )
  @test.assert_eq(HasDimensions::dimensions(mp), Dimensions::ZeroDimensional)
  // MultiLineString aggregates as OneDimensional.
  let mls = @type.Geometry::MultiLineString(
    @type.MultiLineString::MultiLineString([
      @type.LineString::from_tuples([(0.0, 0.0), (1.0, 1.0)]),
    ]),
  )
  @test.assert_eq(HasDimensions::dimensions(mls), Dimensions::OneDimensional)
  // MultiPolygon aggregates as TwoDimensional.
  let mpoly = @type.Geometry::MultiPolygon(
    @type.MultiPolygon::MultiPolygon([
      @type.Polygon::Polygon(
        @type.LineString::from_tuples([
          (0.0, 0.0),
          (4.0, 0.0),
          (4.0, 4.0),
          (0.0, 4.0),
        ]),
        [],
      ),
    ]),
  )
  @test.assert_eq(HasDimensions::dimensions(mpoly), Dimensions::TwoDimensional)
  // Triangle is TwoDimensional.
  let tri = @type.Geometry::Triangle(
    @type.Triangle::Triangle(
      @type.Coord::Coord(0.0, 0.0),
      @type.Coord::Coord(1.0, 0.0),
      @type.Coord::Coord(0.0, 1.0),
    ),
  )
  @test.assert_eq(HasDimensions::dimensions(tri), Dimensions::TwoDimensional)
  // GeometryCollection takes the max dimension of its components.
  let gc = @type.Geometry::GeometryCollection(
    @type.GeometryCollection::GeometryCollection([
      @type.Geometry::Point(@type.Point::Point(0.0, 0.0)),
      @type.Geometry::LineString(
        @type.LineString::from_tuples([(0.0, 0.0), (1.0, 1.0)]),
      ),
    ]),
  )
  @test.assert_eq(HasDimensions::dimensions(gc), Dimensions::OneDimensional)
}
```

```mbt check
///|
test "HasDimensions on LineString - empty and zero-dimensional inputs" {
  // Empty LineString — `Empty` dimension.
  @test.assert_eq(
    HasDimensions::dimensions(@type.LineString::empty()),
    Dimensions::Empty,
  )
  // All-coords-equal LineString collapses to ZeroDimensional.
  let coincident = @type.LineString::from_tuples([(1.0, 2.0), (1.0, 2.0)])
  @test.assert_eq(
    HasDimensions::dimensions(coincident),
    Dimensions::ZeroDimensional,
  )
}
```

```mbt check
///|
test "ClosestPoint on Line - degenerate (start==end)" {
  let degenerate = @type.Line::from_tuples((3.0, 4.0), (3.0, 4.0))
  // target on the point → Intersection.
  @test.assert_eq(
    ClosestPoint::closest_point(degenerate, @type.Coord::Coord(3.0, 4.0)),
    Closest::Intersection(@type.Coord::Coord(3.0, 4.0)),
  )
  // target off the point → SinglePoint at the start.
  @test.assert_eq(
    ClosestPoint::closest_point(degenerate, @type.Coord::Coord(10.0, 10.0)),
    Closest::SinglePoint(@type.Coord::Coord(3.0, 4.0)),
  )
}
```

```mbt check
///|
test "ClosestPoint on LineString - empty and multi-segment cases" {
  // Empty LineString → Indeterminate.
  @test.assert_eq(
    ClosestPoint::closest_point(
      @type.LineString::empty(),
      @type.Coord::Coord(0.0, 0.0),
    ),
    Closest::Indeterminate,
  )
  // Multi-segment LineString — picks the closer segment to the target,
  // exercising the SinglePoint vs SinglePoint comparison branch.
  let ls = @type.LineString::from_tuples([(0.0, 0.0), (10.0, 0.0), (10.0, 10.0)])
  // (5, -1) is closer to the first segment than the second.
  let result = ClosestPoint::closest_point(ls, @type.Coord::Coord(5.0, -1.0))
  match result {
    Closest::SinglePoint(c) => @test.assert_eq(c, @type.Coord::Coord(5.0, 0.0))
    _ => abort("expected SinglePoint for off-line target")
  }
  // Target on the line yields Intersection.
  @test.assert_eq(
    ClosestPoint::closest_point(ls, @type.Coord::Coord(5.0, 0.0)),
    Closest::Intersection(@type.Coord::Coord(5.0, 0.0)),
  )
}
```

### Direct `MapCoords` impls

```mbt check
///|
test "MapCoords - direct dispatch on every concrete type" {
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
  // Identity maps each value to itself across every per-type impl.
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

### Direct `ExteriorCoordsCarrier` impls

```mbt check
///|
test "ExteriorCoordsCarrier - direct dispatch on every concrete type" {
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
  // Polygon: 5 coords (auto-closed exterior).
  @test.assert_eq(ExteriorCoordsCarrier::exterior_coords(polygon).length(), 5)
  // MultiPolygon: 5 coords across one polygon.
  @test.assert_eq(ExteriorCoordsCarrier::exterior_coords(mpoly).length(), 5)
  // Geometry::Polygon dispatch falls through to the polygon impl.
  @test.assert_eq(
    ExteriorCoordsCarrier::exterior_coords(@type.Geometry::Polygon(polygon)).length(),
    5,
  )
}
```
