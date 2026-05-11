// Ported from georust/geo
// https://github.com/georust/geo/blob/main/geo/src/algorithm/dbscan.rs
// (and the related `outlier_detection.rs` LOF helper, which is folded
// into the trivial `dbscan_outliers` here — DBSCAN's noise label already
// answers "which points are outliers"; full LOF / ensemble outlier
// detection is a deferred follow-up.)
//
// DBSCAN groups points whose `eps`-neighbourhoods contain at least
// `min_pts` neighbours (counting the point itself) and labels the rest
// as noise. The R*-tree (`@rtree`) backs each per-point neighbour query
// so the sweep runs in `O(n log n)` for typical inputs instead of
// `O(n²)`. Cluster IDs are 1-based; `0` is reserved for noise so the
// returned `Array[Int]` reads naturally without an `Option` wrapper.

///|
/// Internal classification tag tracking each point's state during the
/// DBSCAN sweep.
priv enum PointState {
  Unvisited
  Noise
  Queued
  Clustered(Int)
}

///|
/// True iff `state` is one of the "still claimable" tags (`Unvisited`
/// or `Noise`). A noise point can be reclassified into a neighbouring
/// cluster as a border point during that cluster's expansion.
fn point_state_is_unassigned(state : PointState) -> Bool {
  match state {
    PointState::Unvisited => true
    PointState::Noise => true
    _ => false
  }
}

///|
/// DBSCAN cluster labels for each input point.
///
/// `eps` is the neighbourhood radius (Euclidean, not squared) and
/// `min_pts` is the minimum number of points (including the point
/// itself) required for a point to qualify as a core point. Returns
/// labels where `0` denotes noise and `1`, `2`, … denote cluster IDs
/// in the order clusters are discovered.
///
/// Edge cases mirror georust/geo:
/// - Empty input → empty result.
/// - `min_pts <= 0` or `min_pts > points.length()` → every label is `0`.
/// - With `min_pts == 1`, every point seeds its own cluster (no noise).
/// - With `eps == 0` and distinct coordinates, every label is `0` —
///   each neighbourhood holds only the point itself, which is `< 2`.
pub fn dbscan(
  points : Array[@type.Point],
  eps : Double,
  min_pts : Int,
) -> Array[Int] {
  let n = points.length()
  if n == 0 {
    return []
  }
  if min_pts <= 0 || min_pts > n {
    return Array::make(n, 0)
  }

  // Build an R*-tree of degenerate point rects so each entry's bbox is
  // the point itself. `locate_within_distance` then returns the indices
  // of every point whose Euclidean distance to the query is `<= eps`.
  let entries : Array[@rtree.Entry[Int]] = []
  for i = 0; i < n; i = i + 1 {
    let c = points[i].coord()
    entries.push(@rtree.Entry(@type.Rect::Rect(c, c), i))
  }
  let tree = @rtree.RTree::bulk_load(entries)
  let states : Array[PointState] = Array::make(n, PointState::Unvisited)
  let mut next_cluster_id = 1
  for point_idx = 0; point_idx < n; point_idx = point_idx + 1 {
    match states[point_idx] {
      PointState::Unvisited => {
        let neighbours = tree.locate_within_distance(
          points[point_idx].coord(),
          eps,
        )
        if neighbours.length() < min_pts {
          states[point_idx] = PointState::Noise
        } else {
          let cluster_id = next_cluster_id
          next_cluster_id = next_cluster_id + 1
          states[point_idx] = PointState::Clustered(cluster_id)
          // BFS expansion. `head` walks the queue without popping so
          // the queue itself stays append-only.
          let queue : Array[Int] = []
          for i = 0; i < neighbours.length(); i = i + 1 {
            let nbr = neighbours[i]
            if point_state_is_unassigned(states[nbr]) {
              states[nbr] = PointState::Queued
              queue.push(nbr)
            }
          }
          let mut head = 0
          while head < queue.length() {
            let current = queue[head]
            head = head + 1
            match states[current] {
              PointState::Queued => {
                states[current] = PointState::Clustered(cluster_id)
                let nbrs = tree.locate_within_distance(
                  points[current].coord(),
                  eps,
                )
                if nbrs.length() >= min_pts {
                  for j = 0; j < nbrs.length(); j = j + 1 {
                    let nb = nbrs[j]
                    if point_state_is_unassigned(states[nb]) {
                      states[nb] = PointState::Queued
                      queue.push(nb)
                    }
                  }
                }
              }
              _ => ()
            }
          }
        }
      }
      _ => ()
    }
  }
  let labels : Array[Int] = Array::make(n, 0)
  for i = 0; i < n; i = i + 1 {
    match states[i] {
      PointState::Clustered(id) => labels[i] = id
      _ => ()
    }
  }
  labels
}

///|
/// Returns the indices of points classified as noise (label `0`) by
/// `dbscan`. Equivalent to running `dbscan` and collecting every index
/// whose label is `0`.
pub fn dbscan_outliers(
  points : Array[@type.Point],
  eps : Double,
  min_pts : Int,
) -> Array[Int] {
  let labels = dbscan(points, eps, min_pts)
  let outliers : Array[Int] = []
  for i = 0; i < labels.length(); i = i + 1 {
    if labels[i] == 0 {
      outliers.push(i)
    }
  }
  outliers
}
