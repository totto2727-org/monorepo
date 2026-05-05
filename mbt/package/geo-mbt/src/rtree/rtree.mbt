// 2D R-tree spatial index ported from georust/rstar (https://github.com/georust/rstar).
//
// This is a **bulk-loaded** R-tree using sort-tile-recursive (STR) packing.
// It is read-only after construction and intentionally simpler than the full
// R*-tree in `rstar`. It supports two queries:
//
// - `query_rect_intersection`: all entries whose bounding rect intersects a
//   query rect.
// - `query_nearest`: the entry closest to a query coordinate (Euclidean).
//
// The dynamic insertion / deletion / rebalancing of the original R*-tree is
// out of scope for this port. The intended use case is geo-mbt's `indexed`
// algorithms (e.g. preparing a polygon set for many point-in-polygon queries
// against a fixed set of polygons).

///|
/// Maximum number of entries per node. With STR packing, branching factor
/// of 16 strikes a reasonable balance between depth and per-node scanning
/// for typical geometric workloads.
const MAX_ENTRIES : Int = 16

///|
/// One entry in an `RTree`: a bounding rectangle and an arbitrary value.
pub(all) struct Entry[T] {
  bbox : @type.Rect
  value : T
}

///|
pub fn[T] Entry::new(bbox : @type.Rect, value : T) -> Entry[T] {
  Entry::{ bbox, value }
}

///|
enum Node[T] {
  Leaf(@type.Rect, Array[Entry[T]])
  Internal(@type.Rect, Array[Node[T]])
}

///|
fn[T] Node::node_bbox(self : Node[T]) -> @type.Rect {
  match self {
    Leaf(b, _) => b
    Internal(b, _) => b
  }
}

///|
/// A read-only 2D R-tree. Build with `RTree::bulk_load(entries)`.
pub struct RTree[T] {
  root : Node[T]?
  size : Int
}

///|
pub fn[T] RTree::is_empty(self : RTree[T]) -> Bool {
  self.size == 0
}

///|
pub fn[T] RTree::size(self : RTree[T]) -> Int {
  self.size
}

///|
fn rect_union(a : @type.Rect, b : @type.Rect) -> @type.Rect {
  let min_x = if a.min().x() < b.min().x() {
    a.min().x()
  } else {
    b.min().x()
  }
  let min_y = if a.min().y() < b.min().y() {
    a.min().y()
  } else {
    b.min().y()
  }
  let max_x = if a.max().x() > b.max().x() {
    a.max().x()
  } else {
    b.max().x()
  }
  let max_y = if a.max().y() > b.max().y() {
    a.max().y()
  } else {
    b.max().y()
  }
  @type.Rect::new(
    @type.Coord::new(min_x, min_y),
    @type.Coord::new(max_x, max_y),
  )
}

///|
fn rect_intersects(a : @type.Rect, b : @type.Rect) -> Bool {
  !(
    a.max().x() < b.min().x() ||
    b.max().x() < a.min().x() ||
    a.max().y() < b.min().y() ||
    b.max().y() < a.min().y()
  )
}

///|
fn rect_center_x(r : @type.Rect) -> Double {
  (r.min().x() + r.max().x()) / 2.0
}

///|
fn rect_center_y(r : @type.Rect) -> Double {
  (r.min().y() + r.max().y()) / 2.0
}

///|
fn[T] entries_bbox(entries : Array[Entry[T]]) -> @type.Rect {
  let mut current = entries[0].bbox
  for i = 1; i < entries.length(); i = i + 1 {
    current = rect_union(current, entries[i].bbox)
  }
  current
}

///|
fn[T] nodes_bbox(nodes : Array[Node[T]]) -> @type.Rect {
  let mut current = nodes[0].node_bbox()
  for i = 1; i < nodes.length(); i = i + 1 {
    current = rect_union(current, nodes[i].node_bbox())
  }
  current
}

///|
fn[T] partition_entries_by_x(
  entries : Array[Entry[T]],
  slice_size : Int,
) -> Array[Array[Entry[T]]] {
  let sorted = entries.copy()
  sorted.sort_by(fn(a, b) {
    let ax = rect_center_x(a.bbox)
    let bx = rect_center_x(b.bbox)
    if ax < bx {
      -1
    } else if ax > bx {
      1
    } else {
      0
    }
  })
  let result : Array[Array[Entry[T]]] = []
  let n = sorted.length()
  let mut i = 0
  while i < n {
    let end = if i + slice_size > n { n } else { i + slice_size }
    let slice : Array[Entry[T]] = []
    for j = i; j < end; j = j + 1 {
      slice.push(sorted[j])
    }
    result.push(slice)
    i = i + slice_size
  }
  result
}

///|
fn[T] partition_entries_by_y(
  entries : Array[Entry[T]],
  slice_size : Int,
) -> Array[Array[Entry[T]]] {
  let sorted = entries.copy()
  sorted.sort_by(fn(a, b) {
    let ay = rect_center_y(a.bbox)
    let by = rect_center_y(b.bbox)
    if ay < by {
      -1
    } else if ay > by {
      1
    } else {
      0
    }
  })
  let result : Array[Array[Entry[T]]] = []
  let n = sorted.length()
  let mut i = 0
  while i < n {
    let end = if i + slice_size > n { n } else { i + slice_size }
    let slice : Array[Entry[T]] = []
    for j = i; j < end; j = j + 1 {
      slice.push(sorted[j])
    }
    result.push(slice)
    i = i + slice_size
  }
  result
}

///|
fn[T] build_leaves(entries : Array[Entry[T]]) -> Array[Node[T]] {
  // Sort-Tile-Recursive: sort by x, slice into vertical strips, then sort each
  // strip by y and slice into MAX_ENTRIES-sized leaves.
  let n = entries.length()
  if n == 0 {
    return []
  }
  let leaf_count = (n + MAX_ENTRIES - 1) / MAX_ENTRIES
  let strip_count = (leaf_count.to_double().sqrt().ceil() : Double).to_int()
  let actual_strip_count = if strip_count == 0 { 1 } else { strip_count }
  let entries_per_strip = (
    (n + actual_strip_count - 1) / actual_strip_count
  ) * 1
  let entries_per_strip_padded = if entries_per_strip < MAX_ENTRIES {
    MAX_ENTRIES
  } else {
    ((entries_per_strip + MAX_ENTRIES - 1) / MAX_ENTRIES) * MAX_ENTRIES
  }
  let strips = partition_entries_by_x(entries, entries_per_strip_padded)
  let leaves : Array[Node[T]] = []
  for strip in strips {
    let leaf_groups = partition_entries_by_y(strip, MAX_ENTRIES)
    for group in leaf_groups {
      let bbox = entries_bbox(group)
      leaves.push(Node::Leaf(bbox, group))
    }
  }
  leaves
}

///|
fn[T] build_internal_level(nodes : Array[Node[T]]) -> Array[Node[T]] {
  // Group up nodes into the next level: pack MAX_ENTRIES per parent.
  let result : Array[Node[T]] = []
  let n = nodes.length()
  let mut i = 0
  while i < n {
    let end = if i + MAX_ENTRIES > n { n } else { i + MAX_ENTRIES }
    let children : Array[Node[T]] = []
    for j = i; j < end; j = j + 1 {
      children.push(nodes[j])
    }
    let bbox = nodes_bbox(children)
    result.push(Node::Internal(bbox, children))
    i = i + MAX_ENTRIES
  }
  result
}

///|
/// Builds an `RTree` from the given entries. Returns an empty tree when
/// `entries` is empty.
pub fn[T] RTree::bulk_load(entries : Array[Entry[T]]) -> RTree[T] {
  let n = entries.length()
  if n == 0 {
    return RTree::{ root: None, size: 0 }
  }
  let mut current_level : Array[Node[T]] = build_leaves(entries)
  while current_level.length() > 1 {
    current_level = build_internal_level(current_level)
  }
  let root = if current_level.length() == 1 {
    Some(current_level[0])
  } else {
    None
  }
  RTree::{ root, size: n }
}

///|
/// Returns all entries whose bounding rect intersects `query`.
pub fn[T] RTree::query_rect_intersection(
  self : RTree[T],
  query : @type.Rect,
) -> Array[T] {
  let result : Array[T] = []
  match self.root {
    None => return result
    Some(root) => collect_intersecting(root, query, result)
  }
  result
}

///|
fn[T] collect_intersecting(
  node : Node[T],
  query : @type.Rect,
  out : Array[T],
) -> Unit {
  match node {
    Leaf(bbox, entries) => {
      if !rect_intersects(bbox, query) {
        return
      }
      for entry in entries {
        if rect_intersects(entry.bbox, query) {
          out.push(entry.value)
        }
      }
    }
    Internal(bbox, children) => {
      if !rect_intersects(bbox, query) {
        return
      }
      for child in children {
        collect_intersecting(child, query, out)
      }
    }
  }
}

///|
/// Squared minimum distance from a coord to a rectangle.
fn rect_min_dist_sq(coord : @type.Coord, rect : @type.Rect) -> Double {
  let dx = if coord.x() < rect.min().x() {
    rect.min().x() - coord.x()
  } else if coord.x() > rect.max().x() {
    coord.x() - rect.max().x()
  } else {
    0.0
  }
  let dy = if coord.y() < rect.min().y() {
    rect.min().y() - coord.y()
  } else if coord.y() > rect.max().y() {
    coord.y() - rect.max().y()
  } else {
    0.0
  }
  dx * dx + dy * dy
}

///|
/// Returns a closest-by-bbox-distance entry to the given coordinate, or
/// `None` if the tree is empty. When two entries have equal bbox distance
/// the result is implementation-defined.
///
/// Note: the returned "nearest" is by **bounding rectangle** distance only;
/// callers that need true geometric distance to a complex shape should
/// post-filter by computing the actual distance for the candidate(s) returned
/// by `query_rect_intersection` of an appropriately enlarged query rect.
pub fn[T] RTree::query_nearest(
  self : RTree[T],
  target : @type.Coord,
) -> T? {
  match self.root {
    None => None
    Some(root) => {
      let mut best : T? = None
      let mut best_dist = @double.infinity
      nearest_recurse(root, target, best_dist, fn(value, dist) {
        if dist < best_dist {
          best_dist = dist
          best = Some(value)
        }
      })
      best
    }
  }
}

///|
fn[T] nearest_recurse(
  node : Node[T],
  target : @type.Coord,
  current_best : Double,
  update : (T, Double) -> Unit,
) -> Unit {
  match node {
    Leaf(_, entries) =>
      for entry in entries {
        let d = rect_min_dist_sq(target, entry.bbox)
        if d < current_best {
          update(entry.value, d)
        }
      }
    Internal(_, children) => {
      // Visit children in order of increasing min-distance for pruning.
      let with_dist : Array[(Double, Node[T])] = children.map(fn(child) {
        (rect_min_dist_sq(target, child.node_bbox()), child)
      })
      with_dist.sort_by(fn(a, b) {
        if a.0 < b.0 {
          -1
        } else if a.0 > b.0 {
          1
        } else {
          0
        }
      })
      for pair in with_dist {
        if pair.0 >= current_best {
          break
        }
        nearest_recurse(pair.1, target, current_best, update)
      }
    }
  }
}
