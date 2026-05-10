// R-tree iteration helpers (iter + drain).

///|
/// Lazy depth-first iterator over every leaf entry's value reachable from
/// `node`.
fn[T] node_iter_values(node : Node[T]) -> Iter[T] {
  match node {
    Leaf(_, entries) => entries.iter().map(fn(e) { e.value })
    Internal(_, children) =>
      children.iter().flat_map(fn(c) { node_iter_values(c) })
  }
}

///|
/// Lazy iterator over every stored value, in arbitrary (depth-first tree)
/// order.
pub fn[T] RTree::iter(self : RTree[T]) -> Iter[T] {
  match self.root {
    None => Iter::empty()
    Some(root) => node_iter_values(root)
  }
}

///|
/// Removes and returns every stored value, leaving the tree empty.
pub fn[T] RTree::drain(self : RTree[T]) -> Array[T] {
  let result = self.iter().collect()
  self.root = None
  self.size = 0
  result
}
