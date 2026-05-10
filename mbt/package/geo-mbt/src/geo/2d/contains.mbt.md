# contains.mbt

Strict (OGC) `contains` predicates: every point of the inner geometry must lie in the **interior** of the outer geometry — boundary points are excluded. `within(a, b) ≡ contains(b, a)` is the symmetric inverse.

## Public API

- `contains_polygon_coord`
- `contains_polygon_point`
- `contains_polygon_line`
- `contains_polygon_line_string`
- `contains_polygon_polygon`
- `contains_multi_polygon_coord`
- `contains_rect_coord`
- `contains_rect_rect`
- `contains_geometry`
- `within_geometry`

## Test

### `contains_polygon_point`

| Variable | State             | Note                      |  1  |  2  |  3  |
| :------- | :---------------- | :------------------------ | :-: | :-: | :-: |
| `point`  | `Strictly inside` | true                      |  ✓  |     |     |
| `point`  | `On boundary`     | false (boundary excluded) |     |  ✓  |     |
| `point`  | `Outside`         | false                     |     |     |  ✓  |

- Inside, boundary, outside

```mbt check
///|
test "contains_polygon_point - inside, boundary excluded, outside" {
  let exterior = @type.LineString::from_tuples([
    (0.0, 0.0),
    (10.0, 0.0),
    (10.0, 10.0),
    (0.0, 10.0),
    (0.0, 0.0),
  ])
  let p = @type.Polygon::Polygon(exterior, [])
  assert_true(contains_polygon_point(p, @type.Point::Point(5.0, 5.0))) // inside
  assert_false(contains_polygon_point(p, @type.Point::Point(0.0, 5.0))) // boundary
  assert_false(contains_polygon_point(p, @type.Point::Point(20.0, 20.0))) // outside
}
```

### `contains_polygon_polygon`

| Variable           | State      | Note  |  1  |  2  |
| :----------------- | :--------- | :---- | :-: | :-: |
| `inner` vs `outer` | `Nested`   | true  |  ✓  |     |
| `inner` vs `outer` | `Crossing` | false |     |  ✓  |

- Nested polygon is contained

```mbt check
///|
test "contains_polygon_polygon - nested inner is contained" {
  let outer = @type.Polygon::Polygon(
    @type.LineString::from_tuples([
      (0.0, 0.0),
      (10.0, 0.0),
      (10.0, 10.0),
      (0.0, 10.0),
      (0.0, 0.0),
    ]),
    [],
  )
  let inner = @type.Polygon::Polygon(
    @type.LineString::from_tuples([
      (2.0, 2.0),
      (4.0, 2.0),
      (4.0, 4.0),
      (2.0, 4.0),
      (2.0, 2.0),
    ]),
    [],
  )
  assert_true(contains_polygon_polygon(outer, inner))
}
```

- Crossing polygon is not contained

```mbt check
///|
test "contains_polygon_polygon - crossing inner is not contained" {
  let outer = @type.Polygon::Polygon(
    @type.LineString::from_tuples([
      (0.0, 0.0),
      (10.0, 0.0),
      (10.0, 10.0),
      (0.0, 10.0),
      (0.0, 0.0),
    ]),
    [],
  )
  let crossing = @type.Polygon::Polygon(
    @type.LineString::from_tuples([
      (5.0, 5.0),
      (15.0, 5.0),
      (15.0, 15.0),
      (5.0, 15.0),
      (5.0, 5.0),
    ]),
    [],
  )
  assert_false(contains_polygon_polygon(outer, crossing))
}
```

### `contains_rect_rect`

| Variable           | State      | Note  |  1  |  2  |
| :----------------- | :--------- | :---- | :-: | :-: |
| `inner` vs `outer` | `Nested`   | true  |  ✓  |     |
| `inner` vs `outer` | `Crossing` | false |     |  ✓  |

- Nested then crossing rectangles

```mbt check
///|
test "contains_rect_rect - nested true, crossing false" {
  let outer = @type.Rect::Rect(
    @type.Coord::Coord(0.0, 0.0),
    @type.Coord::Coord(10.0, 10.0),
  )
  let inner = @type.Rect::Rect(
    @type.Coord::Coord(2.0, 2.0),
    @type.Coord::Coord(8.0, 8.0),
  )
  let crossing = @type.Rect::Rect(
    @type.Coord::Coord(5.0, 5.0),
    @type.Coord::Coord(15.0, 15.0),
  )
  assert_true(contains_rect_rect(outer, inner))
  assert_false(contains_rect_rect(outer, crossing))
}
```

### `within_geometry`

- `within(a, b)` is the symmetric inverse of `contains(b, a)`

```mbt check
///|
test "within_geometry - is the inverse of contains_geometry" {
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
  let pt = @type.Point::Point(5.0, 5.0)
  let g_polygon = @type.Geometry::Polygon(polygon)
  let g_pt = @type.Geometry::Point(pt)
  assert_true(within_geometry(g_pt, g_polygon))
  assert_false(within_geometry(g_polygon, g_pt))
}
```

### `contains_polygon_line` / `contains_polygon_line_string`

- Strictly contained line and the linestring whose every coord is inside

```mbt check
///|
test "contains_polygon_line / contains_polygon_line_string - strict containment" {
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
  let inside_line = @type.Line::from_tuples((1.0, 1.0), (5.0, 5.0))
  assert_true(contains_polygon_line(polygon, inside_line))
  let crossing_line = @type.Line::from_tuples((1.0, 1.0), (20.0, 20.0))
  assert_false(contains_polygon_line(polygon, crossing_line))
  let inside_ls = @type.LineString::from_tuples([
    (1.0, 1.0),
    (5.0, 5.0),
    (8.0, 2.0),
  ])
  assert_true(contains_polygon_line_string(polygon, inside_ls))
  let mixed_ls = @type.LineString::from_tuples([(1.0, 1.0), (20.0, 20.0)])
  assert_false(contains_polygon_line_string(polygon, mixed_ls))
}
```

### `contains_multi_polygon_coord` / `contains_rect_coord`

- Multi polygon containment by any component; rect containment is strict

```mbt check
///|
test "contains_multi_polygon_coord / contains_rect_coord" {
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
  let mp = @type.MultiPolygon::MultiPolygon([polygon])
  assert_true(contains_multi_polygon_coord(mp, @type.Coord::Coord(5.0, 5.0)))
  assert_false(contains_multi_polygon_coord(mp, @type.Coord::Coord(20.0, 20.0)))
  let r = @type.Rect::Rect(
    @type.Coord::Coord(0.0, 0.0),
    @type.Coord::Coord(10.0, 10.0),
  )
  assert_true(contains_rect_coord(r, @type.Coord::Coord(5.0, 5.0)))
  assert_false(contains_rect_coord(r, @type.Coord::Coord(0.0, 5.0)))
}
```

### `contains_geometry` dispatch sweep

```mbt check
///|
test "contains_geometry - dispatch sweep over every supported pair" {
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
  let g_poly = @type.Geometry::Polygon(polygon)
  let g_line = @type.Geometry::Line(
    @type.Line::from_tuples((1.0, 1.0), (5.0, 5.0)),
  )
  assert_true(contains_geometry(g_poly, g_line))
  let g_ls = @type.Geometry::LineString(
    @type.LineString::from_tuples([(1.0, 1.0), (5.0, 5.0)]),
  )
  assert_true(contains_geometry(g_poly, g_ls))
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
  assert_true(contains_geometry(g_poly, @type.Geometry::Polygon(inner)))
  let r = @type.Rect::Rect(
    @type.Coord::Coord(0.0, 0.0),
    @type.Coord::Coord(10.0, 10.0),
  )
  assert_true(
    contains_geometry(
      @type.Geometry::Rect(r),
      @type.Geometry::Point(@type.Point::Point(5.0, 5.0)),
    ),
  )
  let inner_r = @type.Rect::Rect(
    @type.Coord::Coord(2.0, 2.0),
    @type.Coord::Coord(8.0, 8.0),
  )
  assert_true(
    contains_geometry(@type.Geometry::Rect(r), @type.Geometry::Rect(inner_r)),
  )
  let mp = @type.MultiPolygon::MultiPolygon([polygon])
  assert_true(
    contains_geometry(
      @type.Geometry::MultiPolygon(mp),
      @type.Geometry::Point(@type.Point::Point(5.0, 5.0)),
    ),
  )
  let g_pt = @type.Geometry::Point(@type.Point::Point(0.0, 0.0))
  assert_true(contains_geometry(g_pt, g_pt))
  assert_false(
    contains_geometry(g_pt, @type.Geometry::Point(@type.Point::Point(1.0, 1.0))),
  )
}
```
