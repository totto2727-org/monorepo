// Bowyer-Watson incremental Delaunay triangulation.
//
// References:
// - Wikipedia "Bowyer–Watson algorithm" pseudocode
//   https://en.wikipedia.org/wiki/Bowyer%E2%80%93Watson_algorithm
// - https://github.com/Stoeoef/spade — full DCEL/flip-based reference
//   port (constraints, conforming Delaunay, walk location). Only a
//   viable subset is implemented here per the geo-mbt roadmap (ms-27).
//
// This is a v0.2.0 first cut: the "find bad triangles" sweep is brute
// force (O(n) per insertion, O(n²) total), and the circumcircle test
// uses the existing `@robust.incircle` predicate (Shewchuk's
// non-adaptive fast path — see `robust/incircle.mbt`). The following
// items are deferred to follow-up milestones:
//
//   - DCEL (Doubly Connected Edge List) for O(log n) walk location
//   - Edge constraints / conforming Delaunay
//   - Spatial-index-backed point location for ms-28 (Voronoi) and
//     ms-29 (concave hull)
//   - Adaptive `incircle` for cocircular tie-breaking
//
// The triangulation stores intermediate triangles using a "super-
// triangle" sentinel: indices `[0..n)` reference input points, and
// indices `[n..n+3)` reference three synthetic vertices large enough
// to enclose the input bbox. After every input point is inserted, any
// triangle still touching a sentinel is discarded so the result is the
// triangulation of the input only.

///|
/// One triangle in the triangulation, identified by indices into the
/// original `points` array passed to `delaunay_triangulation`.
pub struct DelaunayTriangle {
  a : Int
  b : Int
  c : Int
} derive(Eq, Debug)

///|
/// Internal triangle that may reference super-triangle vertices via
/// indices `>= n` (where `n = points.length()`).
priv struct InternalTri {
  a : Int
  b : Int
  c : Int
}

///|
/// Compute the Delaunay triangulation of a set of 2D points using the
/// Bowyer-Watson incremental algorithm.
///
/// Returns `Some(triangles)` where each triangle is given as a triple
/// of indices into `points`, in CCW order. Returns `None` when the
/// triangulation is empty: fewer than 3 input points, all points
/// coincident, or all points collinear.
pub fn delaunay_triangulation(
  points : Array[@type.Coord],
) -> Array[DelaunayTriangle]? {
  let n = points.length()
  if n < 3 {
    return None
  }

  // Bounding box of input.
  let mut min_x = points[0].x()
  let mut max_x = points[0].x()
  let mut min_y = points[0].y()
  let mut max_y = points[0].y()
  for i = 1; i < n; i = i + 1 {
    let x = points[i].x()
    let y = points[i].y()
    if x < min_x {
      min_x = x
    }
    if x > max_x {
      max_x = x
    }
    if y < min_y {
      min_y = y
    }
    if y > max_y {
      max_y = y
    }
  }
  let dx = max_x - min_x
  let dy = max_y - min_y
  let dmax = if dx > dy { dx } else { dy }
  // All points coincident — no triangulation.
  if dmax == 0.0 {
    return None
  }

  // Super-triangle. The 20× margin (vs. Wikipedia's 3×) is large
  // enough to guarantee enclosure for narrow / elongated inputs while
  // keeping coordinate magnitudes well within Double range.
  let mid_x = (min_x + max_x) / 2.0
  let mid_y = (min_y + max_y) / 2.0
  let m = dmax * 20.0
  let st0 = @type.Coord(mid_x - m, mid_y - m)
  let st1 = @type.Coord(mid_x + m, mid_y - m)
  let st2 = @type.Coord(mid_x, mid_y + m)

  // Augmented points: indices [0..n) input, [n..n+3) super-triangle.
  let pts : Array[@type.Coord] = []
  for i = 0; i < n; i = i + 1 {
    pts.push(points[i])
  }
  pts.push(st0)
  pts.push(st1)
  pts.push(st2)

  // Initial triangulation = the super-triangle alone (CCW: bl, br, top).
  let mut triangles : Array[InternalTri] = [
    InternalTri::{ a: n, b: n + 1, c: n + 2 },
  ]

  // Insert each input point.
  for i = 0; i < n; i = i + 1 {
    let p = points[i]

    // 1) Find bad triangles (those whose circumcircle contains p).
    let bad : Array[Int] = []
    for j = 0; j < triangles.length(); j = j + 1 {
      let t = triangles[j]
      let pa = pts[t.a]
      let pb = pts[t.b]
      let pc = pts[t.c]
      if @robust.incircle(pa, pb, pc, p) > 0.0 {
        bad.push(j)
      }
    }

    // 2) Polygonal hole boundary = edges that appear exactly once
    //    among the bad triangles.
    let edges_u : Array[Int] = []
    let edges_v : Array[Int] = []
    for j = 0; j < bad.length(); j = j + 1 {
      let t = triangles[bad[j]]
      push_normalized_edge(edges_u, edges_v, t.a, t.b)
      push_normalized_edge(edges_u, edges_v, t.b, t.c)
      push_normalized_edge(edges_u, edges_v, t.c, t.a)
    }
    let boundary_u : Array[Int] = []
    let boundary_v : Array[Int] = []
    for k = 0; k < edges_u.length(); k = k + 1 {
      let mut count = 0
      for l = 0; l < edges_u.length(); l = l + 1 {
        if edges_u[k] == edges_u[l] && edges_v[k] == edges_v[l] {
          count = count + 1
        }
      }
      if count == 1 {
        boundary_u.push(edges_u[k])
        boundary_v.push(edges_v[k])
      }
    }

    // 3) Remove bad triangles. `bad` is built in increasing order, so
    //    walking from the largest index downward keeps surviving
    //    indices stable.
    let next_triangles : Array[InternalTri] = []
    let mut bad_idx = 0
    for j = 0; j < triangles.length(); j = j + 1 {
      if bad_idx < bad.length() && bad[bad_idx] == j {
        bad_idx = bad_idx + 1
      } else {
        next_triangles.push(triangles[j])
      }
    }

    // 4) Add new triangles connecting p (index i) to each boundary
    //    edge in CCW order.
    for k = 0; k < boundary_u.length(); k = k + 1 {
      let u = boundary_u[k]
      let v = boundary_v[k]
      let pu = pts[u]
      let pv = pts[v]
      let o = @robust.orient2d(pu, pv, p)
      if o > 0.0 {
        next_triangles.push(InternalTri::{ a: u, b: v, c: i })
      } else if o < 0.0 {
        next_triangles.push(InternalTri::{ a: v, b: u, c: i })
      }
    }
    triangles = next_triangles
  }

  // Discard triangles that still touch the super-triangle.
  let result : Array[DelaunayTriangle] = []
  for k = 0; k < triangles.length(); k = k + 1 {
    let t = triangles[k]
    if t.a < n && t.b < n && t.c < n {
      result.push(DelaunayTriangle::{ a: t.a, b: t.b, c: t.c })
    }
  }
  if result.length() == 0 {
    return None
  }
  Some(result)
}

///|
/// Append the undirected edge `(u, v)` to `(edges_u, edges_v)` in
/// normalised form (smaller index first) so equality comparisons can
/// be done component-wise.
fn push_normalized_edge(
  edges_u : Array[Int],
  edges_v : Array[Int],
  u : Int,
  v : Int,
) -> Unit {
  if u < v {
    edges_u.push(u)
    edges_v.push(v)
  } else {
    edges_u.push(v)
    edges_v.push(u)
  }
}

///|
/// Convert a `DelaunayTriangle` index list back into actual `Triangle`
/// geometries by indexing into the original `points` array.
pub fn delaunay_triangles_to_geometries(
  points : Array[@type.Coord],
  triangles : Array[DelaunayTriangle],
) -> Array[@type.Triangle] {
  let result : Array[@type.Triangle] = []
  for i = 0; i < triangles.length(); i = i + 1 {
    let t = triangles[i]
    result.push(@type.Triangle::Triangle(points[t.a], points[t.b], points[t.c]))
  }
  result
}
