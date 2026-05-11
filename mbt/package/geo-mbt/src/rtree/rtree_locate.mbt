// R-tree point-containment and distance-threshold queries.

///|
/// True iff `pt` lies within `rect` (closed boundary).
fn rect_contains_point(rect : @type.Rect, pt : @type.Coord) -> Bool {
  rect.min().x() <= pt.x() &&
  pt.x() <= rect.max().x() &&
  rect.min().y() <= pt.y() &&
  pt.y() <= rect.max().y()
}

///|
fn[T] locate_at_point_recurse(
  node : Node[T],
  pt : @type.Coord,
  out : Array[T],
) -> Unit {
  match node {
    Leaf(bbox, entries) => {
      if !rect_contains_point(bbox, pt) {
        return
      }
      for i in 0..<entries.length() {
        let e = entries[i]
        if rect_contains_point(e.bbox, pt) {
          out.push(e.value)
        }
      }
    }
    Internal(bbox, children) => {
      if !rect_contains_point(bbox, pt) {
        return
      }
      for i in 0..<children.length() {
        locate_at_point_recurse(children[i], pt, out)
      }
    }
  }
}

///|
/// Returns every value whose bounding rect contains `pt`. Result order is
/// implementation-defined (depends on tree layout).
pub fn[T] RTree::locate_at_point(self : RTree[T], pt : @type.Coord) -> Array[T] {
  let out : Array[T] = []
  match self.root {
    None => ()
    Some(root) => locate_at_point_recurse(root, pt, out)
  }
  out
}

///|
fn[T] locate_within_distance_recurse(
  node : Node[T],
  pt : @type.Coord,
  max_dist_sq : Double,
  out : Array[T],
) -> Unit {
  match node {
    Leaf(bbox, entries) => {
      if rect_min_dist_sq(pt, bbox) > max_dist_sq {
        return
      }
      for i in 0..<entries.length() {
        let e = entries[i]
        if rect_min_dist_sq(pt, e.bbox) <= max_dist_sq {
          out.push(e.value)
        }
      }
    }
    Internal(bbox, children) => {
      if rect_min_dist_sq(pt, bbox) > max_dist_sq {
        return
      }
      for i in 0..<children.length() {
        locate_within_distance_recurse(children[i], pt, max_dist_sq, out)
      }
    }
  }
}

///|
/// Returns every value whose bounding rect lies within Euclidean distance
/// `r` of `pt` (i.e. squared min-distance from pt to bbox is `<= r * r`).
/// Result order is implementation-defined.
pub fn[T] RTree::locate_within_distance(
  self : RTree[T],
  pt : @type.Coord,
  r : Double,
) -> Array[T] {
  let out : Array[T] = []
  let max_dist_sq = r * r
  match self.root {
    None => ()
    Some(root) => locate_within_distance_recurse(root, pt, max_dist_sq, out)
  }
  out
}
