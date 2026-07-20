# voronoi.mbt

2D Voronoi diagram computed as the **dual of the Delaunay triangulation** produced by `delaunay.mbt`.

The construction is purely topological:

1. Triangulate the input via `delaunay_triangulation`. Each Delaunay triangle's circumcenter becomes a Voronoi vertex.
2. Walk every triangle edge once, normalised so the smaller index comes first. Edges that appear twice are interior — their two adjacent circumcenters form a Voronoi edge. Edges that appear once live on the convex hull and produce an unbounded Voronoi ray.
3. Boundary rays start at the circumcenter and head outward along the perpendicular bisector of the Delaunay edge, away from the triangle's third vertex. They are clipped against a caller-supplied `bbox`.

Edge pairing is brute force (O(t²) over t triangles); good enough while the underlying Bowyer-Watson sweep is also O(n²). Polygonal Voronoi cells (sorted edge fans around each input point) and Liang-Barsky exact ray clipping are deferred to follow-up work.

## Public API

- `voronoi_diagram` — `(Array[Coord], Rect) -> Array[VoronoiEdge]?`
- `voronoi_vertices` — `(Array[Coord]) -> Array[Coord]?`

## Test

### `voronoi_vertices`

| Variable | State                | Note                                                   |  1  |  2  |  3  |
| :------- | :------------------- | :----------------------------------------------------- | :-: | :-: | :-: |
| `points` | 3 non-collinear      | exactly one vertex at the triangle circumcenter        |  ✓  |     |     |
| `points` | 3 collinear          | `None`                                                 |     |  ✓  |     |
| `points` | 5×5 grid (25 points) | one vertex per Delaunay triangle (32 by Euler formula) |     |     |  ✓  |

- Three non-collinear points produce exactly one Voronoi vertex — the circumcenter of the triangle.

```mbt check
///|
test "voronoi_vertices - single triangle" {
  let points = [
    @type.Coord(0.0, 0.0),
    @type.Coord(2.0, 0.0),
    @type.Coord(1.0, 2.0),
  ]
  let result = voronoi_vertices(points)
  match result {
    Some(vs) => {
      @test.assert_eq(vs.length(), 1)
      @test.assert_eq(vs[0].x(), 1.0)
      @test.assert_eq(vs[0].y(), 0.75)
    }
    None => abort("expected Some(vertices)")
  }
}
```

- Collinear input has no Delaunay triangulation, hence no Voronoi vertices.

```mbt check
///|
test "voronoi_vertices - collinear returns None" {
  let points = [
    @type.Coord(0.0, 0.0),
    @type.Coord(1.0, 0.0),
    @type.Coord(2.0, 0.0),
  ]
  let result = voronoi_vertices(points)
  @test.assert_eq(result, None)
}
```

- The 5×5 axis-aligned grid produces 32 Delaunay triangles (Euler `2N - h - 2 = 2·25 - 16 - 2`); each triangle contributes exactly one Voronoi vertex.

```mbt check
///|
test "voronoi_vertices - 5x5 grid count matches Delaunay" {
  let points : Array[@type.Coord] = []
  for i = 0; i < 5; i = i + 1 {
    for j = 0; j < 5; j = j + 1 {
      points.push(@type.Coord(i.to_double(), j.to_double()))
    }
  }
  let result = voronoi_vertices(points)
  match result {
    Some(vs) => @test.assert_eq(vs.length(), 32)
    None => abort("expected Some(vertices)")
  }
}
```

### `voronoi_diagram`

| Variable | State           | Note                                                     |  1  |  2  |  3  |  4  |  5  |
| :------- | :-------------- | :------------------------------------------------------- | :-: | :-: | :-: | :-: | :-: |
| `points` | empty           | `None`                                                   |  ✓  |     |     |     |     |
| `points` | 3 collinear     | `None`                                                   |     |  ✓  |     |     |     |
| `points` | 3 non-collinear | 3 boundary rays from the circumcenter to the bbox        |     |     |  ✓  |     |     |
| `points` | square corners  | 4 boundary rays (interior diagonal edge is degenerate)   |     |     |     |  ✓  |     |
| `points` | square + center | 8 edges (4 interior between cell midpoints + 4 boundary) |     |     |     |     |  ✓  |

- Empty input returns `None`.

```mbt check
///|
test "voronoi_diagram - empty" {
  let bbox = @type.Rect::Rect(@type.Coord(-1.0, -1.0), @type.Coord(1.0, 1.0))
  let result = voronoi_diagram([], bbox)
  @test.assert_eq(result, None)
}
```

- Collinear input returns `None` (Delaunay produces nothing).

```mbt check
///|
test "voronoi_diagram - collinear returns None" {
  let points = [
    @type.Coord(0.0, 0.0),
    @type.Coord(1.0, 0.0),
    @type.Coord(2.0, 0.0),
  ]
  let bbox = @type.Rect::Rect(
    @type.Coord(-10.0, -10.0),
    @type.Coord(10.0, 10.0),
  )
  let result = voronoi_diagram(points, bbox)
  @test.assert_eq(result, None)
}
```

- Three non-collinear points triangulate to a single Delaunay triangle.
  Its three edges all sit on the convex hull, so the diagram is three Voronoi rays — all starting at the single circumcenter `(1, 0.75)` — heading outward to the bbox.

```mbt check
///|
test "voronoi_diagram - single triangle" {
  let points = [
    @type.Coord(0.0, 0.0),
    @type.Coord(2.0, 0.0),
    @type.Coord(1.0, 2.0),
  ]
  let bbox = @type.Rect::Rect(
    @type.Coord(-10.0, -10.0),
    @type.Coord(10.0, 10.0),
  )
  let result = voronoi_diagram(points, bbox)
  match result {
    Some(edges) => {
      @test.assert_eq(edges.length(), 3)
      for k = 0; k < edges.length(); k = k + 1 {
        let e = edges[k]
        @test.assert_eq(e.start.x(), 1.0)
        @test.assert_eq(e.start.y(), 0.75)
      }
    }
    None => abort("expected Some(edges)")
  }
}
```

- The four square corners triangulate into two right triangles whose shared diagonal hypotenuse has midpoint `(0.5, 0.5)` — i.e. both circumcenters coincide and the interior Voronoi edge collapses to a point. The four convex-hull edges yield four rays out to the bbox, all anchored at `(0.5, 0.5)`.

```mbt check
///|
test "voronoi_diagram - square has 4 boundary rays" {
  let points = [
    @type.Coord(0.0, 0.0),
    @type.Coord(1.0, 0.0),
    @type.Coord(1.0, 1.0),
    @type.Coord(0.0, 1.0),
  ]
  let bbox = @type.Rect::Rect(
    @type.Coord(-10.0, -10.0),
    @type.Coord(10.0, 10.0),
  )
  let result = voronoi_diagram(points, bbox)
  match result {
    Some(edges) => {
      @test.assert_eq(edges.length(), 4)
      for k = 0; k < edges.length(); k = k + 1 {
        let e = edges[k]
        @test.assert_eq(e.start.x(), 0.5)
        @test.assert_eq(e.start.y(), 0.5)
      }
    }
    None => abort("expected Some(edges)")
  }
}
```

- Adding the center to the four square corners produces the canonical fan of four right triangles with circumcenters at the four edge midpoints `(0.5, 0)`, `(1, 0.5)`, `(0.5, 1)`, `(0, 0.5)`. Adjacent fan triangles share a spoke edge → 4 interior Voronoi edges; the four square sides give 4 boundary rays. Total: 8 edges.

```mbt check
///|
test "voronoi_diagram - square plus center has 8 edges" {
  let points = [
    @type.Coord(0.0, 0.0),
    @type.Coord(1.0, 0.0),
    @type.Coord(1.0, 1.0),
    @type.Coord(0.0, 1.0),
    @type.Coord(0.5, 0.5),
  ]
  let bbox = @type.Rect::Rect(
    @type.Coord(-10.0, -10.0),
    @type.Coord(10.0, 10.0),
  )
  let result = voronoi_diagram(points, bbox)
  match result {
    Some(edges) => @test.assert_eq(edges.length(), 8)
    None => abort("expected Some(edges)")
  }
}
```
