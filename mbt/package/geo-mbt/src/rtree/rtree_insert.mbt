// R-tree dynamic insertion.
//
// Implements `choose_subtree` (least-area-enlargement) and a simple
// sort-and-split when a node overflows. The full R*-tree forced-reinsertion
// strategy (which reduces overlap by re-inserting up to ~30% of an
// overflowing node's entries before resorting to split) is intentionally
// omitted — see TODO ms-18-followup.

///|
/// Result of a recursive insert: either the subtree fits back into a single
/// node, or it overflowed and split into two siblings that the caller must
/// place into the parent.
priv enum InsertResult[T] {
  Single(Node[T])
  Split(Node[T], Node[T])
}

///|
/// Picks the child whose bbox needs the smallest area enlargement to contain
/// `bbox`. Ties broken by smaller current area.
///
/// TODO ms-18-followup: rstar uses overlap-enlargement (not area) at the
/// leaf level. Switching would reduce later split frequency at a per-insert
/// cost.
fn[T] choose_subtree(children : Array[Node[T]], bbox : @type.Rect) -> Int {
  let mut best_idx = 0
  let mut best_enlargement = @double.infinity
  let mut best_area = @double.infinity
  for i in 0..<children.length() {
    let cb = children[i].node_bbox()
    let cur_area = cb.area()
    let union_b = rect_union(cb, bbox)
    let enlargement = union_b.area() - cur_area
    if enlargement < best_enlargement ||
      (enlargement == best_enlargement && cur_area < best_area) {
      best_idx = i
      best_enlargement = enlargement
      best_area = cur_area
    }
  }
  best_idx
}

///|
/// Splits `entries` in half along the wider axis of their union bbox. Sorts by
/// the corresponding centre coordinate then cuts at the midpoint.
fn[T] split_entries(
  entries : Array[Entry[T]],
) -> (Array[Entry[T]], Array[Entry[T]]) {
  let bbox = entries_bbox(entries)
  let dx = bbox.max().x() - bbox.min().x()
  let dy = bbox.max().y() - bbox.min().y()
  let sorted = Array::makei(entries.length(), fn(i) { entries[i] })
  if dx >= dy {
    sorted.sort_by(fn(a, b) {
      cmp_by_double(a, b, fn(e) { rect_center_x(e.bbox) })
    })
  } else {
    sorted.sort_by(fn(a, b) {
      cmp_by_double(a, b, fn(e) { rect_center_y(e.bbox) })
    })
  }
  let mid = sorted.length() / 2
  let left = Array::makei(mid, fn(i) { sorted[i] })
  let right = Array::makei(sorted.length() - mid, fn(i) { sorted[mid + i] })
  (left, right)
}

///|
/// Splits `nodes` in half along the wider axis of their union bbox.
fn[T] split_nodes(nodes : Array[Node[T]]) -> (Array[Node[T]], Array[Node[T]]) {
  let bbox = nodes_bbox(nodes)
  let dx = bbox.max().x() - bbox.min().x()
  let dy = bbox.max().y() - bbox.min().y()
  let sorted = Array::makei(nodes.length(), fn(i) { nodes[i] })
  if dx >= dy {
    sorted.sort_by(fn(a, b) {
      cmp_by_double(a, b, fn(n) { rect_center_x(n.node_bbox()) })
    })
  } else {
    sorted.sort_by(fn(a, b) {
      cmp_by_double(a, b, fn(n) { rect_center_y(n.node_bbox()) })
    })
  }
  let mid = sorted.length() / 2
  let left = Array::makei(mid, fn(i) { sorted[i] })
  let right = Array::makei(sorted.length() - mid, fn(i) { sorted[mid + i] })
  (left, right)
}

///|
/// Recursively descends to a leaf, inserts the entry, and propagates any
/// resulting split back up the tree.
fn[T] insert_into(node : Node[T], entry : Entry[T]) -> InsertResult[T] {
  match node {
    Leaf(_, entries) => {
      let new_entries = Array::makei(entries.length() + 1, fn(i) {
        if i < entries.length() {
          entries[i]
        } else {
          entry
        }
      })
      if new_entries.length() <= MAX_ENTRIES {
        Single(Node::Leaf(entries_bbox(new_entries), new_entries))
      } else {
        let (a, b) = split_entries(new_entries)
        Split(Node::Leaf(entries_bbox(a), a), Node::Leaf(entries_bbox(b), b))
      }
    }
    Internal(_, children) => {
      let best_idx = choose_subtree(children, entry.bbox)
      match insert_into(children[best_idx], entry) {
        Single(new_child) => {
          let new_children = Array::makei(children.length(), fn(i) {
            if i == best_idx {
              new_child
            } else {
              children[i]
            }
          })
          Single(Node::Internal(nodes_bbox(new_children), new_children))
        }
        Split(c1, c2) => {
          let n = children.length()
          let new_children = Array::makei(n + 1, fn(i) {
            if i == n {
              c2
            } else if i == best_idx {
              c1
            } else {
              children[i]
            }
          })
          if new_children.length() <= MAX_ENTRIES {
            Single(Node::Internal(nodes_bbox(new_children), new_children))
          } else {
            let (a, b) = split_nodes(new_children)
            Split(
              Node::Internal(nodes_bbox(a), a),
              Node::Internal(nodes_bbox(b), b),
            )
          }
        }
      }
    }
  }
}

///|
/// Inserts `entry` into the tree, splitting nodes and growing the tree as
/// needed. Amortised `O(log n)`.
pub fn[T] RTree::insert(self : RTree[T], entry : Entry[T]) -> Unit {
  match self.root {
    None => self.root = Some(Node::Leaf(entry.bbox, [entry]))
    Some(root) =>
      match insert_into(root, entry) {
        Single(new_root) => self.root = Some(new_root)
        Split(a, b) => {
          let children = [a, b]
          self.root = Some(Node::Internal(nodes_bbox(children), children))
        }
      }
  }
  self.size = self.size + 1
}
