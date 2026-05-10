// Voronoi diagram as the dual of the Delaunay triangulation.
//
// Each Delaunay triangle has a circumcenter that becomes a Voronoi
// vertex. Each pair of Delaunay triangles sharing an edge yields a
// Voronoi edge connecting their circumcenters. Each Delaunay edge on
// the convex hull (only one adjacent triangle) yields an unbounded
// Voronoi edge that is clipped to a caller-supplied bounding box.
//
// This is a v0.2.0 first cut sitting on top of the brute-force
// Bowyer-Watson triangulator (`delaunay.mbt`). Edge pairing is also
// brute force (O(t²) over t triangles), acceptable while Delaunay
// itself is O(n²). Future work — deferred:
//
//   - Polygonal Voronoi cells (sorted edge fans around each input
//     point).
//   - Exact ray clipping via Liang-Barsky once the rest of the 2D
//     module gains a clipping primitive.
//   - DCEL-backed adjacency to drop the O(t²) edge pairing.

///|
/// One edge of a Voronoi diagram. For an interior edge both endpoints
/// are circumcenters of adjacent Delaunay triangles; for a boundary
/// edge that would extend to infinity, the unbounded endpoint is
/// replaced by the projection onto the supplied bbox.
pub struct VoronoiEdge {
  start : @type.Coord
  end : @type.Coord
} derive(Eq, Debug)

///|
/// Compute the Voronoi diagram of a set of 2D points by triangulating
/// then taking the dual. Returns the list of Voronoi edges, or `None`
/// when the underlying Delaunay triangulation is empty (fewer than 3
/// points or all collinear).
///
/// `bbox` is used to clip the unbounded boundary edges. Pass a Rect
/// that comfortably contains all input points (e.g. an expanded
/// bounding rect).
pub fn voronoi_diagram(
  points : Array[@type.Coord],
  bbox : @type.Rect,
) -> Array[VoronoiEdge]? {
  match delaunay_triangulation(points) {
    None => None
    Some(triangles) => Some(build_voronoi_edges(points, triangles, bbox))
  }
}

///|
/// Compute just the Voronoi vertices — one circumcenter per Delaunay
/// triangle, in triangulation order. Returns `None` when the
/// underlying Delaunay triangulation is empty.
///
/// Degenerate triangles whose circumcenter cannot be computed (zero
/// determinant, i.e. collinear corners — shouldn't occur for a valid
/// Delaunay output) are skipped, so the returned array length may be
/// at most the triangle count.
pub fn voronoi_vertices(points : Array[@type.Coord]) -> Array[@type.Coord]? {
  match delaunay_triangulation(points) {
    None => None
    Some(triangles) => {
      let result : Array[@type.Coord] = []
      for i = 0; i < triangles.length(); i = i + 1 {
        let t = triangles[i]
        match circumcenter(points[t.a], points[t.b], points[t.c]) {
          Some(cc) => result.push(cc)
          None => ()
        }
      }
      Some(result)
    }
  }
}

///|
/// Build the Voronoi edges given a Delaunay triangulation. Iterates
/// every triangle edge once, pairs interior edges with their other
/// adjacent triangle, and clips boundary edges to `bbox`.
fn build_voronoi_edges(
  points : Array[@type.Coord],
  triangles : Array[DelaunayTriangle],
  bbox : @type.Rect,
) -> Array[VoronoiEdge] {
  let n_tri = triangles.length()

  // Circumcenters per triangle (with a `valid` flag for degenerate
  // triangles whose circumcenter cannot be computed).
  let circumcenters : Array[@type.Coord] = []
  let valid : Array[Bool] = []
  for i = 0; i < n_tri; i = i + 1 {
    let t = triangles[i]
    match circumcenter(points[t.a], points[t.b], points[t.c]) {
      Some(cc) => {
        circumcenters.push(cc)
        valid.push(true)
      }
      None => {
        circumcenters.push(@type.Coord(0.0, 0.0))
        valid.push(false)
      }
    }
  }

  // Flatten triangle edges into parallel arrays. `edges_third` stores
  // the index of the third triangle vertex (the one not on this edge),
  // needed to orient the outward Voronoi ray for boundary edges.
  let edges_u : Array[Int] = []
  let edges_v : Array[Int] = []
  let edges_tri : Array[Int] = []
  let edges_third : Array[Int] = []
  for i = 0; i < n_tri; i = i + 1 {
    let t = triangles[i]
    push_edge_record(edges_u, edges_v, edges_tri, edges_third, t.a, t.b, t.c, i)
    push_edge_record(edges_u, edges_v, edges_tri, edges_third, t.b, t.c, t.a, i)
    push_edge_record(edges_u, edges_v, edges_tri, edges_third, t.c, t.a, t.b, i)
  }

  // Pair edges: an edge appearing twice is interior (one Voronoi edge
  // between the two circumcenters); an edge appearing once is on the
  // convex hull (one Voronoi ray).
  let n_edges = edges_u.length()
  let processed : Array[Bool] = []
  for k = 0; k < n_edges; k = k + 1 {
    processed.push(false)
  }
  let result : Array[VoronoiEdge] = []
  for k = 0; k < n_edges; k = k + 1 {
    if !processed[k] {
      processed[k] = true
      let mut paired = -1
      for l = k + 1; l < n_edges; l = l + 1 {
        if paired < 0 &&
          !processed[l] &&
          edges_u[k] == edges_u[l] &&
          edges_v[k] == edges_v[l] {
          paired = l
          processed[l] = true
        }
      }
      if paired >= 0 {
        let t1 = edges_tri[k]
        let t2 = edges_tri[paired]
        if valid[t1] && valid[t2] {
          let cc1 = circumcenters[t1]
          let cc2 = circumcenters[t2]
          // Skip degenerate (zero-length) interior edges — happens
          // e.g. for the perfect square where both adjacent triangles
          // share a circumcenter at the diagonal midpoint.
          if cc1.x() != cc2.x() || cc1.y() != cc2.y() {
            result.push(VoronoiEdge::{ start: cc1, end: cc2 })
          }
        }
      } else {
        let ti = edges_tri[k]
        if valid[ti] {
          let cc = circumcenters[ti]
          let pa = points[edges_u[k]]
          let pb = points[edges_v[k]]
          let pc = points[edges_third[k]]
          match clip_ray_to_bbox(cc, pa, pb, pc, bbox) {
            Some(endpoint) =>
              result.push(VoronoiEdge::{ start: cc, end: endpoint })
            None => ()
          }
        }
      }
    }
  }
  result
}

///|
/// Compute the circumcenter of a triangle `(a, b, c)`. Returns `None`
/// when the three points are collinear (zero determinant), in which
/// case there is no finite circumcenter.
fn circumcenter(
  a : @type.Coord,
  b : @type.Coord,
  c : @type.Coord,
) -> @type.Coord? {
  let ax = a.x()
  let ay = a.y()
  let bx = b.x()
  let by = b.y()
  let cx = c.x()
  let cy = c.y()
  let d = 2.0 * ((ax - cx) * (by - cy) - (bx - cx) * (ay - cy))
  if d == 0.0 {
    return None
  }
  let asq = ax * ax + ay * ay
  let bsq = bx * bx + by * by
  let csq = cx * cx + cy * cy
  let ux = ((asq - csq) * (by - cy) - (bsq - csq) * (ay - cy)) / d
  let uy = ((bsq - csq) * (ax - cx) - (asq - csq) * (bx - cx)) / d
  Some(@type.Coord(ux, uy))
}

///|
/// Append a single triangle edge `(u, v)` (third vertex `w`, owning
/// triangle `tri_idx`) to the four parallel arrays in normalised form
/// (smaller index first) so two triangles sharing the edge produce
/// matching `(edges_u, edges_v)` entries.
fn push_edge_record(
  edges_u : Array[Int],
  edges_v : Array[Int],
  edges_tri : Array[Int],
  edges_third : Array[Int],
  u : Int,
  v : Int,
  w : Int,
  tri_idx : Int,
) -> Unit {
  if u < v {
    edges_u.push(u)
    edges_v.push(v)
  } else {
    edges_u.push(v)
    edges_v.push(u)
  }
  edges_tri.push(tri_idx)
  edges_third.push(w)
}

///|
/// Clip the perpendicular-bisector ray of Delaunay edge `(pa, pb)`
/// starting at circumcenter `cc` and pointing away from the third
/// triangle vertex `pc` to the supplied `bbox`. Returns the boundary
/// intersection coord, or `None` when the ray never enters `bbox`.
fn clip_ray_to_bbox(
  cc : @type.Coord,
  pa : @type.Coord,
  pb : @type.Coord,
  pc : @type.Coord,
  bbox : @type.Rect,
) -> @type.Coord? {
  // Direction along the perpendicular bisector of (pa, pb).
  let mut dx = -(pb.y() - pa.y())
  let mut dy = pb.x() - pa.x()
  // Midpoint of the Delaunay edge — lies on the bisector together
  // with `cc`.
  let mx = (pa.x() + pb.x()) / 2.0
  let my = (pa.y() + pb.y()) / 2.0
  // If `dir` happens to point toward the interior vertex `pc`, flip
  // it so the ray heads outward (away from the triangle).
  if dx * (pc.x() - mx) + dy * (pc.y() - my) > 0.0 {
    dx = -dx
    dy = -dy
  }
  let min_x = bbox.min().x()
  let max_x = bbox.max().x()
  let min_y = bbox.min().y()
  let max_y = bbox.max().y()
  let eps = 1.0e-9
  let mut best_t = -1.0
  if dx != 0.0 {
    let t1 = (min_x - cc.x()) / dx
    let y1 = cc.y() + t1 * dy
    if t1 > 0.0 && y1 >= min_y - eps && y1 <= max_y + eps {
      if best_t < 0.0 || t1 < best_t {
        best_t = t1
      }
    }
    let t2 = (max_x - cc.x()) / dx
    let y2 = cc.y() + t2 * dy
    if t2 > 0.0 && y2 >= min_y - eps && y2 <= max_y + eps {
      if best_t < 0.0 || t2 < best_t {
        best_t = t2
      }
    }
  }
  if dy != 0.0 {
    let t3 = (min_y - cc.y()) / dy
    let x3 = cc.x() + t3 * dx
    if t3 > 0.0 && x3 >= min_x - eps && x3 <= max_x + eps {
      if best_t < 0.0 || t3 < best_t {
        best_t = t3
      }
    }
    let t4 = (max_y - cc.y()) / dy
    let x4 = cc.x() + t4 * dx
    if t4 > 0.0 && x4 >= min_x - eps && x4 <= max_x + eps {
      if best_t < 0.0 || t4 < best_t {
        best_t = t4
      }
    }
  }
  if best_t > 0.0 {
    Some(@type.Coord(cc.x() + best_t * dx, cc.y() + best_t * dy))
  } else {
    None
  }
}
