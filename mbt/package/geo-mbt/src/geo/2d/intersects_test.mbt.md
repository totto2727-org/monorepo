# intersects.mbt

Boundary-inclusive intersection predicates: `intersects(a, b)` is true if `a` and `b` share at least one point (interior or boundary). Per-pair entry points cover the common cases; `intersects_geometry` dispatches over the `Geometry` enum, falling back to a bounding-rect approximation for uncommon pairs.

## Public API

- `intersects_coord_coord`
- `intersects_coord_line`
- `intersects_line_line`
- `intersects_coord_line_string`
- `intersects_line_line_string`
- `intersects_line_string_line_string`
- `intersects_coord_polygon`
- `intersects_line_polygon`
- `intersects_polygon_polygon`
- `intersects_rect_coord`
- `intersects_geometry`

## Test

### `intersects_line_line`

| Variable    | State                          | Note                       |  1  |  2  |  3  |  4  |
| :---------- | :----------------------------- | :------------------------- | :-: | :-: | :-: | :-: |
| `a`/`b`     | `Touching endpoints`           | true                       |  ✓  |     |     |     |
| `a`/`b`     | `Classic crossing`             | true                       |     |  ✓  |     |     |
| `a`/`b`     | `Parallel non-overlapping`     | false                      |     |     |  ✓  |     |
| `a`/`b`     | `Collinear overlapping`        | true                       |     |     |     |  ✓  |

- Touching endpoints

```mbt check
///|
test "intersects_line_line - touching endpoints" {
  let a = @type.Line::from_tuples((0.0, 0.0), (1.0, 0.0))
  let b = @type.Line::from_tuples((1.0, 0.0), (1.0, 1.0))
  assert_true(intersects_line_line(a, b))
}
```

- Classic crossing

```mbt check
///|
test "intersects_line_line - classic crossing" {
  let a = @type.Line::from_tuples((0.0, 0.0), (10.0, 10.0))
  let b = @type.Line::from_tuples((0.0, 10.0), (10.0, 0.0))
  assert_true(intersects_line_line(a, b))
}
```

- Parallel non-overlapping

```mbt check
///|
test "intersects_line_line - parallel non-overlapping false" {
  let a = @type.Line::from_tuples((0.0, 0.0), (10.0, 0.0))
  let b = @type.Line::from_tuples((0.0, 1.0), (10.0, 1.0))
  assert_false(intersects_line_line(a, b))
}
```

- Collinear overlapping

```mbt check
///|
test "intersects_line_line - collinear overlapping" {
  let a = @type.Line::from_tuples((0.0, 0.0), (10.0, 0.0))
  let b = @type.Line::from_tuples((5.0, 0.0), (15.0, 0.0))
  assert_true(intersects_line_line(a, b))
}
```

### `intersects_polygon_polygon`

| Variable    | State        | Note    |  1  |  2  |
| :---------- | :----------- | :------ | :-: | :-: |
| `a`/`b`     | `Overlap`    | true    |  ✓  |     |
| `a`/`b`     | `Disjoint`   | false   |     |  ✓  |

- Overlap

```mbt check
///|
test "intersects_polygon_polygon - overlap" {
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
  assert_true(intersects_polygon_polygon(a, b))
}
```

- Disjoint

```mbt check
///|
test "intersects_polygon_polygon - disjoint" {
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
  assert_false(intersects_polygon_polygon(a, b))
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
test "intersects_coord_coord / intersects_coord_line" {
  let a = @type.Coord::Coord(1.0, 2.0)
  let b = @type.Coord::Coord(1.0, 2.0)
  let c = @type.Coord::Coord(3.0, 4.0)
  assert_true(intersects_coord_coord(a, b))
  assert_false(intersects_coord_coord(a, c))
  let l = @type.Line::from_tuples((0.0, 0.0), (10.0, 0.0))
  assert_true(intersects_coord_line(@type.Coord::Coord(5.0, 0.0), l))
  assert_false(intersects_coord_line(@type.Coord::Coord(5.0, 1.0), l))
}
```

```mbt check
///|
test "intersects_coord_line_string / intersects_line_line_string" {
  let ls = @type.LineString::from_tuples([(0.0, 0.0), (10.0, 0.0)])
  assert_true(intersects_coord_line_string(@type.Coord::Coord(5.0, 0.0), ls))
  assert_false(intersects_coord_line_string(@type.Coord::Coord(5.0, 1.0), ls))
  let l = @type.Line::from_tuples((5.0, -1.0), (5.0, 1.0))
  assert_true(intersects_line_line_string(l, ls))
}
```

```mbt check
///|
test "intersects_coord_polygon / intersects_line_polygon / intersects_rect_coord" {
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
  assert_true(intersects_coord_polygon(@type.Coord::Coord(1.0, 1.0), polygon))
  assert_false(
    intersects_coord_polygon(@type.Coord::Coord(10.0, 10.0), polygon),
  )
  // Line crossing the polygon's interior intersects.
  let crossing = @type.Line::from_tuples((-1.0, 1.0), (3.0, 1.0))
  assert_true(intersects_line_polygon(crossing, polygon))
  // Line entirely outside has no intersection.
  let outside = @type.Line::from_tuples((10.0, 10.0), (20.0, 20.0))
  assert_false(intersects_line_polygon(outside, polygon))
  // Rect × Coord direct call.
  let r = @type.Rect::Rect(
    @type.Coord::Coord(0.0, 0.0),
    @type.Coord::Coord(10.0, 10.0),
  )
  assert_true(intersects_rect_coord(r, @type.Coord::Coord(5.0, 5.0)))
  assert_false(intersects_rect_coord(r, @type.Coord::Coord(20.0, 20.0)))
}
```
