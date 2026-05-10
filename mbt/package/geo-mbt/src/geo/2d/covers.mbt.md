# covers.mbt

Boundary-inclusive containment. `covers(a, b)` is `true` whenever every point of `b` lies in `a`'s interior **or** on its boundary — unlike `contains_*` which is strict (boundary excluded for points).

## Public API

- `covers_polygon_coord`
- `covers_polygon_point`
- `covers_polygon_line_string`
- `covers_polygon_polygon`
- `covers_rect_coord`
- `covers_geometry`

## Test

### `covers_polygon_point`

| Variable | State             | Note                     |  1  |  2  |  3  |
| :------- | :---------------- | :----------------------- | :-: | :-: | :-: |
| `point`  | `On boundary`     | true (boundary included) |  ✓  |     |     |
| `point`  | `Strictly inside` | true                     |     |  ✓  |     |
| `point`  | `Outside`         | false                    |     |     |  ✓  |

- Boundary, interior, and outside points

```mbt check
///|
test "covers_polygon_point - boundary included, outside rejected" {
  let exterior = @type.LineString::from_tuples([
    (0.0, 0.0),
    (10.0, 0.0),
    (10.0, 10.0),
    (0.0, 10.0),
    (0.0, 0.0),
  ])
  let p = @type.Polygon::Polygon(exterior, [])
  assert_true(covers_polygon_point(p, @type.Point::Point(0.0, 5.0))) // boundary
  assert_true(covers_polygon_point(p, @type.Point::Point(5.0, 5.0))) // interior
  assert_false(covers_polygon_point(p, @type.Point::Point(20.0, 20.0))) // outside
}
```

### `covers_polygon_coord` / `covers_polygon_line_string` / `covers_polygon_polygon`

- Coord, LineString, and Polygon coverage by a polygon

```mbt check
///|
test "covers_polygon_coord / line_string / polygon - boundary inclusive" {
  let polygon = @type.Polygon::Polygon(
    @type.LineString::from_tuples([
      (0.0, 0.0),
      (10.0, 0.0),
      (10.0, 10.0),
      (0.0, 10.0),
      (0.0, 0.0),
    ]),
    [],
  )
  // Coord on boundary → covered.
  assert_true(covers_polygon_coord(polygon, @type.Coord::Coord(0.0, 5.0)))
  assert_false(covers_polygon_coord(polygon, @type.Coord::Coord(20.0, 20.0)))
  // LineString every coord covered.
  let ls = @type.LineString::from_tuples([(1.0, 1.0), (5.0, 5.0)])
  assert_true(covers_polygon_line_string(polygon, ls))
  let crossing = @type.LineString::from_tuples([(1.0, 1.0), (20.0, 20.0)])
  assert_false(covers_polygon_line_string(polygon, crossing))
  // Inner polygon's exterior coords all covered.
  let inner = @type.Polygon::Polygon(
    @type.LineString::from_tuples([
      (2.0, 2.0),
      (3.0, 2.0),
      (3.0, 3.0),
      (2.0, 3.0),
      (2.0, 2.0),
    ]),
    [],
  )
  assert_true(covers_polygon_polygon(polygon, inner))
}
```

### `covers_rect_coord`

```mbt check
///|
test "covers_rect_coord - boundary inclusive" {
  let r = @type.Rect::Rect(
    @type.Coord::Coord(0.0, 0.0),
    @type.Coord::Coord(10.0, 10.0),
  )
  // Boundary is covered (unlike strict contains_rect_coord).
  assert_true(covers_rect_coord(r, @type.Coord::Coord(0.0, 5.0)))
  assert_true(covers_rect_coord(r, @type.Coord::Coord(5.0, 5.0)))
  assert_false(covers_rect_coord(r, @type.Coord::Coord(20.0, 20.0)))
}
```

### `covers_geometry`

- Boundary point: `contains_geometry` returns `false`, `covers_geometry` returns `true`

```mbt check
///|
test "covers_geometry - boundary point: covers true, contains false" {
  let exterior = @type.LineString::from_tuples([
    (0.0, 0.0),
    (10.0, 0.0),
    (10.0, 10.0),
    (0.0, 10.0),
    (0.0, 0.0),
  ])
  let p = @type.Geometry::Polygon(@type.Polygon::Polygon(exterior, []))
  let boundary_pt = @type.Geometry::Point(@type.Point::Point(0.0, 5.0))
  assert_false(contains_geometry(p, boundary_pt))
  assert_true(covers_geometry(p, boundary_pt))
}
```
