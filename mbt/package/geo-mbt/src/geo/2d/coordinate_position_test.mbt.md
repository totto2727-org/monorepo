# coordinate_position.mbt

Classifies a `Coord` relative to a geometry as `CoordPos` — `Inside`, `OnBoundary`, or `Outside`. Exposed via the `CoordPositionFor::coord_position` trait whose impls live in `traits.mbt`. Also exposes the public free predicate `coord_on_line`.

## Public API

- `CoordPos`
- `coord_on_line`
- `CoordPositionFor` — `coord_position` (impls in traits.mbt for `Polygon` / `Rect` / etc.)

## Test

### `coord_on_line`

| Variable | State                  | Note     |  1  |  2  |  3  |  4  |  5  |
| :------- | :--------------------- | :------- | :-: | :-: | :-: | :-: | :-: |
| `coord`  | `Start endpoint`       | true     |  ✓  |     |     |     |     |
| `coord`  | `End endpoint`         | true     |     |  ✓  |     |     |     |
| `coord`  | `Strict midpoint`      | true     |     |     |  ✓  |     |     |
| `coord`  | `Off the line`         | false    |     |     |     |  ✓  |     |
| `coord`  | `Beyond end`           | false    |     |     |     |     |  ✓  |

- Endpoints, midpoint, off-line, beyond-end

```mbt check
///|
test "coord_on_line - endpoints, midpoint, off-line, beyond-end" {
  let l = @type.Line::from_tuples((0.0, 0.0), (10.0, 0.0))
  assert_true(coord_on_line(@type.Coord::Coord(0.0, 0.0), l))
  assert_true(coord_on_line(@type.Coord::Coord(10.0, 0.0), l))
  assert_true(coord_on_line(@type.Coord::Coord(5.0, 0.0), l))
  assert_false(coord_on_line(@type.Coord::Coord(5.0, 1.0), l))
  assert_false(coord_on_line(@type.Coord::Coord(11.0, 0.0), l))
}
```

### `CoordPositionFor`

#### `coord_position`

| Variable        | State                                              | Note          |  1  |  2  |  3  |  4  |  5  |  6  |  7  |  8  |
| :-------------- | :------------------------------------------------- | :------------ | :-: | :-: | :-: | :-: | :-: | :-: | :-: | :-: |
| `self`/`coord`  | `Polygon, coord inside`                            | `Inside`      |  ✓  |     |     |     |     |     |     |     |
| `self`/`coord`  | `Polygon, coord on edge`                           | `OnBoundary`  |     |  ✓  |     |     |     |     |     |     |
| `self`/`coord`  | `Polygon, coord outside`                           | `Outside`     |     |     |  ✓  |     |     |     |     |     |
| `self`/`coord`  | `Polygon with hole, coord inside hole`             | `Outside`     |     |     |     |  ✓  |     |     |     |     |
| `self`/`coord`  | `Polygon with hole, coord on hole boundary`        | `OnBoundary`  |     |     |     |     |  ✓  |     |     |     |
| `self`/`coord`  | `Rect, coord inside`                               | `Inside`      |     |     |     |     |     |  ✓  |     |     |
| `self`/`coord`  | `Rect, coord on edge`                              | `OnBoundary`  |     |     |     |     |     |     |  ✓  |     |
| `self`/`coord`  | `Rect, coord outside`                              | `Outside`     |     |     |     |     |     |     |     |  ✓  |

- Polygon: inside, boundary, outside

```mbt check
///|
test "CoordPositionFor::coord_position - Polygon inside, boundary, outside" {
  let p = @type.Polygon::Polygon(
    @type.LineString::from_tuples([
      (0.0, 0.0),
      (2.0, 0.0),
      (2.0, 2.0),
      (0.0, 2.0),
      (0.0, 0.0),
    ]),
    [],
  )
  @test.assert_eq(
    CoordPositionFor::coord_position(p, @type.Coord::Coord(1.0, 1.0)),
    CoordPos::Inside,
  )
  @test.assert_eq(
    CoordPositionFor::coord_position(p, @type.Coord::Coord(0.0, 1.0)),
    CoordPos::OnBoundary,
  )
  @test.assert_eq(
    CoordPositionFor::coord_position(p, @type.Coord::Coord(5.0, 5.0)),
    CoordPos::Outside,
  )
}
```

- Polygon with hole: inside-hole is `Outside`, hole boundary is `OnBoundary`, polygon-not-hole is `Inside`

```mbt check
///|
test "CoordPositionFor::coord_position - Polygon with hole demotes to Outside" {
  let p = @type.Polygon::Polygon(
    @type.LineString::from_tuples([
      (0.0, 0.0),
      (10.0, 0.0),
      (10.0, 10.0),
      (0.0, 10.0),
      (0.0, 0.0),
    ]),
    [
      @type.LineString::from_tuples([
        (3.0, 3.0),
        (7.0, 3.0),
        (7.0, 7.0),
        (3.0, 7.0),
        (3.0, 3.0),
      ]),
    ],
  )
  @test.assert_eq(
    CoordPositionFor::coord_position(p, @type.Coord::Coord(5.0, 5.0)),
    CoordPos::Outside,
  )
  @test.assert_eq(
    CoordPositionFor::coord_position(p, @type.Coord::Coord(3.0, 5.0)),
    CoordPos::OnBoundary,
  )
  @test.assert_eq(
    CoordPositionFor::coord_position(p, @type.Coord::Coord(1.0, 1.0)),
    CoordPos::Inside,
  )
}
```

- Rect: inside, boundary, outside

```mbt check
///|
test "CoordPositionFor::coord_position - Rect inside, boundary, outside" {
  let r = @type.Rect::Rect(
    @type.Coord::Coord(0.0, 0.0),
    @type.Coord::Coord(10.0, 10.0),
  )
  @test.assert_eq(
    CoordPositionFor::coord_position(r, @type.Coord::Coord(5.0, 5.0)),
    CoordPos::Inside,
  )
  @test.assert_eq(
    CoordPositionFor::coord_position(r, @type.Coord::Coord(0.0, 5.0)),
    CoordPos::OnBoundary,
  )
  @test.assert_eq(
    CoordPositionFor::coord_position(r, @type.Coord::Coord(11.0, 11.0)),
    CoordPos::Outside,
  )
}
```

- Line: degenerate (start==end) and non-degenerate cases

```mbt check
///|
test "CoordPositionFor::coord_position - Line degenerate / endpoint / interior / off-line" {
  let degenerate = @type.Line::from_tuples((3.0, 4.0), (3.0, 4.0))
  @test.assert_eq(
    CoordPositionFor::coord_position(degenerate, @type.Coord::Coord(3.0, 4.0)),
    CoordPos::Inside,
  )
  @test.assert_eq(
    CoordPositionFor::coord_position(degenerate, @type.Coord::Coord(0.0, 0.0)),
    CoordPos::Outside,
  )
  let l = @type.Line::from_tuples((0.0, 0.0), (10.0, 0.0))
  @test.assert_eq(
    CoordPositionFor::coord_position(l, @type.Coord::Coord(0.0, 0.0)),
    CoordPos::OnBoundary,
  )
  @test.assert_eq(
    CoordPositionFor::coord_position(l, @type.Coord::Coord(5.0, 0.0)),
    CoordPos::Inside,
  )
  @test.assert_eq(
    CoordPositionFor::coord_position(l, @type.Coord::Coord(5.0, 5.0)),
    CoordPos::Outside,
  )
}
```

- LineString: empty / endpoint / interior / off-line

```mbt check
///|
test "CoordPositionFor::coord_position - LineString empty / endpoint / interior / off-line" {
  @test.assert_eq(
    CoordPositionFor::coord_position(
      @type.LineString::empty(),
      @type.Coord::Coord(0.0, 0.0),
    ),
    CoordPos::Outside,
  )
  let ls = @type.LineString::from_tuples([(0.0, 0.0), (5.0, 0.0), (10.0, 0.0)])
  @test.assert_eq(
    CoordPositionFor::coord_position(ls, @type.Coord::Coord(0.0, 0.0)),
    CoordPos::OnBoundary,
  )
  @test.assert_eq(
    CoordPositionFor::coord_position(ls, @type.Coord::Coord(2.5, 0.0)),
    CoordPos::Inside,
  )
  @test.assert_eq(
    CoordPositionFor::coord_position(ls, @type.Coord::Coord(5.0, 5.0)),
    CoordPos::Outside,
  )
}
```

- MultiPolygon: Inside dominates and OnBoundary surfaces

```mbt check
///|
test "CoordPositionFor::coord_position - MultiPolygon Inside / OnBoundary / Outside" {
  let in_polygon = @type.Polygon::Polygon(
    @type.LineString::from_tuples([
      (0.0, 0.0),
      (10.0, 0.0),
      (10.0, 10.0),
      (0.0, 10.0),
      (0.0, 0.0),
    ]),
    [],
  )
  let other_polygon = @type.Polygon::Polygon(
    @type.LineString::from_tuples([
      (20.0, 20.0),
      (30.0, 20.0),
      (30.0, 30.0),
      (20.0, 30.0),
      (20.0, 20.0),
    ]),
    [],
  )
  let mp = @type.MultiPolygon::MultiPolygon([in_polygon, other_polygon])
  @test.assert_eq(
    CoordPositionFor::coord_position(mp, @type.Coord::Coord(5.0, 5.0)),
    CoordPos::Inside,
  )
  @test.assert_eq(
    CoordPositionFor::coord_position(mp, @type.Coord::Coord(0.0, 5.0)),
    CoordPos::OnBoundary,
  )
  @test.assert_eq(
    CoordPositionFor::coord_position(mp, @type.Coord::Coord(100.0, 100.0)),
    CoordPos::Outside,
  )
}
```

- Triangle: dispatch via `Triangle::to_polygon`

```mbt check
///|
test "CoordPositionFor::coord_position - Triangle dispatches via to_polygon" {
  let t = @type.Triangle::Triangle(
    @type.Coord::Coord(0.0, 0.0),
    @type.Coord::Coord(10.0, 0.0),
    @type.Coord::Coord(0.0, 10.0),
  )
  @test.assert_eq(
    CoordPositionFor::coord_position(t, @type.Coord::Coord(2.0, 2.0)),
    CoordPos::Inside,
  )
  @test.assert_eq(
    CoordPositionFor::coord_position(t, @type.Coord::Coord(20.0, 20.0)),
    CoordPos::Outside,
  )
}
```

- `Geometry` dispatch sweep over every variant

```mbt check
///|
test "CoordPositionFor::coord_position - Geometry dispatch sweep" {
  let g_pt = @type.Geometry::Point(@type.Point::Point(0.0, 0.0))
  let g_line = @type.Geometry::Line(
    @type.Line::from_tuples((0.0, 0.0), (10.0, 0.0)),
  )
  let g_ls = @type.Geometry::LineString(
    @type.LineString::from_tuples([(0.0, 0.0), (10.0, 0.0)]),
  )
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
  let g_polygon = @type.Geometry::Polygon(polygon)
  let g_mp = @type.Geometry::MultiPoint(
    @type.MultiPoint::from_tuples([(5.0, 5.0)]),
  )
  let g_mls = @type.Geometry::MultiLineString(
    @type.MultiLineString::MultiLineString([
      @type.LineString::from_tuples([(0.0, 0.0), (10.0, 0.0)]),
    ]),
  )
  let g_mpoly = @type.Geometry::MultiPolygon(
    @type.MultiPolygon::MultiPolygon([polygon]),
  )
  let g_rect = @type.Geometry::Rect(
    @type.Rect::Rect(
      @type.Coord::Coord(0.0, 0.0),
      @type.Coord::Coord(10.0, 10.0),
    ),
  )
  let g_tri = @type.Geometry::Triangle(
    @type.Triangle::Triangle(
      @type.Coord::Coord(0.0, 0.0),
      @type.Coord::Coord(10.0, 0.0),
      @type.Coord::Coord(0.0, 10.0),
    ),
  )
  let g_gc = @type.Geometry::GeometryCollection(
    @type.GeometryCollection::GeometryCollection([g_pt]),
  )
  @test.assert_eq(
    CoordPositionFor::coord_position(g_pt, @type.Coord::Coord(0.0, 0.0)),
    CoordPos::Inside,
  )
  @test.assert_eq(
    CoordPositionFor::coord_position(g_pt, @type.Coord::Coord(1.0, 1.0)),
    CoordPos::Outside,
  )
  let inside = @type.Coord::Coord(5.0, 0.0)
  @test.assert_eq(
    CoordPositionFor::coord_position(g_line, inside),
    CoordPos::Inside,
  )
  @test.assert_eq(
    CoordPositionFor::coord_position(g_ls, inside),
    CoordPos::Inside,
  )
  @test.assert_eq(
    CoordPositionFor::coord_position(g_polygon, @type.Coord::Coord(5.0, 5.0)),
    CoordPos::Inside,
  )
  @test.assert_eq(
    CoordPositionFor::coord_position(g_mp, @type.Coord::Coord(5.0, 5.0)),
    CoordPos::Inside,
  )
  @test.assert_eq(
    CoordPositionFor::coord_position(g_mls, @type.Coord::Coord(5.0, 0.0)),
    CoordPos::Inside,
  )
  @test.assert_eq(
    CoordPositionFor::coord_position(g_mpoly, @type.Coord::Coord(5.0, 5.0)),
    CoordPos::Inside,
  )
  @test.assert_eq(
    CoordPositionFor::coord_position(g_rect, @type.Coord::Coord(5.0, 5.0)),
    CoordPos::Inside,
  )
  @test.assert_eq(
    CoordPositionFor::coord_position(g_tri, @type.Coord::Coord(2.0, 2.0)),
    CoordPos::Inside,
  )
  @test.assert_eq(
    CoordPositionFor::coord_position(g_gc, @type.Coord::Coord(0.0, 0.0)),
    CoordPos::Inside,
  )
}
```
