# intersects.mbt

Boundary-inclusive intersection predicates: `intersects(a, b)` is true if `a` and `b` share at least one point (interior or boundary). The public surface is the `Intersects` trait plus `intersects_geometry`; per-pair helpers are implementation details.

## Public API

- `Intersects` trait
- `intersects_geometry`

## Test

### `intersects_line_line`

| Variable | State                      | Note  |  1  |  2  |  3  |  4  |
| :------- | :------------------------- | :---- | :-: | :-: | :-: | :-: |
| `a`/`b`  | `Touching endpoints`       | true  |  ✓  |     |     |     |
| `a`/`b`  | `Classic crossing`         | true  |     |  ✓  |     |     |
| `a`/`b`  | `Parallel non-overlapping` | false |     |     |  ✓  |     |
| `a`/`b`  | `Collinear overlapping`    | true  |     |     |     |  ✓  |

- Touching endpoints

```mbt check
///|
test "intersects_geometry - touching line endpoints" {
  let a = @type.Line::from_tuples((0.0, 0.0), (1.0, 0.0))
  let b = @type.Line::from_tuples((1.0, 0.0), (1.0, 1.0))
  assert_true(intersects_geometry(@type.Geometry::Line(a), @type.Geometry::Line(b)))
}
```

- Classic crossing

```mbt check
///|
test "intersects_geometry - classic crossing lines" {
  let a = @type.Line::from_tuples((0.0, 0.0), (10.0, 10.0))
  let b = @type.Line::from_tuples((0.0, 10.0), (10.0, 0.0))
  assert_true(intersects_geometry(@type.Geometry::Line(a), @type.Geometry::Line(b)))
}
```

- Parallel non-overlapping

```mbt check
///|
test "intersects_geometry - parallel non-overlapping lines false" {
  let a = @type.Line::from_tuples((0.0, 0.0), (10.0, 0.0))
  let b = @type.Line::from_tuples((0.0, 1.0), (10.0, 1.0))
  assert_false(intersects_geometry(@type.Geometry::Line(a), @type.Geometry::Line(b)))
}
```

- Collinear overlapping

```mbt check
///|
test "intersects_geometry - collinear overlapping lines" {
  let a = @type.Line::from_tuples((0.0, 0.0), (10.0, 0.0))
  let b = @type.Line::from_tuples((5.0, 0.0), (15.0, 0.0))
  assert_true(intersects_geometry(@type.Geometry::Line(a), @type.Geometry::Line(b)))
}
```

### `intersects_polygon_polygon`

| Variable | State      | Note  |  1  |  2  |
| :------- | :--------- | :---- | :-: | :-: |
| `a`/`b`  | `Overlap`  | true  |  ✓  |     |
| `a`/`b`  | `Disjoint` | false |     |  ✓  |

- Overlap

```mbt check
///|
test "intersects_geometry - polygon overlap" {
  let a = @type.Polygon::Polygon(
    @type.LineString::from_tuples([
      (0.0, 0.0),
      (2.0, 0.0),
      (2.0, 2.0),
      (0.0, 2.0),
      (0.0, 0.0),
    ]),
    [],
  )
  let b = @type.Polygon::Polygon(
    @type.LineString::from_tuples([
      (1.0, 1.0),
      (3.0, 1.0),
      (3.0, 3.0),
      (1.0, 3.0),
    ]),
    [],
  )
  assert_true(intersects_geometry(@type.Geometry::Polygon(a), @type.Geometry::Polygon(b)))
}
```

- Disjoint

```mbt check
///|
test "intersects_geometry - polygon disjoint" {
  let a = @type.Polygon::Polygon(
    @type.LineString::from_tuples([
      (0.0, 0.0),
      (2.0, 0.0),
      (2.0, 2.0),
      (0.0, 2.0),
      (0.0, 0.0),
    ]),
    [],
  )
  let b = @type.Polygon::Polygon(
    @type.LineString::from_tuples([
      (10.0, 10.0),
      (12.0, 10.0),
      (12.0, 12.0),
      (10.0, 12.0),
    ]),
    [],
  )
  assert_false(intersects_geometry(@type.Geometry::Polygon(a), @type.Geometry::Polygon(b)))
}
```

### `intersects_geometry`

- Dispatches `Point` × `Polygon` to `intersects_coord_polygon`

```mbt check
///|
test "intersects_geometry - Point inside Polygon dispatches correctly" {
  let p = @type.Geometry::Point(@type.Point::Point(1.0, 1.0))
  let poly = @type.Geometry::Polygon(
    @type.Polygon::Polygon(
      @type.LineString::from_tuples([
        (0.0, 0.0),
        (2.0, 0.0),
        (2.0, 2.0),
        (0.0, 2.0),
        (0.0, 0.0),
      ]),
      [],
    ),
  )
  assert_true(intersects_geometry(p, poly))
}
```

- Dispatch sweep: each common pair routes to its per-type predicate

```mbt check
///|
test "intersects_geometry - dispatch sweep over common pairs" {
  let pt0 = @type.Point::Point(0.0, 0.0)
  let pt1 = @type.Point::Point(1.0, 1.0)
  let l = @type.Line::from_tuples((0.0, 0.0), (10.0, 0.0))
  let ls = @type.LineString::from_tuples([(0.0, 0.0), (10.0, 0.0)])
  let poly = @type.Polygon::Polygon(
    @type.LineString::from_tuples([
      (0.0, 0.0),
      (2.0, 0.0),
      (2.0, 2.0),
      (0.0, 2.0),
      (0.0, 0.0),
    ]),
    [],
  )
  let g_pt = @type.Geometry::Point(pt0)
  let g_pt_eq = @type.Geometry::Point(pt0)
  let g_pt_diff = @type.Geometry::Point(pt1)
  let g_line = @type.Geometry::Line(l)
  let g_ls = @type.Geometry::LineString(ls)
  let g_poly = @type.Geometry::Polygon(poly)
  // Point × Point
  assert_true(intersects_geometry(g_pt, g_pt_eq))
  assert_false(intersects_geometry(g_pt, g_pt_diff))
  // Point × Line and reverse
  assert_true(intersects_geometry(g_pt, g_line))
  assert_true(intersects_geometry(g_line, g_pt))
  // Point × LineString and reverse
  assert_true(intersects_geometry(g_pt, g_ls))
  assert_true(intersects_geometry(g_ls, g_pt))
  // Polygon × Point reverse
  assert_true(intersects_geometry(g_poly, g_pt))
  // Line × Line
  let g_line_b = @type.Geometry::Line(
    @type.Line::from_tuples((5.0, -1.0), (5.0, 1.0)),
  )
  assert_true(intersects_geometry(g_line, g_line_b))
  // Line × LineString and reverse
  assert_true(intersects_geometry(g_line, g_ls))
  assert_true(intersects_geometry(g_ls, g_line))
  // LineString × LineString
  assert_true(intersects_geometry(g_ls, g_ls))
  // Line × Polygon and reverse
  assert_true(intersects_geometry(g_line, g_poly))
  assert_true(intersects_geometry(g_poly, g_line))
  // GeometryCollection vs anything routes through `any` over its components.
  let gc = @type.Geometry::GeometryCollection(
    @type.GeometryCollection::GeometryCollection([g_pt]),
  )
  assert_true(intersects_geometry(gc, g_pt))
  assert_true(intersects_geometry(g_pt, gc))
  // Fallback bbox-approximation path: pair without a specialised arm.
  let g_mp = @type.Geometry::MultiPoint(
    @type.MultiPoint::from_tuples([(0.0, 0.0)]),
  )
  let g_mls = @type.Geometry::MultiLineString(
    @type.MultiLineString::MultiLineString([ls]),
  )
  // Both bboxes are at origin → bbox-overlap = true.
  assert_true(intersects_geometry(g_mp, g_mls))
  // Disjoint MultiPoints fall through to the bbox path and return false.
  let g_far = @type.Geometry::MultiPoint(
    @type.MultiPoint::from_tuples([(100.0, 100.0)]),
  )
  assert_false(intersects_geometry(g_mp, g_far))
}
```

### `intersects_coord_*` / `intersects_rect_coord` direct calls

```mbt check
///|
test "intersects_geometry - point point and point line" {
  let a = @type.Coord::Coord(1.0, 2.0)
  let b = @type.Coord::Coord(1.0, 2.0)
  let c = @type.Coord::Coord(3.0, 4.0)
  assert_true(intersects_geometry(@type.Geometry::Point(@type.Point::from_coord(a)), @type.Geometry::Point(@type.Point::from_coord(b))))
  assert_false(intersects_geometry(@type.Geometry::Point(@type.Point::from_coord(a)), @type.Geometry::Point(@type.Point::from_coord(c))))
  let l = @type.Line::from_tuples((0.0, 0.0), (10.0, 0.0))
  assert_true(intersects_geometry(@type.Geometry::Point(@type.Point::Point(5.0, 0.0)), @type.Geometry::Line(l)))
  assert_false(intersects_geometry(@type.Geometry::Point(@type.Point::Point(5.0, 1.0)), @type.Geometry::Line(l)))
}
```

```mbt check
///|
test "intersects_geometry - point linestring and line linestring" {
  let ls = @type.LineString::from_tuples([(0.0, 0.0), (10.0, 0.0)])
  assert_true(intersects_geometry(@type.Geometry::Point(@type.Point::Point(5.0, 0.0)), @type.Geometry::LineString(ls)))
  assert_false(intersects_geometry(@type.Geometry::Point(@type.Point::Point(5.0, 1.0)), @type.Geometry::LineString(ls)))
  let l = @type.Line::from_tuples((5.0, -1.0), (5.0, 1.0))
  assert_true(intersects_geometry(@type.Geometry::Line(l), @type.Geometry::LineString(ls)))
}
```

```mbt check
///|
test "intersects_geometry - point/line polygon and rect point" {
  let polygon = @type.Polygon::Polygon(
    @type.LineString::from_tuples([
      (0.0, 0.0),
      (2.0, 0.0),
      (2.0, 2.0),
      (0.0, 2.0),
      (0.0, 0.0),
    ]),
    [],
  )
  let g_polygon = @type.Geometry::Polygon(polygon)
  assert_true(intersects_geometry(@type.Geometry::Point(@type.Point::Point(1.0, 1.0)), g_polygon))
  assert_false(
    intersects_geometry(@type.Geometry::Point(@type.Point::Point(10.0, 10.0)), g_polygon),
  )
  // Line crossing the polygon's interior intersects.
  let crossing = @type.Line::from_tuples((-1.0, 1.0), (3.0, 1.0))
  assert_true(intersects_geometry(@type.Geometry::Line(crossing), g_polygon))
  // Line entirely outside has no intersection.
  let outside = @type.Line::from_tuples((10.0, 10.0), (20.0, 20.0))
  assert_false(intersects_geometry(@type.Geometry::Line(outside), g_polygon))
  // Rect × Coord direct call.
  let r = @type.Rect::Rect(
    @type.Coord::Coord(0.0, 0.0),
    @type.Coord::Coord(10.0, 10.0),
  )
  assert_true(intersects_geometry(@type.Geometry::Rect(r), @type.Geometry::Point(@type.Point::Point(5.0, 5.0))))
  assert_false(intersects_geometry(@type.Geometry::Rect(r), @type.Geometry::Point(@type.Point::Point(20.0, 20.0))))
}
```
