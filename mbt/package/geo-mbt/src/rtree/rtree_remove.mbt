// R-tree element removal.
//
// Removes the first leaf entry whose `value` equals `entry.value` and whose
// containing leaf intersects `entry.bbox`. Re-uses the input bbox for cheap
// pruning during descent.
//
// TODO ms-18-followup: rstar performs a "condense tree" pass that re-inserts
// orphans from under-full nodes. We skip it — leaves are simply allowed to
// shrink (potentially to size 1) and only when a leaf becomes empty do we
// drop it from its parent. Acceptable for v0.2.0; query performance can
// degrade with heavy churn.

///|
/// Recursively descends to find a leaf entry equal to `entry.value`. Returns
/// the removed value plus the new subtree rooted at `node`, or `None` if the
/// subtree was unchanged. A returned `None` for the new subtree means the
/// node became empty and should be dropped by the caller.
fn[T : Eq] remove_from(node : Node[T], entry : Entry[T]) -> (T, Node[T]?)? {
  match node {
    Leaf(bbox, entries) => {
      if !rect_intersects(bbox, entry.bbox) {
        return None
      }
      let mut found = -1
      for i in 0..<entries.length() {
        if entries[i].value == entry.value {
          found = i
          break
        }
      }
      if found < 0 {
        return None
      }
      let removed = entries[found].value
      if entries.length() == 1 {
        return Some((removed, None))
      }
      let new_entries = Array::makei(entries.length() - 1, fn(i) {
        if i < found {
          entries[i]
        } else {
          entries[i + 1]
        }
      })
      Some((removed, Some(Node::Leaf(entries_bbox(new_entries), new_entries))))
    }
    Internal(bbox, children) => {
      if !rect_intersects(bbox, entry.bbox) {
        return None
      }
      for i in 0..<children.length() {
        match remove_from(children[i], entry) {
          Some((removed, maybe_new_child)) => {
            let new_children = match maybe_new_child {
              Some(nc) =>
                Array::makei(children.length(), fn(j) {
                  if j == i {
                    nc
                  } else {
                    children[j]
                  }
                })
              None =>
                Array::makei(children.length() - 1, fn(j) {
                  if j < i {
                    children[j]
                  } else {
                    children[j + 1]
                  }
                })
            }
            if new_children.length() == 0 {
              return Some((removed, None))
            }
            return Some(
              (
                removed,
                Some(Node::Internal(nodes_bbox(new_children), new_children)),
              ),
            )
          }
          None => continue
        }
      }
      None
    }
  }
}

///|
/// Removes the first stored entry whose value equals `entry.value` and whose
/// leaf intersects `entry.bbox`. Returns the removed value, or `None` if no
/// such entry was found. Uses the supplied bbox to prune the search; pass
/// the same `Entry` value used in the original `insert` for best results.
pub fn[T : Eq] RTree::remove(self : RTree[T], entry : Entry[T]) -> T? {
  match self.root {
    None => None
    Some(root) =>
      match remove_from(root, entry) {
        Some((value, new_root)) => {
          self.root = new_root
          self.size = self.size - 1
          Some(value)
        }
        None => None
      }
  }
}
