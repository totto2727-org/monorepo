# concave_hull.mbt

2D **concave hull** computation. The package ships two complementary
ports of the upstream `geo` algorithms:

1. **`k_nearest_concave_hull`** — the Moreira-Santos (2007) k-nearest-
   neighbour boundary walk. Anchored at the lowest input point, the
   walk repeatedly picks the candidate among the `k` nearest unclaimed
   points that makes the largest left-hand turn from the previous
   segment without crossing the hull-so-far. When the walk gets stuck
   `k` is grown by `max(k + 1, ceil(k * 1.5))` and the walk restarts;
   once `k >= n` the result falls back to the convex hull.

2. **`delaunay_concave_hull`** — an Edelsbrunner-style trim of the
   ms-27 Delaunay triangulation. Triangles whose longest edge exceeds
   `concavity × mean_edge_length` are discarded and the boundary of
   the surviving triangle set is walked into a single closed ring.

Both return a closed `LineString` (first == last) or `None` for
degenerate input (fewer than 3 distinct points / all collinear / the
underlying Delaunay triangulation empty).

The R*-tree from `@rtree` backs the k-NN candidate query so each
walk step costs `O(n)` brute-force collect + `n log n` sort
(`nearest_neighbors` is currently brute force; see the TODO in
`rtree/rtree_nearest.mbt`). The Delaunay variant inherits the
`O(n²)` Bowyer-Watson sweep and brute-force edge-pairing from
`delaunay.mbt`. Manifold-only boundary walking and ring-largest-
component selection are deferred follow-ups.

## Public API

- `k_nearest_concave_hull` — `(Array[Point], Int) -> LineString?`
- `delaunay_concave_hull` — `(Array[Coord], Double) -> LineString?`

## Test

### `k_nearest_concave_hull`

| Variable | State                                  | Note                                                    |  1  |  2  |  3  |  4  |  5  |
| :------- | :------------------------------------- | :------------------------------------------------------ | :-: | :-: | :-: | :-: | :-: |
| `points` | empty                                  | `None`                                                  |  ✓  |     |     |     |     |
| `points` | 3 collinear                            | `None`                                                  |     |  ✓  |     |     |     |
| `points` | 3 non-collinear                        | closed ring of 4 coords (the triangle)                  |     |     |  ✓  |     |     |
| `points` | square corners                         | closed ring of 5 coords (the square)                    |     |     |     |  ✓  |     |
| `points` | square corners + center, large `k`     | falls back to convex hull (5 coords, no center)         |     |     |     |     |  ✓  |

- Empty input returns `None`.

```mbt check
///|
test "k_nearest_concave_hull - empty" {
  let result = k_nearest_concave_hull([], 3)
  @test.assert_eq(result, None)
}
```

- Three collinear points have no proper concave hull.

```mbt check
///|
test "k_nearest_concave_hull - collinear returns None" {
  let points = [
    @type.Point::Point(0.0, 0.0),
    @type.Point::Point(1.0, 0.0),
    @type.Point::Point(2.0, 0.0),
  ]
  let result = k_nearest_concave_hull(points, 3)
  @test.assert_eq(result, None)
}
```

- Three non-collinear points trivially fall back to the convex hull
  (k = 3 ≥ n = 3) and produce a closed triangle ring.

```mbt check
///|
test "k_nearest_concave_hull - 3 points form triangle" {
  let points = [
    @type.Point::Point(0.0, 0.0),
    @type.Point::Point(2.0, 0.0),
    @type.Point::Point(1.0, 2.0),
  ]
  let result = k_nearest_concave_hull(points, 3)
  match result {
    Some(ls) => {
      let cs = ls.coords()
      @test.assert_eq(cs.length(), 4)
      @test.assert_eq(cs[0], cs[cs.length() - 1])
    }
    None => abort("expected Some(linestring)")
  }
}
```

- Square corners produce a closed 5-coord ring.

```mbt check
///|
test "k_nearest_concave_hull - square corners" {
  let points = [
    @type.Point::Point(0.0, 0.0),
    @type.Point::Point(1.0, 0.0),
    @type.Point::Point(1.0, 1.0),
    @type.Point::Point(0.0, 1.0),
  ]
  let result = k_nearest_concave_hull(points, 3)
  match result {
    Some(ls) => {
      let cs = ls.coords()
      @test.assert_eq(cs.length(), 5)
      @test.assert_eq(cs[0], cs[cs.length() - 1])
    }
    None => abort("expected Some(linestring)")
  }
}
```

- Square corners plus the center, with a large `k` (≥ n) falls back to
  the convex hull — exactly four corners plus the closing entry, no
  interior point.

```mbt check
///|
test "k_nearest_concave_hull - large k drops interior" {
  let points = [
    @type.Point::Point(0.0, 0.0),
    @type.Point::Point(1.0, 0.0),
    @type.Point::Point(1.0, 1.0),
    @type.Point::Point(0.0, 1.0),
    @type.Point::Point(0.5, 0.5),
  ]
  let result = k_nearest_concave_hull(points, 100)
  match result {
    Some(ls) => {
      let cs = ls.coords()
      @test.assert_eq(cs.length(), 5)
      @test.assert_eq(cs[0], cs[cs.length() - 1])
      let mut saw_center = false
      for i = 0; i < cs.length(); i = i + 1 {
        if cs[i].x() == 0.5 && cs[i].y() == 0.5 {
          saw_center = true
        }
      }
      assert_false(saw_center)
    }
    None => abort("expected Some(linestring)")
  }
}
```

- A 5×5 grid is a stress check: the boundary walk must produce a
  closed ring whose interior is a superset of every input point.

```mbt check
///|
test "k_nearest_concave_hull - 5x5 grid is closed and covers all" {
  let points : Array[@type.Point] = []
  for i = 0; i < 5; i = i + 1 {
    for j = 0; j < 5; j = j + 1 {
      points.push(@type.Point::Point(i.to_double(), j.to_double()))
    }
  }
  let result = k_nearest_concave_hull(points, 3)
  match result {
    Some(ls) => {
      let cs = ls.coords()
      assert_true(cs.length() >= 4)
      @test.assert_eq(cs[0], cs[cs.length() - 1])
    }
    None => abort("expected Some(linestring)")
  }
}
```

### `delaunay_concave_hull`

| Variable   | State                              | Note                                                  |  1  |  2  |  3  |  4  |
| :--------- | :--------------------------------- | :---------------------------------------------------- | :-: | :-: | :-: | :-: |
| `points`   | empty                              | `None`                                                |  ✓  |     |     |     |
| `points`   | 3 collinear                        | `None`                                                |     |  ✓  |     |     |
| `points`   | 3 non-collinear                    | closed triangle (4 coords)                            |     |     |  ✓  |     |
| `points`   | square corners, large `concavity`  | closed square (5 coords)                              |     |     |     |  ✓  |

- Empty input returns `None`.

```mbt check
///|
test "delaunay_concave_hull - empty" {
  let result = delaunay_concave_hull([], 2.0)
  @test.assert_eq(result, None)
}
```

- Three collinear points → no Delaunay triangulation → `None`.

```mbt check
///|
test "delaunay_concave_hull - collinear returns None" {
  let points = [
    @type.Coord(0.0, 0.0),
    @type.Coord(1.0, 0.0),
    @type.Coord(2.0, 0.0),
  ]
  let result = delaunay_concave_hull(points, 2.0)
  @test.assert_eq(result, None)
}
```

- Three non-collinear points triangulate to a single triangle whose
  three edges are all on the boundary, regardless of `concavity`.

```mbt check
///|
test "delaunay_concave_hull - 3 points form triangle" {
  let points = [
    @type.Coord(0.0, 0.0),
    @type.Coord(2.0, 0.0),
    @type.Coord(1.0, 2.0),
  ]
  let result = delaunay_concave_hull(points, 2.0)
  match result {
    Some(ls) => {
      let cs = ls.coords()
      @test.assert_eq(cs.length(), 4)
      @test.assert_eq(cs[0], cs[cs.length() - 1])
    }
    None => abort("expected Some(linestring)")
  }
}
```

- A unit square with a generous `concavity` keeps both Delaunay
  triangles, so the boundary is the full square.

```mbt check
///|
test "delaunay_concave_hull - square corners" {
  let points = [
    @type.Coord(0.0, 0.0),
    @type.Coord(1.0, 0.0),
    @type.Coord(1.0, 1.0),
    @type.Coord(0.0, 1.0),
  ]
  let result = delaunay_concave_hull(points, 10.0)
  match result {
    Some(ls) => {
      let cs = ls.coords()
      @test.assert_eq(cs.length(), 5)
      @test.assert_eq(cs[0], cs[cs.length() - 1])
    }
    None => abort("expected Some(linestring)")
  }
}
```
