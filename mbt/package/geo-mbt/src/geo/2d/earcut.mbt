// Polygon triangulation via the Mapbox earcut algorithm. Ported from
// `earcutr` (Rust port of mapbox/earcut).
//
// Strategy: build a circular doubly-linked list of polygon vertices, link
// holes into the outer ring via David Eberly's bridging algorithm, then run
// a 4-pass ear-clipping loop. The Z-order spatial index from the upstream
// algorithm is intentionally skipped — the unhashed `is_ear` path handles
// every input correctly but is O(n^2) per pass instead of O(n log n) for
// large polygons (>80 vertices).
//
// Index 0 of the linked list `nodes` array is a permanent NULL sentinel;
// real nodes start at index 1.

///|
let null_idx : Int = 0

///|
let dim : Int = 2

///|
priv struct Node {
  vertices_index : Int
  x : Double
  y : Double
  mut prev : Int
  mut next : Int
  mut is_steiner : Bool
}

///|
priv struct LinkedLists {
  nodes : Array[Node]
}

///|
fn new_linked_lists() -> LinkedLists {
  let sentinel = Node::{
    vertices_index: 0,
    x: 0.0,
    y: 0.0,
    prev: 0,
    next: 0,
    is_steiner: false,
  }
  LinkedLists::{ nodes: [sentinel] }
}

///|
/// Insert a new node into the doubly-linked list. If `last` is `null_idx`,
/// the new node forms a self-loop (single-element ring). Otherwise the new
/// node is inserted immediately after `last`.
fn insert_node(
  ll : LinkedLists,
  vertices_index : Int,
  x : Double,
  y : Double,
  last : Int,
) -> Int {
  let new_idx = ll.nodes.length()
  let node = Node::{ vertices_index, x, y, prev: 0, next: 0, is_steiner: false }
  if last == null_idx {
    node.prev = new_idx
    node.next = new_idx
  } else {
    let last_next = ll.nodes[last].next
    node.next = last_next
    node.prev = last
    ll.nodes[last_next].prev = new_idx
    ll.nodes[last].next = new_idx
  }
  ll.nodes.push(node)
  new_idx
}

///|
/// Detach a node from the doubly-linked list. The node remains in `nodes`
/// (we don't compact the array), but its prev/next neighbours skip over it.
fn remove_node(ll : LinkedLists, p_idx : Int) -> Unit {
  let pi = ll.nodes[p_idx].prev
  let ni = ll.nodes[p_idx].next
  ll.nodes[pi].next = ni
  ll.nodes[ni].prev = pi
}

///|
/// Shoelace partial: signed area of the slice `vertices[start..end]`
/// treated as a closed ring. Positive = clockwise (in screen / image
/// coordinates) — the algorithm wants the outer ring's signed area to be
/// positive for `clockwise == true`.
fn signed_area_slice(
  vertices : Array[Double],
  start : Int,
  end : Int,
) -> Double {
  if end <= start + dim {
    return 0.0
  }
  let mut sum = 0.0
  let mut j = end - dim
  let mut i = start
  while i < end {
    sum = sum +
      (vertices[j] - vertices[i]) * (vertices[i + 1] + vertices[j + 1])
    j = i
    i = i + dim
  }
  sum
}

///|
/// Whether two nodes have the same (x, y).
fn xy_eq(ll : LinkedLists, a : Int, b : Int) -> Bool {
  ll.nodes[a].x == ll.nodes[b].x && ll.nodes[a].y == ll.nodes[b].y
}

///|
/// Append the slice `vertices[start..end]` as a ring to the linked list. If
/// the ring's actual winding doesn't match `clockwise`, the slice is
/// iterated in reverse so the resulting linked list is always in the
/// requested winding order. Returns `(last_idx, leftmost_idx)` or `None`
/// for invalid input.
fn add_contour(
  ll : LinkedLists,
  vertices : Array[Double],
  start : Int,
  end : Int,
  clockwise : Bool,
) -> (Int, Int)? {
  let n = vertices.length()
  if start > n || end > n || n == 0 {
    return None
  }
  if end < dim || end - dim < start {
    return None
  }
  let mut last_idx = null_idx
  let mut leftmost_idx = null_idx
  let mut contour_minx = @double.infinity
  let area = signed_area_slice(vertices, start, end)
  let forward = clockwise == (area > 0.0)
  if forward {
    let mut i = start
    while i + 1 < end {
      let x = vertices[i]
      let y = vertices[i + 1]
      last_idx = insert_node(ll, i / dim, x, y, last_idx)
      if x < contour_minx {
        contour_minx = x
        leftmost_idx = last_idx
      }
      i = i + dim
    }
  } else {
    let mut i = end - dim
    while i >= start {
      let x = vertices[i]
      let y = vertices[i + 1]
      last_idx = insert_node(ll, i / dim, x, y, last_idx)
      if x < contour_minx {
        contour_minx = x
        leftmost_idx = last_idx
      }
      if i < dim {
        break
      }
      i = i - dim
    }
  }
  if last_idx == null_idx {
    return None
  }
  let next_idx = ll.nodes[last_idx].next
  if xy_eq(ll, last_idx, next_idx) {
    remove_node(ll, last_idx)
    last_idx = ll.nodes[last_idx].next
  }
  Some((last_idx, leftmost_idx))
}

///|
/// Build a doubly-linked list from a single ring of `vertices`.
fn linked_list(
  vertices : Array[Double],
  start : Int,
  end : Int,
  clockwise : Bool,
) -> (LinkedLists, Int)? {
  let ll = new_linked_lists()
  match add_contour(ll, vertices, start, end, clockwise) {
    Some((last, _)) => Some((ll, last))
    None => None
  }
}

///|
/// Signed area of triangle (a, b, c) — positive iff a→b→c is clockwise in
/// screen coordinates. (For CCW triangles in math/standard coords it is
/// negative.)
fn area_of_node_triangle(ll : LinkedLists, a : Int, b : Int, c : Int) -> Double {
  let ax = ll.nodes[a].x
  let ay = ll.nodes[a].y
  let bx = ll.nodes[b].x
  let by = ll.nodes[b].y
  let cx = ll.nodes[c].x
  let cy = ll.nodes[c].y
  (by - ay) * (cx - bx) - (bx - ax) * (cy - by)
}

///|
/// Whether (px, py) lies inside the closed triangle (ax,ay)-(bx,by)-(cx,cy)
/// (all three half-plane sides ≥ 0 — same convention as the upstream).
fn point_in_triangle(
  ax : Double,
  ay : Double,
  bx : Double,
  by : Double,
  cx : Double,
  cy : Double,
  px : Double,
  py : Double,
) -> Bool {
  (cx - px) * (ay - py) - (ax - px) * (cy - py) >= 0.0 &&
  (ax - px) * (by - py) - (bx - px) * (ay - py) >= 0.0 &&
  (bx - px) * (cy - py) - (cx - px) * (by - py) >= 0.0
}

///|
/// Whether the corner (prev, ear, next) is a valid ear of the polygon
/// represented by the linked list — i.e. it is convex (signed area < 0)
/// AND no other reflex node lies inside it.
fn is_ear(ll : LinkedLists, prev : Int, ear : Int, next : Int) -> Bool {
  if area_of_node_triangle(ll, prev, ear, next) >= 0.0 {
    return false
  }
  let ax = ll.nodes[prev].x
  let ay = ll.nodes[prev].y
  let bx = ll.nodes[ear].x
  let by = ll.nodes[ear].y
  let cx = ll.nodes[next].x
  let cy = ll.nodes[next].y
  let stop = prev
  let mut p = ll.nodes[next].next
  while p != stop {
    let pp = ll.nodes[p].prev
    let pn = ll.nodes[p].next
    if point_in_triangle(ax, ay, bx, by, cx, cy, ll.nodes[p].x, ll.nodes[p].y) &&
      area_of_node_triangle(ll, pp, p, pn) >= 0.0 {
      return false
    }
    p = ll.nodes[p].next
  }
  true
}

///|
/// Drop colinear / duplicate vertices in the ring starting at `start`.
/// Walks until either: (a) the ring shrinks to a single self-loop, in
/// which case `null_idx` is returned (or `start` if no nodes were removed
/// when the ring is already a self-loop on entry); or (b) we visit `end`
/// without changes in a full loop. `end` is updated each time `start` is
/// removed so that the caller's continuation point stays valid.
fn filter_points(ll : LinkedLists, start : Int, end_in : Int?) -> Int {
  let n = ll.nodes.length()
  let mut end = match end_in {
    Some(e) => e
    None => start
  }
  if end >= n || start >= n {
    return null_idx
  }
  let mut p = start
  let mut result = null_idx
  while true {
    let mut again = false
    let pn = ll.nodes[p].next
    let p_prev = ll.nodes[p].prev
    if !ll.nodes[p].is_steiner &&
      (xy_eq(ll, p, pn) || area_of_node_triangle(ll, p_prev, p, pn) == 0.0) {
      remove_node(ll, p)
      end = ll.nodes[p].prev
      p = end
      if p == ll.nodes[p].next {
        result = end
        break
      }
      again = true
    } else if p == ll.nodes[p].next {
      result = null_idx
      break
    } else {
      p = ll.nodes[p].next
    }
    if !again && p == end {
      result = end
      break
    }
  }
  result
}

///|
/// Whether the directed segments p1-q1 and p2-q2 cross at an interior
/// point. Endpoint-touch is NOT considered a crossing — except when the two
/// segments are identical / reversed (special case at the top).
fn pseudo_intersects(
  p1x : Double,
  p1y : Double,
  q1x : Double,
  q1y : Double,
  p2x : Double,
  p2y : Double,
  q2x : Double,
  q2y : Double,
) -> Bool {
  let p1_eq_p2 = p1x == p2x && p1y == p2y
  let q1_eq_q2 = q1x == q2x && q1y == q2y
  let p1_eq_q2 = p1x == q2x && p1y == q2y
  let q1_eq_p2 = q1x == p2x && q1y == p2y
  if (p1_eq_p2 && q1_eq_q2) || (p1_eq_q2 && q1_eq_p2) {
    return true
  }
  let a1 = (q1y - p1y) * (p2x - q1x) - (q1x - p1x) * (p2y - q1y)
  let a2 = (q1y - p1y) * (q2x - q1x) - (q1x - p1x) * (q2y - q1y)
  let a3 = (q2y - p2y) * (p1x - q2x) - (q2x - p2x) * (p1y - q2y)
  let a4 = (q2y - p2y) * (q1x - q2x) - (q2x - p2x) * (q1y - q2y)
  (a1 > 0.0) != (a2 > 0.0) && (a3 > 0.0) != (a4 > 0.0)
}

///|
/// Whether the diagonal a-b crosses any edge of the polygon.
fn intersects_polygon(ll : LinkedLists, a : Int, b : Int) -> Bool {
  let avi = ll.nodes[a].vertices_index
  let bvi = ll.nodes[b].vertices_index
  let ax = ll.nodes[a].x
  let ay = ll.nodes[a].y
  let bx = ll.nodes[b].x
  let by = ll.nodes[b].y
  let mut p = a
  let mut result = false
  while true {
    let n = ll.nodes[p].next
    let pvi = ll.nodes[p].vertices_index
    let nvi = ll.nodes[n].vertices_index
    if pvi != avi &&
      nvi != avi &&
      pvi != bvi &&
      nvi != bvi &&
      pseudo_intersects(
        ll.nodes[p].x,
        ll.nodes[p].y,
        ll.nodes[n].x,
        ll.nodes[n].y,
        ax,
        ay,
        bx,
        by,
      ) {
      result = true
      break
    }
    p = n
    if p == a {
      break
    }
  }
  result
}

///|
/// Whether the diagonal a-b is locally inside the polygon at `a`.
fn locally_inside(ll : LinkedLists, a : Int, b : Int) -> Bool {
  let ap = ll.nodes[a].prev
  let an = ll.nodes[a].next
  if area_of_node_triangle(ll, ap, a, an) < 0.0 {
    area_of_node_triangle(ll, a, b, an) >= 0.0 &&
    area_of_node_triangle(ll, a, ap, b) >= 0.0
  } else {
    area_of_node_triangle(ll, a, b, ap) < 0.0 ||
    area_of_node_triangle(ll, a, an, b) < 0.0
  }
}

///|
/// Whether the midpoint of the diagonal a-b lies inside the polygon.
/// Ray-casts from the midpoint and counts edge crossings.
fn middle_inside(ll : LinkedLists, a : Int, b : Int) -> Bool {
  let mx = (ll.nodes[a].x + ll.nodes[b].x) / 2.0
  let my = (ll.nodes[a].y + ll.nodes[b].y) / 2.0
  let mut inside = false
  let mut p = a
  while true {
    let n = ll.nodes[p].next
    let py = ll.nodes[p].y
    let ny = ll.nodes[n].y
    if (py > my) != (ny > my) &&
      ny != py &&
      mx <
      (ll.nodes[n].x - ll.nodes[p].x) * (my - py) / (ny - py) + ll.nodes[p].x {
      inside = !inside
    }
    p = n
    if p == a {
      break
    }
  }
  inside
}

///|
/// Whether the diagonal between two polygon nodes is interior — i.e. it
/// stays inside the polygon and doesn't cross an existing edge.
fn is_valid_diagonal(ll : LinkedLists, a : Int, b : Int) -> Bool {
  let an = ll.nodes[a].next
  let ap = ll.nodes[a].prev
  ll.nodes[an].vertices_index != ll.nodes[b].vertices_index &&
  ll.nodes[ap].vertices_index != ll.nodes[b].vertices_index &&
  !intersects_polygon(ll, a, b) &&
  locally_inside(ll, a, b) &&
  locally_inside(ll, b, a) &&
  middle_inside(ll, a, b)
}

///|
/// Connect or split the linked list at the diagonal a-b. Two new nodes are
/// appended (copies of `a` and `b` with new indices); their wiring either
/// merges two rings into one or splits one ring into two. Returns the new
/// node corresponding to b (i.e. the second new index).
fn split_bridge_polygon(ll : LinkedLists, a : Int, b : Int) -> Int {
  let cidx = ll.nodes.length()
  let didx = cidx + 1
  let c = Node::{
    vertices_index: ll.nodes[a].vertices_index,
    x: ll.nodes[a].x,
    y: ll.nodes[a].y,
    prev: 0,
    next: 0,
    is_steiner: false,
  }
  let d = Node::{
    vertices_index: ll.nodes[b].vertices_index,
    x: ll.nodes[b].x,
    y: ll.nodes[b].y,
    prev: 0,
    next: 0,
    is_steiner: false,
  }
  let an = ll.nodes[a].next
  let bp = ll.nodes[b].prev
  ll.nodes[a].next = b
  ll.nodes[b].prev = a
  c.next = an
  ll.nodes[an].prev = cidx
  d.next = cidx
  c.prev = didx
  ll.nodes[bp].next = didx
  d.prev = bp
  ll.nodes.push(c)
  ll.nodes.push(d)
  didx
}

///|
/// David Eberly's algorithm. Find a node on the outer ring that can be
/// bridged to `hole` (the leftmost node of a hole ring). Returns the
/// outer-ring node index, or `null_idx` if no bridge can be found.
fn find_hole_bridge(ll : LinkedLists, hole : Int, outer_node : Int) -> Int {
  let hx = ll.nodes[hole].x
  let hy = ll.nodes[hole].y
  let mut qx = @double.neg_infinity
  let mut m = null_idx

  // Iterate over (p, n) edge pairs of the outer ring; find the segment
  // whose horizontal projection straddles the ray y=hy moving left from
  // `hole`, and whose intersection x is closest to `hx` (but still ≤ hx).
  let mut p = outer_node
  while true {
    let n = ll.nodes[p].next
    let pny = ll.nodes[n].y
    let py = ll.nodes[p].y
    if hy <= py && hy >= pny && pny != py {
      let calcx = ll.nodes[p].x +
        (hy - py) * (ll.nodes[n].x - ll.nodes[p].x) / (pny - py)
      if calcx <= hx && calcx > qx {
        qx = calcx
        if qx == hx && hy == py {
          return p
        }
        if qx == hx && hy == pny {
          return n
        }
        m = if ll.nodes[p].x < ll.nodes[n].x { p } else { n }
      }
    }
    p = n
    if p == outer_node {
      break
    }
  }
  if m == null_idx {
    return null_idx
  }

  // Hole touches the outer segment at hx — return the lower endpoint.
  if hx == qx {
    return ll.nodes[m].prev
  }

  // Look for reflex points inside the triangle (n1, mp, n2). If any such
  // point exists, choose the one whose ray-tangent to the bridge is
  // smallest (with tie-breaking by largest x).
  let mp_x = ll.nodes[m].x
  let mp_y = ll.nodes[m].y
  let stop = m
  let mut cur = ll.nodes[m].next
  let x1 = if hy < mp_y { hx } else { qx }
  let x2 = if hy < mp_y { qx } else { hx }
  let mut best = m
  let mut tan_min = @double.max_value / 2.0
  while cur != stop {
    let cx = ll.nodes[cur].x
    let cy = ll.nodes[cur].y
    if hx > cx && cx >= mp_x {
      if point_in_triangle(x1, hy, mp_x, mp_y, x2, hy, cx, cy) {
        let calctan = (hy - cy).abs() / (hx - cx)
        if (calctan < tan_min || (calctan == tan_min && cx > ll.nodes[best].x)) &&
          locally_inside(ll, cur, hole) {
          best = cur
          tan_min = calctan
        }
      }
    }
    cur = ll.nodes[cur].next
  }
  best
}

///|
fn eliminate_hole(ll : LinkedLists, hole : Int, outer_node : Int) -> Unit {
  let test_idx = find_hole_bridge(ll, hole, outer_node)
  if test_idx == null_idx {
    return
  }
  let b = split_bridge_polygon(ll, test_idx, hole)
  let ni = ll.nodes[b].next
  let _ = filter_points(ll, b, Some(ni))
}

///|
/// Sort an array of (x, leftmost_node_idx) pairs by ascending x. Insertion
/// sort — `n` is small (count of holes) in practice.
fn sort_by_x(items : Array[(Double, Int)]) -> Unit {
  let n = items.length()
  let mut i = 1
  while i < n {
    let key = items[i]
    let mut j = i - 1
    while j >= 0 && items[j].0 > key.0 {
      items[j + 1] = items[j]
      j = j - 1
    }
    items[j + 1] = key
    i = i + 1
  }
}

///|
/// Add every hole ring to `ll`, then bridge each hole into the outer ring
/// in left-to-right (ascending x of leftmost vertex) order.
fn eliminate_holes(
  ll : LinkedLists,
  vertices : Array[Double],
  hole_indices : Array[Int],
  outer_node_in : Int,
) -> Int? {
  let mut outer_node = outer_node_in
  let leftmost_per_hole : Array[(Double, Int)] = []
  let n_holes = hole_indices.length()
  let mut i = 0
  while i < n_holes {
    let hole_start = hole_indices[i] * dim
    let hole_end = if i + 1 < n_holes {
      hole_indices[i + 1] * dim
    } else {
      vertices.length()
    }
    if hole_start > vertices.length() || hole_end > vertices.length() {
      return None
    }
    match add_contour(ll, vertices, hole_start, hole_end, false) {
      Some((list, leftmost_idx)) => {
        if list == ll.nodes[list].next {
          ll.nodes[list].is_steiner = true
        }
        leftmost_per_hole.push((ll.nodes[leftmost_idx].x, leftmost_idx))
      }
      None => return None
    }
    i = i + 1
  }
  sort_by_x(leftmost_per_hole)
  let mut k = 0
  while k < leftmost_per_hole.length() {
    let (_, lidx) = leftmost_per_hole[k]
    eliminate_hole(ll, lidx, outer_node)
    let nextidx = ll.nodes[outer_node].next
    outer_node = filter_points(ll, outer_node, Some(nextidx))
    k = k + 1
  }
  Some(outer_node)
}

///|
/// Walk the ring once removing ear-tips that close a "local
/// self-intersection" — two adjacent edges that pseudo-cross. Each removal
/// emits a triangle into `triangles`.
fn cure_local_intersections(
  ll : LinkedLists,
  in_start : Int,
  triangles : Array[Int],
) -> Int {
  let mut p = in_start
  let mut start = in_start
  while true {
    let a = ll.nodes[p].prev
    let pn = ll.nodes[p].next
    let b = ll.nodes[pn].next
    if !xy_eq(ll, a, b) &&
      pseudo_intersects(
        ll.nodes[a].x,
        ll.nodes[a].y,
        ll.nodes[p].x,
        ll.nodes[p].y,
        ll.nodes[pn].x,
        ll.nodes[pn].y,
        ll.nodes[b].x,
        ll.nodes[b].y,
      ) &&
      locally_inside(ll, a, b) &&
      locally_inside(ll, b, a) {
      triangles.push(ll.nodes[a].vertices_index)
      triangles.push(ll.nodes[p].vertices_index)
      triangles.push(ll.nodes[b].vertices_index)
      remove_node(ll, p)
      let nidx = ll.nodes[p].next
      remove_node(ll, nidx)
      start = b
      p = start
    }
    p = ll.nodes[p].next
    if p == start {
      break
    }
  }
  p
}

///|
/// Try to split the polygon into two halves along a valid interior
/// diagonal, then triangulate each half independently.
fn split_earcut(
  ll : LinkedLists,
  start_idx : Int,
  triangles : Array[Int],
) -> Unit {
  let mut a = start_idx
  while true {
    let an = ll.nodes[a].next
    let mut b = ll.nodes[an].next
    let stop_b = ll.nodes[a].prev
    while b != stop_b {
      if ll.nodes[a].vertices_index != ll.nodes[b].vertices_index &&
        is_valid_diagonal(ll, a, b) {
        let mut c = split_bridge_polygon(ll, a, b)
        let an2 = ll.nodes[a].next
        let cn = ll.nodes[c].next
        let new_a = filter_points(ll, a, Some(an2))
        c = filter_points(ll, c, Some(cn))
        earcut_linked_unhashed(ll, new_a, triangles, 0)
        earcut_linked_unhashed(ll, c, triangles, 0)
        return
      }
      b = ll.nodes[b].next
    }
    a = ll.nodes[a].next
    if a == start_idx {
      break
    }
  }
}

///|
/// Main 4-pass ear-clipping loop, without the z-order spatial index. The
/// `pass` parameter mirrors the upstream `const PASS` generic:
/// - 0: try ear clipping; on stall, filter colinear/duplicate vertices and
///   recurse with PASS=1
/// - 1: cure local self-intersections, recurse with PASS=2
/// - 2: split along a valid diagonal and recurse on each half (PASS=0)
/// - else: give up
fn earcut_linked_unhashed(
  ll : LinkedLists,
  ear_in : Int,
  triangles : Array[Int],
  pass : Int,
) -> Unit {
  let mut ear = ear_in
  let mut stop_idx = ear
  let mut prev_idx = 0
  let mut next_idx = ll.nodes[ear].next
  while stop_idx != next_idx {
    prev_idx = ll.nodes[ear].prev
    next_idx = ll.nodes[ear].next
    if is_ear(ll, prev_idx, ear, next_idx) {
      triangles.push(ll.nodes[prev_idx].vertices_index)
      triangles.push(ll.nodes[ear].vertices_index)
      triangles.push(ll.nodes[next_idx].vertices_index)
      remove_node(ll, ear)
      // skipping the next vertex leads to less sliver triangles
      ear = ll.nodes[next_idx].next
      stop_idx = ear
    } else {
      ear = next_idx
    }
  }
  if prev_idx == next_idx {
    return
  }
  if pass == 0 {
    let tmp = filter_points(ll, next_idx, None)
    earcut_linked_unhashed(ll, tmp, triangles, 1)
  } else if pass == 1 {
    let new_ear = cure_local_intersections(ll, next_idx, triangles)
    earcut_linked_unhashed(ll, new_ear, triangles, 2)
  } else if pass == 2 {
    split_earcut(ll, next_idx, triangles)
  }
}

///|
/// Triangulate a 2D polygon (with optional holes) using the Mapbox earcut
/// algorithm. `vertices` is a flat array `[x0, y0, x1, y1, …]`. Each entry
/// of `hole_indices` is a *vertex* index (not coordinate index) where a
/// hole ring begins. `dims` should be 2 (other values short-circuit to an
/// empty result, matching the upstream).
///
/// Returns `Some(indices)` where every 3 consecutive ints form one
/// triangle (each int is a vertex index), or `None` for malformed input
/// such as an odd-length `vertices` array.
pub fn earcut(
  vertices : Array[Double],
  hole_indices : Array[Int],
  dims : Int,
) -> Array[Int]? {
  if vertices.is_empty() && hole_indices.is_empty() {
    return Some([])
  }
  if vertices.length() % 2 == 1 || dims > vertices.length() {
    return None
  }
  let outer_len = if hole_indices.length() > 0 {
    let v0 = hole_indices[0] * dim
    if v0 > vertices.length() || v0 == 0 {
      return None
    }
    if v0 % 2 == 1 {
      return None
    }
    v0
  } else {
    vertices.length()
  }
  let triangles : Array[Int] = []
  match linked_list(vertices, 0, outer_len, true) {
    None => return None
    Some((ll, outer_node)) => {
      if ll.nodes.length() == 1 || dim != dims {
        return Some(triangles)
      }
      match eliminate_holes(ll, vertices, hole_indices, outer_node) {
        None => return None
        Some(outer) => earcut_linked_unhashed(ll, outer, triangles, 0)
      }
    }
  }
  Some(triangles)
}
