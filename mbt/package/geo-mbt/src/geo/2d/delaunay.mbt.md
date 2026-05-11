# delaunay.mbt

2D Delaunay triangulation via the **Bowyer-Watson incremental
algorithm**. The `geo-mbt` v0.2.0 first cut targets a viable subset of
[`spade`](https://github.com/Stoeoef/spade) — full DCEL, edge
constraints, conforming Delaunay, and walk-based location are deferred
to follow-up milestones (ms-28 Voronoi / ms-29 concave hull).

The core sweep:

1. Build a "super-triangle" enclosing the input bounding box.
2. For each input point, find every triangle whose circumcircle
   contains the point ("bad triangles") via the existing robust
   `incircle` predicate.
3. Replace the polygon hole left by the bad triangles with new
   triangles connecting the new point to each boundary edge, using
   `orient2d` to enforce CCW orientation.
4. After every input point is inserted, discard any triangle still
   touching a super-triangle vertex.

The "find bad triangles" step is brute force (O(n) per insertion,
O(n²) total), acceptable for v0.2.0 — a spatial-index-backed walk is
deferred. The `incircle` predicate currently uses Shewchuk's
non-adaptive fast path (see `robust/incircle.mbt`); near-cocircular
inputs may misclassify until the adaptive version is ported.

## Public API

- `delaunay_triangulation` — `(Array[Coord]) -> Array[DelaunayTriangle]?`
- `delaunay_triangles_to_geometries` — `(Array[Coord], Array[DelaunayTriangle]) -> Array[Triangle]`

## Test

### `delaunay_triangulation`

| Variable | State                    | Note                                                     |  1  |  2  |  3  |  4  |  5  |  6  |
| :------- | :----------------------- | :------------------------------------------------------- | :-: | :-: | :-: | :-: | :-: | :-: |
| `points` | empty                    | `None`                                                   |  ✓  |     |     |     |     |     |
| `points` | 3 collinear              | `None`                                                   |     |  ✓  |     |     |     |     |
| `points` | 3 non-collinear          | exactly 1 triangle covering the input vertices           |     |     |  ✓  |     |     |     |
| `points` | 4 corners of unit square | exactly 2 triangles sharing one diagonal edge            |     |     |     |  ✓  |     |     |
| `points` | square + center          | exactly 4 triangles, all sharing the center vertex (fan) |     |     |     |     |  ✓  |     |
| `points` | 25 grid points (5×5)     | Euler-formula triangle count `2N - h - 2` (N=25, h=16)   |     |     |     |     |     |  ✓  |

- Empty input returns `None`.

```mbt check
///|
test "delaunay_triangulation - empty" {
  let result = delaunay_triangulation([])
  @test.assert_eq(result, None)
}
```

- Three collinear points have no Delaunay triangulation; result is
  `None`.

```mbt check
///|
test "delaunay_triangulation - collinear returns None" {
  let points = [
    @type.Coord(0.0, 0.0),
    @type.Coord(1.0, 0.0),
    @type.Coord(2.0, 0.0),
  ]
  let result = delaunay_triangulation(points)
  @test.assert_eq(result, None)
}
```

- Three non-collinear points form exactly one triangle, and its three
  vertex indices are a permutation of `{0, 1, 2}`.

```mbt check
///|
test "delaunay_triangulation - single triangle" {
  let points = [
    @type.Coord(0.0, 0.0),
    @type.Coord(1.0, 0.0),
    @type.Coord(0.0, 1.0),
  ]
  let result = delaunay_triangulation(points)
  match result {
    Some(triangles) => {
      @test.assert_eq(triangles.length(), 1)
      let t = triangles[0]
      let s = [t.a, t.b, t.c]
      s.sort()
      @test.assert_eq(s[0], 0)
      @test.assert_eq(s[1], 1)
      @test.assert_eq(s[2], 2)
    }
    None => abort("expected Some(triangles)")
  }
}
```

- Four corners of a unit square produce exactly two triangles. Their
  shared edge is one of the two diagonals.

```mbt check
///|
test "delaunay_triangulation - square -> 2 triangles" {
  let points = [
    @type.Coord(0.0, 0.0),
    @type.Coord(1.0, 0.0),
    @type.Coord(1.0, 1.0),
    @type.Coord(0.0, 1.0),
  ]
  let result = delaunay_triangulation(points)
  match result {
    Some(triangles) => {
      @test.assert_eq(triangles.length(), 2)
      // Each triangle has exactly 3 distinct vertex indices in [0, 4).
      for k = 0; k < 2; k = k + 1 {
        let t = triangles[k]
        assert_true(t.a >= 0 && t.a < 4)
        assert_true(t.b >= 0 && t.b < 4)
        assert_true(t.c >= 0 && t.c < 4)
        assert_true(t.a != t.b)
        assert_true(t.b != t.c)
        assert_true(t.a != t.c)
      }
    }
    None => abort("expected Some(triangles)")
  }
}
```

- Square plus the center point: every triangle in the result fans from
  the center vertex (index 4), and there are exactly four such
  triangles.

```mbt check
///|
test "delaunay_triangulation - square plus center fans from center" {
  let points = [
    @type.Coord(0.0, 0.0),
    @type.Coord(1.0, 0.0),
    @type.Coord(1.0, 1.0),
    @type.Coord(0.0, 1.0),
    @type.Coord(0.5, 0.5),
  ]
  let result = delaunay_triangulation(points)
  match result {
    Some(triangles) => {
      @test.assert_eq(triangles.length(), 4)
      // Every triangle includes vertex 4 (the center).
      for k = 0; k < triangles.length(); k = k + 1 {
        let t = triangles[k]
        assert_true(t.a == 4 || t.b == 4 || t.c == 4)
      }
    }
    None => abort("expected Some(triangles)")
  }
}
```

- A 5×5 axis-aligned grid (25 points, 16 on the convex hull) yields a
  triangulation whose triangle count matches Euler's formula
  `2N - h - 2 = 2·25 - 16 - 2 = 32`. (Holds in general position; the
  grid is OK because the algorithm picks a consistent diagonal in each
  unit square.)

```mbt check
///|
test "delaunay_triangulation - 5x5 grid Euler formula" {
  let points : Array[@type.Coord] = []
  for i = 0; i < 5; i = i + 1 {
    for j = 0; j < 5; j = j + 1 {
      points.push(@type.Coord(i.to_double(), j.to_double()))
    }
  }
  let result = delaunay_triangulation(points)
  match result {
    Some(triangles) => @test.assert_eq(triangles.length(), 32)
    None => abort("expected Some(triangles)")
  }
}
```

### `delaunay_triangles_to_geometries`

| Variable    | State                            | Note                                  |  1  |
| :---------- | :------------------------------- | :------------------------------------ | :-: |
| `triangles` | result of triangulating a square | one `Triangle` per input index-triple |  ✓  |

- Round-trips a triangulation into concrete `Triangle` geometries.

```mbt check
///|
test "delaunay_triangles_to_geometries - round-trip square" {
  let points = [
    @type.Coord(0.0, 0.0),
    @type.Coord(1.0, 0.0),
    @type.Coord(1.0, 1.0),
    @type.Coord(0.0, 1.0),
  ]
  let triangles = match delaunay_triangulation(points) {
    Some(ts) => ts
    None => abort("expected Some(triangles)")
  }
  let geometries = delaunay_triangles_to_geometries(points, triangles)
  @test.assert_eq(geometries.length(), triangles.length())
  for k = 0; k < geometries.length(); k = k + 1 {
    let t = triangles[k]
    let g = geometries[k]
    @test.assert_eq(g.v0(), points[t.a])
    @test.assert_eq(g.v1(), points[t.b])
    @test.assert_eq(g.v2(), points[t.c])
  }
}
```
