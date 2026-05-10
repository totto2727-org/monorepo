// R-tree k-nearest-neighbor query.
//
// TODO ms-18-followup: this is a brute-force collect-sort-take-k pass; for
// large trees with small `k` a best-first traversal with a min-heap of
// `(dist², node)` pairs is asymptotically faster (O((k + log n) * log n) vs
// O(n log n)). Deferred because MoonBit's `@priority_queue` would require
// either a comparable wrapper around `Node[T]` or a custom heap, and the
// brute-force version is correct enough for ms-30 / ms-27 spatial-location
// callers that operate on at most a few hundred candidates.

///|
/// Walks the subtree rooted at `node` and pushes `(value, dist²-from-pt)` for
/// every leaf entry into `out`.
fn[T] collect_entries_with_dist(
  node : Node[T],
  pt : @type.Coord,
  out : Array[(T, Double)],
) -> Unit {
  match node {
    Leaf(_, entries) =>
      for i in 0..<entries.length() {
        let e = entries[i]
        out.push((e.value, rect_min_dist_sq(pt, e.bbox)))
      }
    Internal(_, children) =>
      for i in 0..<children.length() {
        collect_entries_with_dist(children[i], pt, out)
      }
  }
}

///|
/// Returns every stored value sorted by ascending Euclidean distance from
/// `pt` (measured to each value's bounding rect). When `k` is `Some(n)` the
/// result is truncated to the first `n` items; `None` returns all.
pub fn[T] RTree::nearest_neighbors(
  self : RTree[T],
  pt : @type.Coord,
  k : Int?,
) -> Array[T] {
  let pairs : Array[(T, Double)] = []
  match self.root {
    None => ()
    Some(root) => collect_entries_with_dist(root, pt, pairs)
  }
  pairs.sort_by(fn(a, b) {
    if a.1 < b.1 {
      -1
    } else if a.1 > b.1 {
      1
    } else {
      0
    }
  })
  let limit = match k {
    Some(n) =>
      if n < 0 {
        0
      } else if n < pairs.length() {
        n
      } else {
        pairs.length()
      }
    None => pairs.length()
  }
  Array::makei(limit, fn(i) { pairs[i].0 })
}
