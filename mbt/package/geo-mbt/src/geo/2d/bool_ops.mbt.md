# bool_ops.mbt

General-polygon boolean operations via the Greiner-Hörmann (1998) algorithm.
Replaces the earlier Sutherland-Hodgman implementation, which only handled clipping against a convex polygon.

## Public API

- `polygon_intersection` — points in both inputs.
- `polygon_union` — points in either input.
- `polygon_difference` — points in `a` but not `b`.
- `polygon_xor` — points in exactly one of the inputs.
- `unary_union` — fold-union of every polygon in a `MultiPolygon`.
- `clip_line_string` — restrict a `LineString` to the inside of a `Polygon`.

Deprecated wrappers (preserved for backward compatibility):

- `intersection_sutherland_hodgman` — delegates to `polygon_intersection`.
- `intersection_polygon_rect` — delegates to `polygon_intersection`.

## Test

### Two disjoint squares

| Variable | State    | Note               |  1  |  2  |  3  |  4  |
| :------- | :------- | :----------------- | :-: | :-: | :-: | :-: |
| `a`/`b`  | Disjoint | `intersection` = ∅ |  ✓  |     |     |     |
| `a`/`b`  | Disjoint | `union` = 2 polys  |     |  ✓  |     |     |
| `a`/`b`  | Disjoint | `difference` = a   |     |     |  ✓  |     |
| `a`/`b`  | Disjoint | `xor` = 2 polys    |     |     |     |  ✓  |

```mbt check
///|
test "polygon_intersection - disjoint squares is empty" {
  let a = @type.Polygon::Polygon(
    @type.LineString::from_tuples([
      (0.0, 0.0),
      (1.0, 0.0),
      (1.0, 1.0),
      (0.0, 1.0),
    ]),
    [],
  )
  let b = @type.Polygon::Polygon(
    @type.LineString::from_tuples([
      (3.0, 3.0),
      (4.0, 3.0),
      (4.0, 4.0),
      (3.0, 4.0),
    ]),
    [],
  )
  let r = polygon_intersection(a, b)
  @test.assert_eq(r.polygons().length(), 0)
}
```

```mbt check
///|
test "polygon_union - disjoint squares yields two polygons" {
  let a = @type.Polygon::Polygon(
    @type.LineString::from_tuples([
      (0.0, 0.0),
      (1.0, 0.0),
      (1.0, 1.0),
      (0.0, 1.0),
    ]),
    [],
  )
  let b = @type.Polygon::Polygon(
    @type.LineString::from_tuples([
      (3.0, 3.0),
      (4.0, 3.0),
      (4.0, 4.0),
      (3.0, 4.0),
    ]),
    [],
  )
  let r = polygon_union(a, b)
  @test.assert_eq(r.polygons().length(), 2)
  @test.assert_eq(HasArea::unsigned_area(r), 2.0)
}
```

```mbt check
///|
test "polygon_difference - disjoint inputs returns first" {
  let a = @type.Polygon::Polygon(
    @type.LineString::from_tuples([
      (0.0, 0.0),
      (1.0, 0.0),
      (1.0, 1.0),
      (0.0, 1.0),
    ]),
    [],
  )
  let b = @type.Polygon::Polygon(
    @type.LineString::from_tuples([
      (3.0, 3.0),
      (4.0, 3.0),
      (4.0, 4.0),
      (3.0, 4.0),
    ]),
    [],
  )
  let r = polygon_difference(a, b)
  @test.assert_eq(r.polygons().length(), 1)
  @test.assert_eq(HasArea::unsigned_area(r), 1.0)
}
```

```mbt check
///|
test "polygon_xor - disjoint inputs yields both" {
  let a = @type.Polygon::Polygon(
    @type.LineString::from_tuples([
      (0.0, 0.0),
      (1.0, 0.0),
      (1.0, 1.0),
      (0.0, 1.0),
    ]),
    [],
  )
  let b = @type.Polygon::Polygon(
    @type.LineString::from_tuples([
      (3.0, 3.0),
      (4.0, 3.0),
      (4.0, 4.0),
      (3.0, 4.0),
    ]),
    [],
  )
  let r = polygon_xor(a, b)
  @test.assert_eq(r.polygons().length(), 2)
  @test.assert_eq(HasArea::unsigned_area(r), 2.0)
}
```

### Overlapping squares

`a = (0,0)-(2,2)`, `b = (1,1)-(3,3)`. Overlap is the unit square `(1,1)-(2,2)`.

```mbt check
///|
test "polygon_intersection - overlapping squares" {
  let a = @type.Polygon::Polygon(
    @type.LineString::from_tuples([
      (0.0, 0.0),
      (2.0, 0.0),
      (2.0, 2.0),
      (0.0, 2.0),
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
  let r = polygon_intersection(a, b)
  @test.assert_eq(r.polygons().length(), 1)
  let area = HasArea::unsigned_area(r)
  assert_true((area - 1.0).abs() < TOLERANCE)
}
```

```mbt check
///|
test "polygon_union - overlapping squares" {
  let a = @type.Polygon::Polygon(
    @type.LineString::from_tuples([
      (0.0, 0.0),
      (2.0, 0.0),
      (2.0, 2.0),
      (0.0, 2.0),
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
  let r = polygon_union(a, b)
  @test.assert_eq(r.polygons().length(), 1)
  // 4 + 4 − 1 = 7
  let area = HasArea::unsigned_area(r)
  assert_true((area - 7.0).abs() < TOLERANCE)
}
```

```mbt check
///|
test "polygon_difference - overlapping squares" {
  let a = @type.Polygon::Polygon(
    @type.LineString::from_tuples([
      (0.0, 0.0),
      (2.0, 0.0),
      (2.0, 2.0),
      (0.0, 2.0),
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
  let r = polygon_difference(a, b)
  @test.assert_eq(r.polygons().length(), 1)
  // 4 − 1 = 3
  let area = HasArea::unsigned_area(r)
  assert_true((area - 3.0).abs() < TOLERANCE)
}
```

### One square fully inside another

`outer = (0,0)-(10,10)`, `inner = (3,3)-(7,7)`.

```mbt check
///|
test "polygon_intersection - inner is contained" {
  let outer = @type.Polygon::Polygon(
    @type.LineString::from_tuples([
      (0.0, 0.0),
      (10.0, 0.0),
      (10.0, 10.0),
      (0.0, 10.0),
    ]),
    [],
  )
  let inner = @type.Polygon::Polygon(
    @type.LineString::from_tuples([
      (3.0, 3.0),
      (7.0, 3.0),
      (7.0, 7.0),
      (3.0, 7.0),
    ]),
    [],
  )
  let r = polygon_intersection(outer, inner)
  @test.assert_eq(r.polygons().length(), 1)
  // Intersection equals the inner square — area 16.
  let area = HasArea::unsigned_area(r)
  assert_true((area - 16.0).abs() < TOLERANCE)
}
```

```mbt check
///|
test "polygon_union - inner is contained" {
  let outer = @type.Polygon::Polygon(
    @type.LineString::from_tuples([
      (0.0, 0.0),
      (10.0, 0.0),
      (10.0, 10.0),
      (0.0, 10.0),
    ]),
    [],
  )
  let inner = @type.Polygon::Polygon(
    @type.LineString::from_tuples([
      (3.0, 3.0),
      (7.0, 3.0),
      (7.0, 7.0),
      (3.0, 7.0),
    ]),
    [],
  )
  let r = polygon_union(outer, inner)
  @test.assert_eq(r.polygons().length(), 1)
  // Union equals the outer square — area 100.
  let area = HasArea::unsigned_area(r)
  assert_true((area - 100.0).abs() < TOLERANCE)
}
```

```mbt check
///|
test "polygon_difference - inner is contained yields outer-with-hole" {
  let outer = @type.Polygon::Polygon(
    @type.LineString::from_tuples([
      (0.0, 0.0),
      (10.0, 0.0),
      (10.0, 10.0),
      (0.0, 10.0),
    ]),
    [],
  )
  let inner = @type.Polygon::Polygon(
    @type.LineString::from_tuples([
      (3.0, 3.0),
      (7.0, 3.0),
      (7.0, 7.0),
      (3.0, 7.0),
    ]),
    [],
  )
  let r = polygon_difference(outer, inner)
  @test.assert_eq(r.polygons().length(), 1)
  @test.assert_eq(r.polygons()[0].interiors().length(), 1)
  // 100 − 16 = 84
  let area = HasArea::unsigned_area(r)
  assert_true((area - 84.0).abs() < TOLERANCE)
}
```

```mbt check
///|
test "polygon_xor - inner is contained yields outer-with-hole" {
  let outer = @type.Polygon::Polygon(
    @type.LineString::from_tuples([
      (0.0, 0.0),
      (10.0, 0.0),
      (10.0, 10.0),
      (0.0, 10.0),
    ]),
    [],
  )
  let inner = @type.Polygon::Polygon(
    @type.LineString::from_tuples([
      (3.0, 3.0),
      (7.0, 3.0),
      (7.0, 7.0),
      (3.0, 7.0),
    ]),
    [],
  )
  let r = polygon_xor(outer, inner)
  // diff(outer, inner) = outer-with-hole; diff(inner, outer) = empty.
  @test.assert_eq(r.polygons().length(), 1)
  @test.assert_eq(r.polygons()[0].interiors().length(), 1)
  let area = HasArea::unsigned_area(r)
  assert_true((area - 84.0).abs() < TOLERANCE)
}
```

### Concave (L-shape) inputs

L-shaped polygon clipped by a horizontal strip.

```mbt check
///|
test "polygon_intersection - L-shape ∩ horizontal strip" {
  // L-shape covering bottom row + right column (area 5: 3 wide × 1 tall +
  // 2 wide × 2 tall − 0 overlap on the corner cell, so 3 + 2 = 5).
  let l = @type.Polygon::Polygon(
    @type.LineString::from_tuples([
      (0.0, 0.0),
      (3.0, 0.0),
      (3.0, 3.0),
      (1.0, 3.0),
      (1.0, 1.0),
      (0.0, 1.0),
    ]),
    [],
  )
  // Strip 0..3 wide × 0.5..2 tall extending past the L on top and bottom.
  let strip = @type.Polygon::Polygon(
    @type.LineString::from_tuples([
      (-1.0, 0.5),
      (4.0, 0.5),
      (4.0, 2.0),
      (-1.0, 2.0),
    ]),
    [],
  )
  let r = polygon_intersection(l, strip)
  @test.assert_eq(r.polygons().length(), 1)
  // Intersection: bottom slab (0..3 × 0.5..1) area 1.5 +
  // upper-right slab (1..3 × 1..2) area 2.0 = 3.5
  let area = HasArea::unsigned_area(r)
  assert_true((area - 3.5).abs() < TOLERANCE)
}
```

### Annulus union

Identical annuli (outer ring with same inner hole). The union is the same annulus.

```mbt check
///|
test "polygon_union - annulus ∪ identical annulus" {
  let outer_ring = @type.LineString::from_tuples([
    (0.0, 0.0),
    (10.0, 0.0),
    (10.0, 10.0),
    (0.0, 10.0),
  ])
  let hole = @type.LineString::from_tuples([
    (3.0, 3.0),
    (3.0, 7.0),
    (7.0, 7.0),
    (7.0, 3.0),
  ])
  let a = @type.Polygon::Polygon(outer_ring, [hole])
  let b = @type.Polygon::Polygon(outer_ring, [hole])
  let r = polygon_union(a, b)
  @test.assert_eq(r.polygons().length(), 1)
  @test.assert_eq(r.polygons()[0].interiors().length(), 1)
  // 100 - 16 = 84.
  let area = HasArea::unsigned_area(r)
  assert_true((area - 84.0).abs() < TOLERANCE)
}
```

### Empty polygon inputs

```mbt check
///|
test "polygon_intersection - empty inputs" {
  let empty_p = @type.Polygon::empty()
  let a = @type.Polygon::Polygon(
    @type.LineString::from_tuples([
      (0.0, 0.0),
      (1.0, 0.0),
      (1.0, 1.0),
      (0.0, 1.0),
    ]),
    [],
  )
  @test.assert_eq(polygon_intersection(empty_p, a).polygons().length(), 0)
  @test.assert_eq(polygon_intersection(a, empty_p).polygons().length(), 0)
}
```

```mbt check
///|
test "polygon_union and difference - empty inputs" {
  let empty_p = @type.Polygon::empty()
  let a = @type.Polygon::Polygon(
    @type.LineString::from_tuples([
      (0.0, 0.0),
      (1.0, 0.0),
      (1.0, 1.0),
      (0.0, 1.0),
    ]),
    [],
  )
  // a ∪ ∅ = a
  @test.assert_eq(polygon_union(a, empty_p).polygons().length(), 1)
  // a \ ∅ = a
  @test.assert_eq(polygon_difference(a, empty_p).polygons().length(), 1)
  // ∅ \ a = ∅
  @test.assert_eq(polygon_difference(empty_p, a).polygons().length(), 0)
}
```

### LineString clipping

```mbt check
///|
test "clip_line_string - segment fully inside is unchanged" {
  let by = @type.Polygon::Polygon(
    @type.LineString::from_tuples([
      (0.0, 0.0),
      (10.0, 0.0),
      (10.0, 10.0),
      (0.0, 10.0),
    ]),
    [],
  )
  let ls = @type.LineString::from_tuples([(2.0, 2.0), (8.0, 8.0)])
  let r = clip_line_string(ls, by)
  @test.assert_eq(r.line_strings().length(), 1)
  let coords = r.line_strings()[0].coords()
  @test.assert_eq(coords.length(), 2)
  @test.assert_eq(coords[0], @type.Coord(2.0, 2.0))
  @test.assert_eq(coords[1], @type.Coord(8.0, 8.0))
}
```

```mbt check
///|
test "clip_line_string - segment fully outside is empty" {
  let by = @type.Polygon::Polygon(
    @type.LineString::from_tuples([
      (0.0, 0.0),
      (10.0, 0.0),
      (10.0, 10.0),
      (0.0, 10.0),
    ]),
    [],
  )
  let ls = @type.LineString::from_tuples([(20.0, 20.0), (30.0, 30.0)])
  let r = clip_line_string(ls, by)
  @test.assert_eq(r.line_strings().length(), 0)
}
```

```mbt check
///|
test "clip_line_string - segment straddling boundary is clipped" {
  let by = @type.Polygon::Polygon(
    @type.LineString::from_tuples([
      (0.0, 0.0),
      (10.0, 0.0),
      (10.0, 10.0),
      (0.0, 10.0),
    ]),
    [],
  )
  // Horizontal segment from x=-5 to x=15 at y=5; expected clip to x=0..10.
  let ls = @type.LineString::from_tuples([(-5.0, 5.0), (15.0, 5.0)])
  let r = clip_line_string(ls, by)
  @test.assert_eq(r.line_strings().length(), 1)
  let coords = r.line_strings()[0].coords()
  @test.assert_eq(coords.length(), 2)
  assert_true((coords[0].x() - 0.0).abs() < TOLERANCE)
  assert_true((coords[1].x() - 10.0).abs() < TOLERANCE)
}
```

### Deprecated wrappers

The two Sutherland-Hodgman entry points remain available; they delegate to `polygon_intersection` and return the first result polygon (or `Polygon::empty()` when the result is empty).

#### `intersection_polygon_rect`

| Variable         | State            | Note                       |  1  |  2  |  3  |  4  |
| :--------------- | :--------------- | :------------------------- | :-: | :-: | :-: | :-: |
| `subject`/`clip` | `Subject ⊆ clip` | result equals subject area |  ✓  |     |     |     |
| `subject`/`clip` | `Clip ⊆ subject` | result equals clip area    |     |  ✓  |     |     |
| `subject`/`clip` | `Half overlap`   | half of subject area       |     |     |  ✓  |     |
| `subject`/`clip` | `Disjoint`       | zero area                  |     |     |     |  ✓  |

```mbt check
///|
test "intersection_polygon_rect - subject inside clip equals subject area" {
  let subject = @type.Polygon::Polygon(
    @type.LineString::from_tuples([
      (2.0, 2.0),
      (4.0, 2.0),
      (4.0, 4.0),
      (2.0, 4.0),
    ]),
    [],
  )
  let clip = @type.Rect::Rect(
    @type.Coord::Coord(0.0, 0.0),
    @type.Coord::Coord(10.0, 10.0),
  )
  let area = HasArea::unsigned_area(intersection_polygon_rect(subject, clip))
  assert_true((area - 4.0).abs() < TOLERANCE)
}
```

```mbt check
///|
test "intersection_polygon_rect - clip inside subject equals clip area" {
  let subject = @type.Polygon::Polygon(
    @type.LineString::from_tuples([
      (0.0, 0.0),
      (10.0, 0.0),
      (10.0, 10.0),
      (0.0, 10.0),
    ]),
    [],
  )
  let clip = @type.Rect::Rect(
    @type.Coord::Coord(2.0, 2.0),
    @type.Coord::Coord(4.0, 4.0),
  )
  let area = HasArea::unsigned_area(intersection_polygon_rect(subject, clip))
  assert_true((area - 4.0).abs() < TOLERANCE)
}
```

```mbt check
///|
test "intersection_polygon_rect - half overlap" {
  let subject = @type.Polygon::Polygon(
    @type.LineString::from_tuples([
      (0.0, 0.0),
      (10.0, 0.0),
      (10.0, 10.0),
      (0.0, 10.0),
    ]),
    [],
  )
  let clip = @type.Rect::Rect(
    @type.Coord::Coord(5.0, -5.0),
    @type.Coord::Coord(15.0, 15.0),
  )
  // Right half: 5 × 10 = 50
  let area = HasArea::unsigned_area(intersection_polygon_rect(subject, clip))
  assert_true((area - 50.0).abs() < TOLERANCE)
}
```

```mbt check
///|
test "intersection_polygon_rect - disjoint inputs give zero area" {
  let subject = @type.Polygon::Polygon(
    @type.LineString::from_tuples([
      (0.0, 0.0),
      (1.0, 0.0),
      (1.0, 1.0),
      (0.0, 1.0),
    ]),
    [],
  )
  let clip = @type.Rect::Rect(
    @type.Coord::Coord(10.0, 10.0),
    @type.Coord::Coord(20.0, 20.0),
  )
  @test.assert_eq(
    HasArea::unsigned_area(intersection_polygon_rect(subject, clip)),
    0.0,
  )
}
```

#### `intersection_sutherland_hodgman`

```mbt check
///|
test "intersection_sutherland_hodgman - inner triangle equals clip area" {
  let subject = @type.Polygon::Polygon(
    @type.LineString::from_tuples([(0.0, 0.0), (10.0, 0.0), (5.0, 10.0)]),
    [],
  )
  let clip = @type.Polygon::Polygon(
    @type.LineString::from_tuples([(2.0, 2.0), (8.0, 2.0), (5.0, 8.0)]),
    [],
  )
  let area = HasArea::unsigned_area(
    intersection_sutherland_hodgman(subject, clip),
  )
  // The clip triangle is entirely inside the subject — area = 0.5 × 6 × 6 = 18.
  assert_true((area - 18.0).abs() < TOLERANCE)
}
```

### `unary_union`

```mbt check
///|
test "unary_union - single polygon returns same" {
  let a = @type.Polygon::Polygon(
    @type.LineString::from_tuples([
      (0.0, 0.0),
      (1.0, 0.0),
      (1.0, 1.0),
      (0.0, 1.0),
    ]),
    [],
  )
  let mp = @type.MultiPolygon::MultiPolygon([a])
  let r = unary_union(mp)
  @test.assert_eq(r.polygons().length(), 1)
  @test.assert_eq(HasArea::unsigned_area(r), 1.0)
}
```

```mbt check
///|
test "unary_union - two overlapping polygons collapse" {
  let a = @type.Polygon::Polygon(
    @type.LineString::from_tuples([
      (0.0, 0.0),
      (2.0, 0.0),
      (2.0, 2.0),
      (0.0, 2.0),
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
  let mp = @type.MultiPolygon::MultiPolygon([a, b])
  let r = unary_union(mp)
  @test.assert_eq(r.polygons().length(), 1)
  let area = HasArea::unsigned_area(r)
  assert_true((area - 7.0).abs() < TOLERANCE)
}
```
