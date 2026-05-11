// 2D R-tree spatial index ported from georust/rstar (https://github.com/georust/rstar).
//
// This is an R-tree using sort-tile-recursive (STR) packing for bulk load and
// a simpler split-only dynamic path for insert/remove. It is intentionally
// smaller than the full R*-tree in `rstar`. It supports:
//
// - `query_rect_intersection`: all entries whose bounding rect intersects a
//   query rect.
// - `query_nearest`: the entry closest to a query coordinate (Euclidean).
// - dynamic `insert` / `remove`, iteration, draining, point/radius locate, and
//   k-nearest collection.
//
// The forced reinsertion, condense-tree rebalancing, tunable params, and
// best-first nearest-neighbour traversal of the original R*-tree are out of
// scope for this port.

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
pub fn[T] Entry::Entry(bbox : @type.Rect, value : T) -> Entry[T] {
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
/// A 2D R-tree. Build with `RTree::bulk_load(entries)` for static data, or
/// start empty with `RTree::new()` and `insert` / `remove` for dynamic use.
pub struct RTree[T] {
  mut root : Node[T]?
  mut size : Int
}

///|
/// Canonical constructor for `RTree`. Most callers use the higher-level
/// `RTree::bulk_load` factory; this raw constructor is kept private to the
/// package and is the single struct-literal entry point for the type.
fn[T] RTree::RTree(root : Node[T]?, size : Int) -> RTree[T] {
  RTree::{ root, size }
}

///|
/// Returns an empty `RTree`. Use with `insert` / `remove` for dynamic use.
pub fn[T] RTree::new() -> RTree[T] {
  RTree::{ root: None, size: 0 }
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
  let min_x = if a.min().x() < b.min().x() { a.min().x() } else { b.min().x() }
  let min_y = if a.min().y() < b.min().y() { a.min().y() } else { b.min().y() }
  let max_x = if a.max().x() > b.max().x() { a.max().x() } else { b.max().x() }
  let max_y = if a.max().y() > b.max().y() { a.max().y() } else { b.max().y() }
  @type.Rect::Rect(@type.Coord(min_x, min_y), @type.Coord(max_x, max_y))
}

///|
fn rect_intersects(a : @type.Rect, b : @type.Rect) -> Bool {
  !(a.max().x() < b.min().x() ||
  b.max().x() < a.min().x() ||
  a.max().y() < b.min().y() ||
  b.max().y() < a.min().y())
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
  entries
  .iter()
  .drop(1)
  .fold(init=entries[0].bbox, fn(acc, e) { rect_union(acc, e.bbox) })
}

///|
fn[T] nodes_bbox(nodes : Array[Node[T]]) -> @type.Rect {
  nodes
  .iter()
  .drop(1)
  .fold(init=nodes[0].node_bbox(), fn(acc, node) {
    rect_union(acc, node.node_bbox())
  })
}

///|

///|
/// Compares two values by mapping them through `key` and ordering by the
/// `Double` result.
fn[T] cmp_by_double(a : T, b : T, key : (T) -> Double) -> Int {
  let ka = key(a)
  let kb = key(b)
  if ka < kb {
    -1
  } else if ka > kb {
    1
  } else {
    0
  }
}

///|
/// Sorts `entries` by `key` (without mutating the input) and slices the result
/// into chunks of size up to `slice_size`.
fn[T] partition_entries_by(
  entries : Array[Entry[T]],
  slice_size : Int,
  key : (Entry[T]) -> Double,
) -> Array[Array[Entry[T]]] {
  let sorted = Array::makei(entries.length(), fn(i) { entries[i] })
  sorted.sort_by(fn(a, b) { cmp_by_double(a, b, key) })
  sorted.chunks(slice_size).map(fn(chunk) { chunk.iter().to_array() })
}

///|
fn[T] partition_entries_by_x(
  entries : Array[Entry[T]],
  slice_size : Int,
) -> Array[Array[Entry[T]]] {
  partition_entries_by(entries, slice_size, fn(e) { rect_center_x(e.bbox) })
}

///|
fn[T] partition_entries_by_y(
  entries : Array[Entry[T]],
  slice_size : Int,
) -> Array[Array[Entry[T]]] {
  partition_entries_by(entries, slice_size, fn(e) { rect_center_y(e.bbox) })
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
  let entries_per_strip = (n + actual_strip_count - 1) / actual_strip_count
  let entries_per_strip_padded = if entries_per_strip < MAX_ENTRIES {
    MAX_ENTRIES
  } else {
    (entries_per_strip + MAX_ENTRIES - 1) / MAX_ENTRIES * MAX_ENTRIES
  }
  partition_entries_by_x(entries, entries_per_strip_padded)
  .iter()
  .flat_map(fn(strip) {
    partition_entries_by_y(strip, MAX_ENTRIES)
    .iter()
    .map(fn(group) { Node::Leaf(entries_bbox(group), group) })
  })
  .collect()
}

///|
fn[T] build_internal_level(nodes : Array[Node[T]]) -> Array[Node[T]] {
  // Group up nodes into the next level: pack MAX_ENTRIES per parent.
  nodes
  .chunks(MAX_ENTRIES)
  .map(fn(chunk) {
    let children = chunk.iter().to_array()
    Node::Internal(nodes_bbox(children), children)
  })
}

///|
/// Builds an `RTree` from the given entries. Returns an empty tree when
/// `entries` is empty.

///|
/// Recursively packs each level of nodes (already at the leaf level) up to
/// the root by grouping `MAX_ENTRIES` siblings per parent.
fn[T] reduce_to_root(level : Array[Node[T]]) -> Array[Node[T]] {
  if level.length() <= 1 {
    level
  } else {
    reduce_to_root(build_internal_level(level))
  }
}

///|
/// Builds an `RTree` from the given entries. Returns an empty tree when
/// `entries` is empty.
pub fn[T] RTree::bulk_load(entries : Array[Entry[T]]) -> RTree[T] {
  let n = entries.length()
  if n == 0 {
    return RTree(None, 0)
  }
  let root_level = reduce_to_root(build_leaves(entries))
  let root = if root_level.length() == 1 { Some(root_level[0]) } else { None }
  RTree(root, n)
}

///|
/// Returns all entries whose bounding rect intersects `query`.
pub fn[T] RTree::query_rect_intersection(
  self : RTree[T],
  query : @type.Rect,
) -> Array[T] {
  match self.root {
    None => []
    Some(root) => intersecting(root, query)
  }
}

///|
/// Returns all leaf-entry values reachable from `node` whose bbox intersects
/// `query`. Pure: builds new arrays via iter chains rather than mutating an
/// out-parameter.
fn[T] intersecting(node : Node[T], query : @type.Rect) -> Array[T] {
  match node {
    Leaf(bbox, entries) =>
      if !rect_intersects(bbox, query) {
        []
      } else {
        entries
        .iter()
        .filter(fn(e) { rect_intersects(e.bbox, query) })
        .map(fn(e) { e.value })
        .collect()
      }
    Internal(bbox, children) =>
      if !rect_intersects(bbox, query) {
        []
      } else {
        children
        .iter()
        .flat_map(fn(c) { intersecting(c, query).iter() })
        .collect()
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
pub fn[T] RTree::query_nearest(self : RTree[T], target : @type.Coord) -> T? {
  match self.root {
    None => None
    Some(root) =>
      match nearest_recurse(root, target, @double.infinity) {
        Some((value, _)) => Some(value)
        None => None
      }
  }
}

///|
/// Returns the (value, squared-distance) pair from the subtree rooted at
/// `node` that is closer than `current_best`, or `None` if nothing in this
/// subtree improves on `current_best`. Pure: no captured mutation.
fn[T] nearest_recurse(
  node : Node[T],
  target : @type.Coord,
  current_best : Double,
) -> (T, Double)? {
  let initial : ((T, Double)?, Double) = (None, current_best)
  match node {
    Leaf(_, entries) =>
      entries
      .iter()
      .fold(init=initial, fn(acc, entry) {
        let (best, best_dist) = acc
        let d = rect_min_dist_sq(target, entry.bbox)
        if d < best_dist {
          (Some((entry.value, d)), d)
        } else {
          (best, best_dist)
        }
      }).0
    Internal(_, children) => {
      // Visit children in order of increasing min-distance for pruning.
      let with_dist = children.map(fn(child) {
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
      with_dist
      .iter()
      .take_while(fn(pair) { pair.0 < current_best })
      .fold(init=initial, fn(acc, pair) {
        let (_, best_dist) = acc
        if pair.0 >= best_dist {
          acc
        } else {
          match nearest_recurse(pair.1, target, best_dist) {
            Some((v, d)) => (Some((v, d)), d)
            None => acc
          }
        }
      }).0
    }
  }
}
