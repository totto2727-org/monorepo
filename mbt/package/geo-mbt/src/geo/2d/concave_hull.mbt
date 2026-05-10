// Concave hull — two complementary algorithms:
//
//   1. `k_nearest_concave_hull` (Moreira-Santos 2007), a k-nearest-
//      neighbour boundary walk backed by the existing R*-tree
//      (`@rtree`). Higher `k` smooths the result toward the convex
//      hull; lower `k` admits more concavity. References:
//      - Moreira & Santos, "Concave Hull: A k-Nearest Neighbours
//        Approach for the Computation of the Region Occupied by a
//        Set of Points",
//        https://pdfs.semanticscholar.org/2397/17005c3ebd5d6a42fc833daf97a0edee1ce4.pdf
//      - georust/geo `algorithm/k_nearest_concave_hull.rs`.
//
//   2. `delaunay_concave_hull`, the boundary of the Delaunay
//      triangulation after trimming triangles whose longest edge
//      exceeds `concavity * mean_edge_length`. Sits on top of the
//      ms-27 `delaunay_triangulation` and follows the
//      Edelsbrunner-style "alpha shape" idea (a discrete trim
//      threshold instead of a smooth alpha radius).
//
// Both return a closed `LineString` (first == last) or `None` for
// degenerate input (fewer than 3 distinct points / collinear / the
// underlying Delaunay triangulation empty).
//
// Limitations / deferred:
//
//   - k-NN: duplicate points are deduplicated by exact equality only;
//     near-duplicates within a tiny epsilon are kept distinct.
//   - k-NN: candidate angles use the upstream pseudo-angle hack rather
//     than `@math.atan2`, so the ordering matches the upstream port
//     bit-for-bit but trades exact angular comparison for speed.
//   - Delaunay variant: the boundary walker assumes the trimmed shape
//     has a single connected component with a manifold boundary
//     (every boundary vertex has degree 2). For pathological multi-
//     component results only one component's ring is returned.
//   - The Delaunay variant inherits the brute-force O(n²) sweep and
//     non-adaptive `incircle` predicate from `delaunay.mbt`.

// MARK: --- k-NN concave hull (Moreira-Santos 2007) -------------------

///|
/// Compute the concave hull of a point set using the k-nearest-neighbour
/// algorithm of Moreira & Santos (2007).
///
/// `k` controls concavity: larger values approach the convex hull,
/// smaller values follow the input more closely. Values below 3 are
/// clamped to 3 (the minimum that admits a non-degenerate boundary
/// walk). When the algorithm cannot complete with a given `k` it
/// retries with `max(k + 1, ceil(k * 1.5))`; once `k >= n` the convex
/// hull is returned as a fallback.
///
/// Returns the concave hull as a closed `LineString` (first == last),
/// or `None` when the input has fewer than 3 distinct points or all
/// points are collinear.
pub fn k_nearest_concave_hull(
  points : Array[@type.Point],
  k : Int,
) -> @type.LineString? {
  let raw_coords : Array[@type.Coord] = []
  for i = 0; i < points.length(); i = i + 1 {
    raw_coords.push(points[i].coord())
  }
  let coords = concave_hull_dedupe(raw_coords)
  let n = coords.length()
  if n < 3 {
    return None
  }
  if concave_hull_all_collinear(coords) {
    return None
  }
  let k_init = if k < 3 { 3 } else { k }
  k_nearest_concave_hull_inner(coords, k_init)
}

///|
/// Builds the indexed dataset once and drives the retry loop until
/// either a successful hull is produced or `k >= n` (in which case the
/// convex hull is returned).
fn k_nearest_concave_hull_inner(
  coords : Array[@type.Coord],
  k_init : Int,
) -> @type.LineString? {
  let n = coords.length()
  let entries : Array[@rtree.Entry[Int]] = []
  for i = 0; i < n; i = i + 1 {
    entries.push(@rtree.Entry(@type.Rect::Rect(coords[i], coords[i]), i))
  }
  let tree = @rtree.RTree::bulk_load(entries)
  let mut k = k_init
  while k < n {
    match try_build_concave_hull(coords, tree, k) {
      Some(hull) => return Some(hull)
      None => {
        let grown = k * 3 / 2
        k = if grown > k + 1 { grown } else { k + 1 }
      }
    }
  }
  Some(convex_hull_of_coords(coords))
}

///|
/// One attempt at the Moreira-Santos boundary walk for a fixed `k`.
/// Returns `None` whenever the walk gets stuck (no non-intersecting
/// candidate / dataset exhausted before closing / the resulting hull
/// fails to cover all input points), so the caller can retry with a
/// larger `k`.
fn try_build_concave_hull(
  coords : Array[@type.Coord],
  tree : @rtree.RTree[Int],
  k : Int,
) -> @type.LineString? {
  let n = coords.length()
  let claimed : Array[Bool] = Array::make(n, false)
  let first_idx = concave_hull_first_point_index(coords)
  let first_coord = coords[first_idx]
  let hull : Array[@type.Coord] = [first_coord]
  let mut current_idx = first_idx
  let mut prev_coord = first_coord
  claimed[first_idx] = true
  let mut step = 2
  let mut closed = false
  let max_steps = n * 3 + 8
  while !closed && step <= max_steps {
    if step == 5 {
      claimed[first_idx] = false
    }
    let current_coord = coords[current_idx]
    let candidates = get_k_nearest_unclaimed(tree, claimed, current_coord, k)
    if candidates.length() == 0 {
      return None
    }
    sort_indices_by_angle(candidates, coords, current_coord, prev_coord)
    let mut selected = -1
    for i = 0; i < candidates.length(); i = i + 1 {
      let cand_coord = coords[candidates[i]]
      if !concave_hull_new_edge_intersects(hull, current_coord, cand_coord) {
        selected = candidates[i]
        break
      }
    }
    if selected < 0 {
      return None
    }
    let selected_coord = coords[selected]
    prev_coord = current_coord
    current_idx = selected
    hull.push(selected_coord)
    claimed[selected] = true
    step = step + 1
    if selected == first_idx {
      closed = true
    }
  }
  if !closed {
    return None
  }
  let polygon = @type.Polygon::Polygon(@type.LineString::LineString(hull), [])
  for i = 0; i < n; i = i + 1 {
    if !claimed[i] && !covers_polygon_coord(polygon, coords[i]) {
      return None
    }
  }
  Some(@type.LineString::LineString(hull))
}

///|
/// Drop exact duplicates while preserving insertion order. O(n²) — fine
/// for the small to mid sized inputs the concave hull is meant for.
fn concave_hull_dedupe(coords : Array[@type.Coord]) -> Array[@type.Coord] {
  let result : Array[@type.Coord] = []
  for i = 0; i < coords.length(); i = i + 1 {
    let c = coords[i]
    let mut seen = false
    for j = 0; j < result.length() && !seen; j = j + 1 {
      if result[j] == c {
        seen = true
      }
    }
    if !seen {
      result.push(c)
    }
  }
  result
}

///|
/// `true` when every point lies on a single straight line. Uses
/// `@robust.orient2d` on the first two distinct points so collinearity
/// is decided exactly.
fn concave_hull_all_collinear(points : Array[@type.Coord]) -> Bool {
  let n = points.length()
  if n < 3 {
    return true
  }
  let mut j = 1
  while j < n && points[j] == points[0] {
    j = j + 1
  }
  if j >= n {
    return true
  }
  for k = j + 1; k < n; k = k + 1 {
    if @robust.orient2d(points[0], points[j], points[k]) != 0.0 {
      return false
    }
  }
  true
}

///|
/// Index of the lexicographically lowest point (smallest `y`, ties
/// broken by smallest `x`). This anchors the boundary walk on a point
/// guaranteed to be on the convex hull.
fn concave_hull_first_point_index(points : Array[@type.Coord]) -> Int {
  let mut idx = 0
  for i = 1; i < points.length(); i = i + 1 {
    let p = points[i]
    let best = points[idx]
    if p.y() < best.y() || (p.y() == best.y() && p.x() < best.x()) {
      idx = i
    }
  }
  idx
}

///|
/// O(1) replacement for `atan2` that preserves angular ordering.
/// Returns a value in `[0, 4)` increasing counterclockwise.
fn concave_hull_pseudo_angle(dx : Double, dy : Double) -> Double {
  if dx == 0.0 && dy == 0.0 {
    return 0.0
  }
  let p = dx / (dx.abs() + dy.abs())
  if dy < 0.0 {
    3.0 + p
  } else {
    1.0 - p
  }
}

///|
/// Sort `indices` in place by counterclockwise angle from the
/// `current → prev` back-direction, *largest first*. The biggest CCW
/// rotation from "behind" corresponds to the largest left-hand turn —
/// exactly what the Moreira-Santos walk wants.
fn sort_indices_by_angle(
  indices : Array[Int],
  coords : Array[@type.Coord],
  current : @type.Coord,
  prev : @type.Coord,
) -> Unit {
  let base = concave_hull_pseudo_angle(
    prev.x() - current.x(),
    prev.y() - current.y(),
  )
  indices.sort_by(fn(a, b) {
    let ca = coords[a]
    let cb = coords[b]
    let mut angle_a = concave_hull_pseudo_angle(
        ca.x() - current.x(),
        ca.y() - current.y(),
      ) -
      base
    if angle_a < 0.0 {
      angle_a = angle_a + 4.0
    }
    let mut angle_b = concave_hull_pseudo_angle(
        cb.x() - current.x(),
        cb.y() - current.y(),
      ) -
      base
    if angle_b < 0.0 {
      angle_b = angle_b + 4.0
    }
    if angle_a > angle_b {
      -1
    } else if angle_a < angle_b {
      1
    } else {
      0
    }
  })
}

///|
/// The first `k` indices ordered by ascending Euclidean distance from
/// `pt` whose `claimed` slot is still `false`. Skipped indices are
/// passed over without being counted.
fn get_k_nearest_unclaimed(
  tree : @rtree.RTree[Int],
  claimed : Array[Bool],
  pt : @type.Coord,
  k : Int,
) -> Array[Int] {
  let all_nearest = tree.nearest_neighbors(pt, None)
  let result : Array[Int] = []
  for i = 0; i < all_nearest.length() && result.length() < k; i = i + 1 {
    let idx = all_nearest[i]
    if !claimed[idx] {
      result.push(idx)
    }
  }
  result
}

///|
/// `true` iff the new edge `(start, end)` intersects any segment of
/// `hull` other than the most recent (which shares its endpoint with
/// `start`). Closing back to the first hull vertex is treated as
/// non-intersection so the loop can terminate.
fn concave_hull_new_edge_intersects(
  hull : Array[@type.Coord],
  start : @type.Coord,
  end : @type.Coord,
) -> Bool {
  let n = hull.length()
  if n == 0 {
    return false
  }
  if end == hull[0] {
    return false
  }
  let new_line = @type.Line::Line(start, end)
  // The "linestring" we test against is `hull[0..n-1]`, dropping the
  // last entry (= `start`). Its segments are `(hull[i], hull[i+1])`
  // for `i` in `[0, n-3]`.
  for i = 0; i + 2 < n; i = i + 1 {
    let segment = @type.Line::Line(hull[i], hull[i + 1])
    if intersects_line_line(segment, new_line) {
      return true
    }
  }
  false
}

// MARK: --- Delaunay-trim concave hull -------------------------------

///|
/// Compute the concave hull of a point set by trimming long edges
/// from the Delaunay triangulation. `concavity` is the trim
/// multiplier: triangulation edges longer than
/// `concavity * mean_edge_length` are removed and the boundary of the
/// surviving triangle set is returned. `concavity = +inf` keeps every
/// triangle (= convex hull); smaller values follow the input more
/// closely. Values `<= 0` cause every triangle to be removed and
/// return `None`.
///
/// Returns a closed `LineString` (first == last) or `None` when the
/// underlying Delaunay triangulation is empty (fewer than 3 points
/// or all collinear), every triangle is trimmed, or the boundary
/// walker fails to assemble a single ring.
pub fn delaunay_concave_hull(
  points : Array[@type.Coord],
  concavity : Double,
) -> @type.LineString? {
  match delaunay_triangulation(points) {
    None => None
    Some(triangles) => {
      let mut total_len = 0.0
      let mut count = 0
      for i = 0; i < triangles.length(); i = i + 1 {
        let t = triangles[i]
        total_len = total_len +
          concave_hull_edge_length(points[t.a], points[t.b]) +
          concave_hull_edge_length(points[t.b], points[t.c]) +
          concave_hull_edge_length(points[t.c], points[t.a])
        count = count + 3
      }
      if count == 0 {
        return None
      }
      let mean_len = total_len / count.to_double()
      let threshold = concavity * mean_len
      let kept : Array[DelaunayTriangle] = []
      for i = 0; i < triangles.length(); i = i + 1 {
        let t = triangles[i]
        let l_ab = concave_hull_edge_length(points[t.a], points[t.b])
        let l_bc = concave_hull_edge_length(points[t.b], points[t.c])
        let l_ca = concave_hull_edge_length(points[t.c], points[t.a])
        if l_ab <= threshold && l_bc <= threshold && l_ca <= threshold {
          kept.push(t)
        }
      }
      if kept.length() == 0 {
        return None
      }
      let edges_u : Array[Int] = []
      let edges_v : Array[Int] = []
      for i = 0; i < kept.length(); i = i + 1 {
        let t = kept[i]
        push_concave_edge(edges_u, edges_v, t.a, t.b)
        push_concave_edge(edges_u, edges_v, t.b, t.c)
        push_concave_edge(edges_u, edges_v, t.c, t.a)
      }
      let boundary_u : Array[Int] = []
      let boundary_v : Array[Int] = []
      for k = 0; k < edges_u.length(); k = k + 1 {
        let mut occurrences = 0
        for l = 0; l < edges_u.length(); l = l + 1 {
          if edges_u[k] == edges_u[l] && edges_v[k] == edges_v[l] {
            occurrences = occurrences + 1
          }
        }
        if occurrences == 1 {
          boundary_u.push(edges_u[k])
          boundary_v.push(edges_v[k])
        }
      }
      if boundary_u.length() < 3 {
        return None
      }
      walk_concave_boundary_ring(boundary_u, boundary_v, points)
    }
  }
}

///|
fn concave_hull_edge_length(a : @type.Coord, b : @type.Coord) -> Double {
  let dx = a.x() - b.x()
  let dy = a.y() - b.y()
  (dx * dx + dy * dy).sqrt()
}

///|
/// Append the undirected edge `(u, v)` in normalised form (smaller
/// index first) so two triangles sharing the edge produce matching
/// records.
fn push_concave_edge(
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
/// Walk the boundary edge graph into a single closed ring. Assumes
/// every boundary vertex has degree 2; for non-manifold inputs we
/// follow the first available neighbour at each step, which still
/// returns *some* cycle if one exists but not necessarily the
/// "outer" ring.
fn walk_concave_boundary_ring(
  boundary_u : Array[Int],
  boundary_v : Array[Int],
  points : Array[@type.Coord],
) -> @type.LineString? {
  let m = boundary_u.length()
  let mut max_idx = -1
  for i = 0; i < m; i = i + 1 {
    if boundary_u[i] > max_idx {
      max_idx = boundary_u[i]
    }
    if boundary_v[i] > max_idx {
      max_idx = boundary_v[i]
    }
  }
  let n = max_idx + 1
  let adjacency : Array[Array[Int]] = []
  for i = 0; i < n; i = i + 1 {
    let inner : Array[Int] = []
    adjacency.push(inner)
  }
  for i = 0; i < m; i = i + 1 {
    adjacency[boundary_u[i]].push(boundary_v[i])
    adjacency[boundary_v[i]].push(boundary_u[i])
  }
  let mut start = -1
  for i = 0; i < n && start < 0; i = i + 1 {
    if adjacency[i].length() >= 2 {
      start = i
    }
  }
  if start < 0 {
    return None
  }
  let ring : Array[Int] = [start]
  let mut prev = -1
  let mut curr = start
  let max_steps = m + 1
  let mut step = 0
  let mut closed = false
  while step < max_steps && !closed {
    step = step + 1
    let nbrs = adjacency[curr]
    let mut next = -1
    for i = 0; i < nbrs.length(); i = i + 1 {
      if nbrs[i] != prev {
        next = nbrs[i]
        break
      }
    }
    if next < 0 {
      return None
    }
    if next == start {
      ring.push(start)
      closed = true
    } else {
      ring.push(next)
      prev = curr
      curr = next
    }
  }
  if !closed {
    return None
  }
  let coord_ring : Array[@type.Coord] = Array::makei(ring.length(), fn(i) {
    points[ring[i]]
  })
  Some(@type.LineString::LineString(coord_ring))
}
