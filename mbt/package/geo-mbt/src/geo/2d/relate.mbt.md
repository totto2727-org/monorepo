# relate.mbt

Direct-computation port of georust/geo's
[`algorithm/relate`](https://github.com/georust/geo/blob/main/geo/src/algorithm/relate/),
which builds the [DE-9IM](https://en.wikipedia.org/wiki/DE-9IM)
intersection matrix for two geometries and exposes the OGC predicate
masks (`is_contains`, `is_within`, `is_touches`, ...) on top of it.

The full upstream implementation is built on a planar
`geomgraph` that labels every edge endpoint and intersection node with
side / position information; it is **not** ported here. Instead, this
milestone uses pragmatic case analysis on the existing pairwise
predicates (`contains`, `intersects`, `coord_position_for_polygon`,
...) plus the segment-intersection helpers from `sweep.mbt`. The
resulting matrix is exact for the common pairs:

- `Point × Point` / `Point × LineString` / `Point × Polygon`
- `LineString × LineString`
- `LineString × Polygon`
- `Polygon × Polygon`

Triangle / Rect / Line are reduced to Polygon / LineString first, so
their relations route through the same code paths. Multi-* and
GeometryCollection fall through to a conservative
`relate_default` that fills only the disjoint cells exactly — a
follow-up cycle (`TODO ms-20-followup` in the source) will replace
that with the full `geomgraph` construction.

## Public API

- `IntersectionMatrix` — the 9-cell DE-9IM matrix
- `IntersectionMatrix::empty`
- `IntersectionMatrix::get`
- Predicate methods on `IntersectionMatrix`: `is_disjoint`,
  `is_intersects`, `is_contains`, `is_within`, `is_covers`,
  `is_covered_by`, `is_equals`, `is_touches`, `is_crosses`,
  `is_overlaps`
- `relate` — compute the matrix
- Convenience predicate functions: `relate_intersects`,
  `relate_disjoint`, `relate_contains`, `relate_within`,
  `relate_covers`, `relate_touches`, `relate_crosses`,
  `relate_equals`, `relate_overlaps`

## Test

### `relate` and predicates

| Variable | State                                            | Note                                     |  1  |  2  |  3  |  4  |  5  |  6  |  7  |  8  |  9  |
| :------- | :----------------------------------------------- | :--------------------------------------- | :-: | :-: | :-: | :-: | :-: | :-: | :-: | :-: | :-: |
| `(a, b)` | two distinct points                              | `disjoint`, `II = Empty`                 |  ✓  |     |     |     |     |     |     |     |     |
| `(a, b)` | identical points                                 | `equals`                                 |     |  ✓  |     |     |     |     |     |     |     |
| `(a, b)` | polygon, point in interior                       | `contains` and `covers`                  |     |     |  ✓  |     |     |     |     |     |     |
| `(a, b)` | polygon, point on boundary                       | `covers` but **not** `contains` (OGC)    |     |     |     |  ✓  |     |     |     |     |     |
| `(a, b)` | two crossing line segments                       | `crosses` and `intersects`               |     |     |     |     |  ✓  |     |     |     |     |
| `(a, b)` | two equal polygons                               | `equals`                                 |     |     |     |     |     |  ✓  |     |     |     |
| `(a, b)` | polygon strictly inside polygon                  | `contains`                               |     |     |     |     |     |     |  ✓  |     |     |
| `(a, b)` | two well-separated polygons                      | `disjoint`, **not** `intersects`         |     |     |     |     |     |     |     |  ✓  |     |
| `(a, b)` | polygons sharing exactly one boundary edge       | `touches`, **not** `overlaps`            |     |     |     |     |     |     |     |     |  ✓  |

- Two distinct points are disjoint and never intersect.

```mbt check
///|
test "relate - two disjoint points" {
  let a = @type.Geometry::Point(@type.Point::Point(0.0, 0.0))
  let b = @type.Geometry::Point(@type.Point::Point(1.0, 1.0))
  let m = relate(a, b)
  @test.assert_eq(m.get(Inside, Inside), Empty)
  @test.assert_eq(m.get(Outside, Outside), TwoDimensional)
  assert_true(m.is_disjoint())
  assert_false(m.is_intersects())
}
```

- A point relates to itself as topologically equal.

```mbt check
///|
test "relate - equal points are equal" {
  let p = @type.Geometry::Point(@type.Point::Point(2.0, 3.0))
  let m = relate(p, p)
  assert_true(m.is_equals())
  assert_true(m.is_intersects())
}
```

- A polygon `contains` (and therefore `covers`) a point in its
  interior.

```mbt check
///|
test "relate - point inside polygon interior is contained" {
  let p = @type.Geometry::Point(@type.Point::Point(5.0, 5.0))
  let poly = @type.Geometry::Polygon(
    @type.Polygon::Polygon(
      @type.LineString::from_tuples([
        (0.0, 0.0),
        (10.0, 0.0),
        (10.0, 10.0),
        (0.0, 10.0),
        (0.0, 0.0),
      ]),
      [],
    ),
  )
  let m = relate(poly, p)
  assert_true(m.is_contains())
  assert_true(m.is_covers())
}
```

- A polygon `covers` (but does **not** `contains`, per OGC) a point on
  its boundary.

```mbt check
///|
test "relate - point on polygon boundary is covered, not contained" {
  let p = @type.Geometry::Point(@type.Point::Point(0.0, 5.0))
  let poly = @type.Geometry::Polygon(
    @type.Polygon::Polygon(
      @type.LineString::from_tuples([
        (0.0, 0.0),
        (10.0, 0.0),
        (10.0, 10.0),
        (0.0, 10.0),
        (0.0, 0.0),
      ]),
      [],
    ),
  )
  let m = relate(poly, p)
  assert_false(m.is_contains())
  assert_true(m.is_covers())
}
```

- Two diagonals of a unit square cross at their midpoints — proper
  interior crossing.

```mbt check
///|
test "relate - two crossing lines cross" {
  let l1 = @type.Geometry::Line(@type.Line::from_tuples((0.0, 0.0), (1.0, 1.0)))
  let l2 = @type.Geometry::Line(@type.Line::from_tuples((1.0, 0.0), (0.0, 1.0)))
  let m = relate(l1, l2)
  assert_true(m.is_crosses())
  assert_true(m.is_intersects())
}
```

- Two equal polygons compare equal under DE-9IM `equals`.

```mbt check
///|
test "relate - two equal polygons are equal" {
  let poly = @type.Geometry::Polygon(
    @type.Polygon::Polygon(
      @type.LineString::from_tuples([
        (0.0, 0.0),
        (1.0, 0.0),
        (1.0, 1.0),
        (0.0, 1.0),
        (0.0, 0.0),
      ]),
      [],
    ),
  )
  let m = relate(poly, poly)
  assert_true(m.is_equals())
}
```

- A polygon strictly inside another (no boundary touch) is contained
  by it.

```mbt check
///|
test "relate - polygon inside polygon is contained" {
  let outer = @type.Geometry::Polygon(
    @type.Polygon::Polygon(
      @type.LineString::from_tuples([
        (0.0, 0.0),
        (10.0, 0.0),
        (10.0, 10.0),
        (0.0, 10.0),
        (0.0, 0.0),
      ]),
      [],
    ),
  )
  let inner = @type.Geometry::Polygon(
    @type.Polygon::Polygon(
      @type.LineString::from_tuples([
        (3.0, 3.0),
        (7.0, 3.0),
        (7.0, 7.0),
        (3.0, 7.0),
        (3.0, 3.0),
      ]),
      [],
    ),
  )
  let m = relate(outer, inner)
  assert_true(m.is_contains())
}
```

- Two polygons with disjoint bounding rectangles are disjoint and do
  not intersect.

```mbt check
///|
test "relate - two well-separated polygons are disjoint" {
  let p1 = @type.Geometry::Polygon(
    @type.Polygon::Polygon(
      @type.LineString::from_tuples([
        (0.0, 0.0),
        (1.0, 0.0),
        (1.0, 1.0),
        (0.0, 1.0),
        (0.0, 0.0),
      ]),
      [],
    ),
  )
  let p2 = @type.Geometry::Polygon(
    @type.Polygon::Polygon(
      @type.LineString::from_tuples([
        (10.0, 10.0),
        (11.0, 10.0),
        (11.0, 11.0),
        (10.0, 11.0),
        (10.0, 10.0),
      ]),
      [],
    ),
  )
  let m = relate(p1, p2)
  assert_true(m.is_disjoint())
  assert_false(m.is_intersects())
}
```

- Two polygons sharing exactly one boundary edge `touch` and do not
  `overlap` — their interiors are disjoint.

```mbt check
///|
test "relate - polygons sharing one edge touch (not overlap)" {
  let p1 = @type.Geometry::Polygon(
    @type.Polygon::Polygon(
      @type.LineString::from_tuples([
        (0.0, 0.0),
        (1.0, 0.0),
        (1.0, 1.0),
        (0.0, 1.0),
        (0.0, 0.0),
      ]),
      [],
    ),
  )
  let p2 = @type.Geometry::Polygon(
    @type.Polygon::Polygon(
      @type.LineString::from_tuples([
        (1.0, 0.0),
        (2.0, 0.0),
        (2.0, 1.0),
        (1.0, 1.0),
        (1.0, 0.0),
      ]),
      [],
    ),
  )
  let m = relate(p1, p2)
  assert_true(m.is_touches())
  assert_false(m.is_overlaps())
}
```
