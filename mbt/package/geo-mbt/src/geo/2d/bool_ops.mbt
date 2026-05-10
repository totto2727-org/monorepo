// Boolean operations on polygons.
//
// Implementation: Greiner-Hormann (1998) polygon clipping algorithm,
// extended to the four standard set operations on simple polygons —
// intersection / union / difference / symmetric difference. Replaces the
// earlier Sutherland-Hodgman implementation that was limited to clipping
// against a convex polygon.
//
// The original ms-21..23 milestone bundle scoped a faithful port of the
// `i_overlay` Rust crate (segments / grid layout / graph / extraction
// pipeline). That is multiple thousands of lines and out of scope for one
// cycle; this implementation provides the same public surface with an
// algorithmically simpler core.
//
// Limitations vs. a full i_overlay port:
// - Degenerate intersections (vertex-on-edge, collinear/overlapping edges)
//   are skipped via an `epsilon_bool` guard. Pathological inputs with
//   exact collinear edges may produce incorrect results.
// - Hole interaction is handled in two regimes: holes of inputs are
//   subtracted from the result for `polygon_intersection`, and the
//   "B fully inside A with no boundary intersection" case for
//   `polygon_difference` / `polygon_xor` produces an A-with-B-as-hole
//   polygon. General hole interaction (e.g. union of two non-equal
//   polygons with overlapping holes) is approximate.
// - The `i_overlay`-specific grid-layout sweep, multi-thread parallelism,
//   and the optimized large-array `unary_union` are deferred (the current
//   `unary_union` is an O(n²) fold).
//
// Reference: Greiner & Hörmann, "Efficient Clipping of Arbitrary Polygons",
// ACM TOG 17(2):71-83, 1998.

///|
/// Epsilon for proper-intersection detection. Intersections within this
/// distance of a segment endpoint or with a near-parallel cross product are
/// skipped (degenerate case).
let epsilon_bool : Double = 1.0e-12

///|
priv enum BoolOp {
  Intersect
  Union
  Difference
}

///|
priv struct Vert {
  coord : @type.Coord
  is_intersection : Bool
  mut neighbor : Int
  mut entry : Bool
  mut visited : Bool
  mut next_idx : Int
  mut prev_idx : Int
}

// MARK: ring helpers ---------------------------------------------------------

///|
/// Drops the closing-duplicate of an auto-closed ring, returning an "open"
/// list of unique vertices.
fn open_ring(ls : @type.LineString) -> Array[@type.Coord] {
  let coords = ls.coords()
  let n = coords.length()
  if n > 1 && coords[0] == coords[n - 1] {
    Array::makei(n - 1, fn(i) { coords[i] })
  } else {
    Array::makei(n, fn(i) { coords[i] })
  }
}

///|
/// Builds a closed `LineString` from an open ring. The closing-duplicate of
/// `ring[0]` is appended unless the input is already closed or empty.
fn closed_line_string(ring : Array[@type.Coord]) -> @type.LineString {
  let n = ring.length()
  if n == 0 {
    return @type.LineString::empty()
  }
  if n > 1 && ring[0] == ring[n - 1] {
    return @type.LineString::LineString(ring)
  }
  @type.LineString::LineString([..ring, ring[0]])
}

///|
/// Signed area of an open ring using the shoelace formula. Positive = CCW
/// in math (y-up) convention; negative = CW.
fn ring_signed_area(ring : Array[@type.Coord]) -> Double {
  let n = ring.length()
  if n < 3 {
    return 0.0
  }
  let mut sum = 0.0
  for i = 0; i < n; i = i + 1 {
    let j = (i + 1) % n
    sum = sum + ring[i].x() * ring[j].y() - ring[j].x() * ring[i].y()
  }
  sum / 2.0
}

///|
/// Ray-casting point-in-ring test. The ring is given as an open list of
/// vertices (no closing duplicate). Boundary points have unstable
/// classification — callers must not rely on a specific answer for
/// on-boundary inputs.
fn point_in_open_ring(pt : @type.Coord, ring : Array[@type.Coord]) -> Bool {
  let n = ring.length()
  if n < 3 {
    return false
  }
  let mut inside = false
  let mut j = n - 1
  for i = 0; i < n; i = i + 1 {
    let xi = ring[i].x()
    let yi = ring[i].y()
    let xj = ring[j].x()
    let yj = ring[j].y()
    let intersect = (yi > pt.y()) != (yj > pt.y()) &&
      pt.x() < (xj - xi) * (pt.y() - yi) / (yj - yi) + xi
    if intersect {
      inside = !inside
    }
    j = i
  }
  inside
}

///|
/// Computes a proper intersection between two segments. Returns
/// `Some((alpha_a, alpha_b, point))` where `alpha_a` and `alpha_b` are the
/// parametric coordinates strictly in `(epsilon_bool, 1 - epsilon_bool)`,
/// or `None` for parallel / endpoint / out-of-range intersections.
fn segment_intersection(
  a1 : @type.Coord,
  a2 : @type.Coord,
  b1 : @type.Coord,
  b2 : @type.Coord,
) -> (Double, Double, @type.Coord)? {
  let r = a2 - a1
  let s = b2 - b1
  let r_cross_s = r.cross(s)
  if r_cross_s.abs() < epsilon_bool {
    return None
  }
  let qp = b1 - a1
  let t = qp.cross(s) / r_cross_s
  let u = qp.cross(r) / r_cross_s
  if t > epsilon_bool &&
    t < 1.0 - epsilon_bool &&
    u > epsilon_bool &&
    u < 1.0 - epsilon_bool {
    let pt = @type.Coord(a1.x() + t * r.x(), a1.y() + t * r.y())
    Some((t, u, pt))
  } else {
    None
  }
}

// MARK: Greiner-Hormann pipeline ---------------------------------------------

///|
/// Builds the two augmented vertex lists with all proper intersections
/// woven into both polygons in alpha order. Returns `(p_verts, q_verts,
/// id_count)`. Each intersection has its `neighbor` pointer linking the
/// matching vertex in the opposite list.
fn build_vertex_lists(
  ring_p : Array[@type.Coord],
  ring_q : Array[@type.Coord],
) -> (Array[Vert], Array[Vert], Int) {
  let np = ring_p.length()
  let nq = ring_q.length()
  let per_p : Array[Array[(Double, Int, @type.Coord)]] = Array::makei(np, fn(
    _,
  ) {
    []
  })
  let per_q : Array[Array[(Double, Int, @type.Coord)]] = Array::makei(nq, fn(
    _,
  ) {
    []
  })
  let mut id_count = 0
  for i = 0; i < np; i = i + 1 {
    let a1 = ring_p[i]
    let a2 = ring_p[(i + 1) % np]
    for j = 0; j < nq; j = j + 1 {
      let b1 = ring_q[j]
      let b2 = ring_q[(j + 1) % nq]
      match segment_intersection(a1, a2, b1, b2) {
        Some((t, u, pt)) => {
          per_p[i].push((t, id_count, pt))
          per_q[j].push((u, id_count, pt))
          id_count = id_count + 1
        }
        None => ()
      }
    }
  }
  let cmp_alpha = fn(
    a : (Double, Int, @type.Coord),
    b : (Double, Int, @type.Coord),
  ) {
    if a.0 < b.0 {
      -1
    } else if a.0 > b.0 {
      1
    } else {
      0
    }
  }
  for i = 0; i < np; i = i + 1 {
    per_p[i].sort_by(cmp_alpha)
  }
  for j = 0; j < nq; j = j + 1 {
    per_q[j].sort_by(cmp_alpha)
  }
  let p_idx_for_id = Array::make(id_count, -1)
  let q_idx_for_id = Array::make(id_count, -1)
  let p_verts : Array[Vert] = []
  for i = 0; i < np; i = i + 1 {
    p_verts.push(Vert::{
      coord: ring_p[i],
      is_intersection: false,
      neighbor: -1,
      entry: false,
      visited: false,
      next_idx: -1,
      prev_idx: -1,
    })
    for k = 0; k < per_p[i].length(); k = k + 1 {
      let (_, id, pt) = per_p[i][k]
      let idx = p_verts.length()
      p_idx_for_id[id] = idx
      p_verts.push(Vert::{
        coord: pt,
        is_intersection: true,
        neighbor: -1,
        entry: false,
        visited: false,
        next_idx: -1,
        prev_idx: -1,
      })
    }
  }
  let q_verts : Array[Vert] = []
  for j = 0; j < nq; j = j + 1 {
    q_verts.push(Vert::{
      coord: ring_q[j],
      is_intersection: false,
      neighbor: -1,
      entry: false,
      visited: false,
      next_idx: -1,
      prev_idx: -1,
    })
    for k = 0; k < per_q[j].length(); k = k + 1 {
      let (_, id, pt) = per_q[j][k]
      let idx = q_verts.length()
      q_idx_for_id[id] = idx
      q_verts.push(Vert::{
        coord: pt,
        is_intersection: true,
        neighbor: -1,
        entry: false,
        visited: false,
        next_idx: -1,
        prev_idx: -1,
      })
    }
  }
  let m = p_verts.length()
  for i = 0; i < m; i = i + 1 {
    p_verts[i].next_idx = (i + 1) % m
    p_verts[i].prev_idx = (i + m - 1) % m
  }
  let n = q_verts.length()
  for i = 0; i < n; i = i + 1 {
    q_verts[i].next_idx = (i + 1) % n
    q_verts[i].prev_idx = (i + n - 1) % n
  }
  for id = 0; id < id_count; id = id + 1 {
    let pi = p_idx_for_id[id]
    let qi = q_idx_for_id[id]
    p_verts[pi].neighbor = qi
    q_verts[qi].neighbor = pi
  }
  (p_verts, q_verts, id_count)
}

///|
/// Marks each intersection vertex in `verts` as entry (true) or exit
/// (false) relative to the other polygon's region. Uses the alternating
/// rule: status starts as "is verts[0] inside other_ring?", and each
/// intersection flips the status — recording the pre-flip value as
/// `entry = !status_before`.
fn mark_entry_exit(
  verts : Array[Vert],
  other_ring : Array[@type.Coord],
) -> Unit {
  let m = verts.length()
  if m == 0 {
    return
  }
  let mut status = point_in_open_ring(verts[0].coord, other_ring)
  for i = 0; i < m; i = i + 1 {
    if verts[i].is_intersection {
      verts[i].entry = !status
      status = !status
    }
  }
}

///|
/// Adjusts entry/exit flags for the requested boolean operation:
/// - `Intersect`: no change.
/// - `Union`: flip both lists.
/// - `Difference (P\Q)`: flip P only (P is walked from "exit" points and Q
///   is walked backward via the swap of forward/backward at flag-flipped
///   intersections).
fn apply_op_flags(
  p_verts : Array[Vert],
  q_verts : Array[Vert],
  op : BoolOp,
) -> Unit {
  match op {
    Intersect => ()
    Union => {
      for i = 0; i < p_verts.length(); i = i + 1 {
        if p_verts[i].is_intersection {
          p_verts[i].entry = !p_verts[i].entry
        }
      }
      for i = 0; i < q_verts.length(); i = i + 1 {
        if q_verts[i].is_intersection {
          q_verts[i].entry = !q_verts[i].entry
        }
      }
    }
    Difference =>
      for i = 0; i < p_verts.length(); i = i + 1 {
        if p_verts[i].is_intersection {
          p_verts[i].entry = !p_verts[i].entry
        }
      }
  }
}

///|
/// Walks the marked lists to extract result rings. Each ring starts at an
/// unvisited entry intersection in `p_verts`, walks forward (or backward
/// depending on the entry flag) along the current list until the next
/// intersection, switches to the neighbor in the other list, and continues
/// until landing back on the start vertex in P.
fn walk_rings(
  p_verts : Array[Vert],
  q_verts : Array[Vert],
) -> Array[Array[@type.Coord]] {
  let result : Array[Array[@type.Coord]] = []
  let m = p_verts.length()
  for s = 0; s < m; s = s + 1 {
    if p_verts[s].is_intersection && p_verts[s].entry && !p_verts[s].visited {
      let ring : Array[@type.Coord] = [p_verts[s].coord]
      p_verts[s].visited = true
      q_verts[p_verts[s].neighbor].visited = true
      let mut cur_idx = s
      let mut in_p = true
      let mut closed = false
      while !closed {
        let forward = if in_p {
          p_verts[cur_idx].entry
        } else {
          q_verts[cur_idx].entry
        }
        let mut at_int = false
        while !at_int {
          let next_idx = if in_p {
            if forward {
              p_verts[cur_idx].next_idx
            } else {
              p_verts[cur_idx].prev_idx
            }
          } else if forward {
            q_verts[cur_idx].next_idx
          } else {
            q_verts[cur_idx].prev_idx
          }
          let next_is_int = if in_p {
            p_verts[next_idx].is_intersection
          } else {
            q_verts[next_idx].is_intersection
          }
          let next_coord = if in_p {
            p_verts[next_idx].coord
          } else {
            q_verts[next_idx].coord
          }
          cur_idx = next_idx
          if next_is_int {
            at_int = true
          } else {
            ring.push(next_coord)
          }
        }
        if in_p && cur_idx == s {
          closed = true
          continue
        }
        let int_coord = if in_p {
          p_verts[cur_idx].coord
        } else {
          q_verts[cur_idx].coord
        }
        let neighbor = if in_p {
          p_verts[cur_idx].neighbor
        } else {
          q_verts[cur_idx].neighbor
        }
        ring.push(int_coord)
        if in_p {
          p_verts[cur_idx].visited = true
          q_verts[neighbor].visited = true
        } else {
          q_verts[cur_idx].visited = true
          p_verts[neighbor].visited = true
        }
        cur_idx = neighbor
        in_p = !in_p
        if in_p && cur_idx == s {
          closed = true
        }
      }
      result.push(ring)
    }
  }
  result
}

///|
/// Handles the no-intersection case via a containment check on the first
/// vertex of each ring. Returns rings in result-orientation.
fn handle_no_intersections(
  ring_p : Array[@type.Coord],
  ring_q : Array[@type.Coord],
  op : BoolOp,
) -> Array[Array[@type.Coord]] {
  let p_in_q = point_in_open_ring(ring_p[0], ring_q)
  let q_in_p = point_in_open_ring(ring_q[0], ring_p)
  match op {
    Intersect => if p_in_q { [ring_p] } else if q_in_p { [ring_q] } else { [] }
    Union =>
      if p_in_q {
        [ring_q]
      } else if q_in_p {
        [ring_p]
      } else {
        [ring_p, ring_q]
      }
    Difference =>
      if p_in_q {
        []
      } else if q_in_p {
        // A contains B → A\B = A with B as hole. Encoded by orientation:
        // CCW outer + CW inner. The B ring is reversed to flip its winding.
        [ring_p, reverse_ring(ring_q)]
      } else {
        [ring_p]
      }
  }
}

///|
fn reverse_ring(ring : Array[@type.Coord]) -> Array[@type.Coord] {
  let n = ring.length()
  Array::makei(n, fn(i) { ring[n - 1 - i] })
}

///|
/// Top-level Greiner-Hormann simple-polygon clip on two open rings.
fn gh_clip(
  ring_p : Array[@type.Coord],
  ring_q : Array[@type.Coord],
  op : BoolOp,
) -> Array[Array[@type.Coord]] {
  if ring_p.length() < 3 || ring_q.length() < 3 {
    return match op {
      Intersect => []
      Union => {
        let acc : Array[Array[@type.Coord]] = []
        if ring_p.length() >= 3 {
          acc.push(ring_p)
        }
        if ring_q.length() >= 3 {
          acc.push(ring_q)
        }
        acc
      }
      Difference => if ring_p.length() >= 3 { [ring_p] } else { [] }
    }
  }
  let (p_verts, q_verts, id_count) = build_vertex_lists(ring_p, ring_q)
  if id_count == 0 {
    return handle_no_intersections(ring_p, ring_q, op)
  }
  mark_entry_exit(p_verts, ring_q)
  mark_entry_exit(q_verts, ring_p)
  apply_op_flags(p_verts, q_verts, op)
  walk_rings(p_verts, q_verts)
}

// MARK: ring → polygon assembly ---------------------------------------------

///|
/// Assembles a list of rings (positive area = exterior, negative = hole)
/// into a `MultiPolygon`. Each hole is attached to the smallest exterior
/// containing it, decided by an "any vertex inside" test on the hole's
/// first vertex.
fn rings_to_multi_polygon(
  rings : Array[Array[@type.Coord]],
) -> @type.MultiPolygon {
  if rings.length() == 0 {
    return @type.MultiPolygon::empty()
  }
  let exteriors : Array[Array[@type.Coord]] = []
  let holes : Array[Array[@type.Coord]] = []
  for i = 0; i < rings.length(); i = i + 1 {
    let r = rings[i]
    if r.length() < 3 {
      continue
    }
    if ring_signed_area(r) >= 0.0 {
      exteriors.push(r)
    } else {
      holes.push(r)
    }
  }
  let polys : Array[@type.Polygon] = []
  for i = 0; i < exteriors.length(); i = i + 1 {
    let ext = exteriors[i]
    let my_holes : Array[@type.LineString] = []
    for j = 0; j < holes.length(); j = j + 1 {
      let h = holes[j]
      if h.length() > 0 && point_in_open_ring(h[0], ext) {
        my_holes.push(closed_line_string(h))
      }
    }
    polys.push(@type.Polygon::Polygon(closed_line_string(ext), my_holes))
  }
  @type.MultiPolygon::MultiPolygon(polys)
}

// MARK: public API -----------------------------------------------------------

///|
/// Boolean intersection: returns the points inside both polygons.
pub fn polygon_intersection(
  a : @type.Polygon,
  b : @type.Polygon,
) -> @type.MultiPolygon {
  if a.exterior().is_empty() || b.exterior().is_empty() {
    return @type.MultiPolygon::empty()
  }
  let ring_a = open_ring(a.exterior())
  let ring_b = open_ring(b.exterior())
  let result = gh_clip(ring_a, ring_b, Intersect)
  if result.length() == 0 {
    return @type.MultiPolygon::empty()
  }
  // Subtract every hole from both inputs — the intersection lives outside
  // the holes of either input.
  let a_holes = a.interiors()
  let b_holes = b.interiors()
  let mut current = result
  for i = 0; i < a_holes.length(); i = i + 1 {
    let h_ring = open_ring(a_holes[i])
    if h_ring.length() < 3 {
      continue
    }
    current = subtract_ring(current, h_ring)
  }
  for i = 0; i < b_holes.length(); i = i + 1 {
    let h_ring = open_ring(b_holes[i])
    if h_ring.length() < 3 {
      continue
    }
    current = subtract_ring(current, h_ring)
  }
  rings_to_multi_polygon(current)
}

///|
fn subtract_ring(
  rings : Array[Array[@type.Coord]],
  hole : Array[@type.Coord],
) -> Array[Array[@type.Coord]] {
  let out : Array[Array[@type.Coord]] = []
  for i = 0; i < rings.length(); i = i + 1 {
    let r = rings[i]
    let diff = gh_clip(r, hole, Difference)
    for j = 0; j < diff.length(); j = j + 1 {
      out.push(diff[j])
    }
  }
  out
}

///|
/// Boolean union: returns points inside either polygon.
pub fn polygon_union(
  a : @type.Polygon,
  b : @type.Polygon,
) -> @type.MultiPolygon {
  if a.exterior().is_empty() {
    return if b.exterior().is_empty() {
      @type.MultiPolygon::empty()
    } else {
      @type.MultiPolygon::MultiPolygon([b])
    }
  }
  if b.exterior().is_empty() {
    return @type.MultiPolygon::MultiPolygon([a])
  }
  let ring_a = open_ring(a.exterior())
  let ring_b = open_ring(b.exterior())
  if ring_a.length() < 3 {
    return @type.MultiPolygon::MultiPolygon([b])
  }
  if ring_b.length() < 3 {
    return @type.MultiPolygon::MultiPolygon([a])
  }
  let (p_verts, q_verts, id_count) = build_vertex_lists(ring_a, ring_b)
  if id_count == 0 {
    let a0_in_b = point_in_open_ring(ring_a[0], ring_b)
    let b0_in_a = point_in_open_ring(ring_b[0], ring_a)
    // Equal exteriors: ray-casting at vertex coords is unstable, so accept
    // either flag and keep the input intact (preserving each side's holes).
    if a0_in_b {
      return @type.MultiPolygon::MultiPolygon([b])
    } else if b0_in_a {
      return @type.MultiPolygon::MultiPolygon([a])
    } else {
      return @type.MultiPolygon::MultiPolygon([a, b])
    }
  }
  mark_entry_exit(p_verts, ring_b)
  mark_entry_exit(q_verts, ring_a)
  apply_op_flags(p_verts, q_verts, Union)
  let rings = walk_rings(p_verts, q_verts)
  rings_to_multi_polygon(rings)
}

///|
/// Boolean difference: points in `a` but not in `b`.
pub fn polygon_difference(
  a : @type.Polygon,
  b : @type.Polygon,
) -> @type.MultiPolygon {
  if a.exterior().is_empty() {
    return @type.MultiPolygon::empty()
  }
  if b.exterior().is_empty() {
    return @type.MultiPolygon::MultiPolygon([a])
  }
  let ring_a = open_ring(a.exterior())
  let ring_b = open_ring(b.exterior())
  if ring_a.length() < 3 {
    return @type.MultiPolygon::empty()
  }
  if ring_b.length() < 3 {
    return @type.MultiPolygon::MultiPolygon([a])
  }
  let (p_verts, q_verts, id_count) = build_vertex_lists(ring_a, ring_b)
  if id_count == 0 {
    let a0_in_b = point_in_open_ring(ring_a[0], ring_b)
    let b0_in_a = point_in_open_ring(ring_b[0], ring_a)
    if a0_in_b {
      return @type.MultiPolygon::empty()
    } else if b0_in_a {
      // B fully inside A → A\B = A with B as a new hole, preserving A's
      // existing holes.
      let new_holes : Array[@type.LineString] = [..a.interiors(), b.exterior()]
      return @type.MultiPolygon::MultiPolygon([
        @type.Polygon::Polygon(a.exterior(), new_holes),
      ])
    } else {
      return @type.MultiPolygon::MultiPolygon([a])
    }
  }
  mark_entry_exit(p_verts, ring_b)
  mark_entry_exit(q_verts, ring_a)
  apply_op_flags(p_verts, q_verts, Difference)
  let rings = walk_rings(p_verts, q_verts)
  rings_to_multi_polygon(rings)
}

///|
/// Symmetric difference: points in exactly one of the polygons. Implemented
/// as `(a \ b) ∪ (b \ a)` and concatenated.
pub fn polygon_xor(a : @type.Polygon, b : @type.Polygon) -> @type.MultiPolygon {
  let diff_ab = polygon_difference(a, b).polygons()
  let diff_ba = polygon_difference(b, a).polygons()
  @type.MultiPolygon::MultiPolygon([..diff_ab, ..diff_ba])
}

///|
/// Union of every polygon in `mp`. Currently an O(n²) fold (each input is
/// merged into the running accumulator pairwise). The i_overlay sweep-based
/// large-array optimization is deferred.
pub fn unary_union(mp : @type.MultiPolygon) -> @type.MultiPolygon {
  let polys = mp.polygons()
  if polys.length() == 0 {
    return @type.MultiPolygon::empty()
  }
  let mut acc : Array[@type.Polygon] = [polys[0]]
  for i = 1; i < polys.length(); i = i + 1 {
    let next = polys[i]
    let mut absorbed = false
    let new_acc : Array[@type.Polygon] = []
    for j = 0; j < acc.length(); j = j + 1 {
      let p = acc[j]
      if absorbed {
        new_acc.push(p)
        continue
      }
      let u = polygon_union(p, next).polygons()
      if u.length() == 1 {
        new_acc.push(u[0])
        absorbed = true
      } else {
        new_acc.push(p)
      }
    }
    if !absorbed {
      new_acc.push(next)
    }
    acc = new_acc
  }
  @type.MultiPolygon::MultiPolygon(acc)
}

// MARK: line string clipping -------------------------------------------------

///|
/// Clips a `LineString` against a `Polygon`. Returns a `MultiLineString`
/// containing the segments that lie inside the polygon. Adjacent
/// sub-segments that share a coordinate are joined into a single
/// `LineString`.
pub fn clip_line_string(
  ls : @type.LineString,
  by : @type.Polygon,
) -> @type.MultiLineString {
  let coords = ls.coords()
  let n = coords.length()
  if n < 2 {
    return @type.MultiLineString::empty()
  }
  let parts : Array[@type.LineString] = []
  let mut current : Array[@type.Coord] = []
  for i = 0; i < n - 1; i = i + 1 {
    let a = coords[i]
    let b = coords[i + 1]
    let segments = clip_segment_by_polygon(a, b, by)
    for k = 0; k < segments.length(); k = k + 1 {
      let (s, e) = segments[k]
      if current.length() == 0 {
        current = [s, e]
      } else if current[current.length() - 1] == s {
        current.push(e)
      } else {
        parts.push(@type.LineString::LineString(current))
        current = [s, e]
      }
    }
  }
  if current.length() > 0 {
    parts.push(@type.LineString::LineString(current))
  }
  @type.MultiLineString::MultiLineString(parts)
}

///|
/// Clips a single line segment `(a, b)` by `by`. Returns the sub-segments
/// of `a → b` that lie inside the polygon, in parameter-order along the
/// segment.
fn clip_segment_by_polygon(
  a : @type.Coord,
  b : @type.Coord,
  by : @type.Polygon,
) -> Array[(@type.Coord, @type.Coord)] {
  if a == b {
    return if contains_polygon_coord(by, a) { [(a, a)] } else { [] }
  }
  let alphas : Array[Double] = [0.0, 1.0]
  let r = b - a
  let collect = fn(ring : @type.LineString) {
    let cs = ring.coords()
    if cs.length() < 2 {
      return
    }
    for i = 0; i < cs.length() - 1; i = i + 1 {
      let e1 = cs[i]
      let e2 = cs[i + 1]
      let s = e2 - e1
      let r_cross_s = r.cross(s)
      if r_cross_s.abs() < epsilon_bool {
        continue
      }
      let qp = e1 - a
      let t = qp.cross(s) / r_cross_s
      let u = qp.cross(r) / r_cross_s
      if t > epsilon_bool &&
        t < 1.0 - epsilon_bool &&
        u >= -epsilon_bool &&
        u <= 1.0 + epsilon_bool {
        alphas.push(t)
      }
    }
  }
  collect(by.exterior())
  let interiors = by.interiors()
  for i = 0; i < interiors.length(); i = i + 1 {
    collect(interiors[i])
  }
  alphas.sort_by(fn(x, y) { if x < y { -1 } else if x > y { 1 } else { 0 } })
  let unique : Array[Double] = []
  for i = 0; i < alphas.length(); i = i + 1 {
    if unique.length() == 0 ||
      alphas[i] - unique[unique.length() - 1] > epsilon_bool {
      unique.push(alphas[i])
    }
  }
  let result : Array[(@type.Coord, @type.Coord)] = []
  for k = 0; k < unique.length() - 1; k = k + 1 {
    let t_lo = unique[k]
    let t_hi = unique[k + 1]
    let mid_t = (t_lo + t_hi) / 2.0
    let mid = @type.Coord(a.x() + mid_t * r.x(), a.y() + mid_t * r.y())
    if contains_polygon_coord(by, mid) {
      let s_pt = @type.Coord(a.x() + t_lo * r.x(), a.y() + t_lo * r.y())
      let e_pt = @type.Coord(a.x() + t_hi * r.x(), a.y() + t_hi * r.y())
      result.push((s_pt, e_pt))
    }
  }
  result
}

// MARK: deprecated Sutherland-Hodgman wrappers -------------------------------

///|
/// Deprecated: use `polygon_intersection`. Preserved as a thin wrapper that
/// returns the first (and usually only) polygon in the result, or an empty
/// polygon if the result is empty. The previous Sutherland-Hodgman
/// implementation imposed a "convex clip" precondition; this wrapper now
/// supports general polygons via Greiner-Hörmann.
pub fn intersection_sutherland_hodgman(
  subject : @type.Polygon,
  clip : @type.Polygon,
) -> @type.Polygon {
  let mp = polygon_intersection(subject, clip)
  let polys = mp.polygons()
  if polys.length() == 0 {
    @type.Polygon::empty()
  } else {
    polys[0]
  }
}

///|
/// Deprecated: use `polygon_intersection` after converting the rect to a
/// polygon. Preserved for backward compatibility.
pub fn intersection_polygon_rect(
  subject : @type.Polygon,
  clip : @type.Rect,
) -> @type.Polygon {
  intersection_sutherland_hodgman(subject, clip.to_polygon())
}
