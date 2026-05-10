// Ported from georust/geo
// https://github.com/georust/geo/blob/main/geo/src/algorithm/kmeans/mod.rs
//
// Lloyd's-algorithm k-means clustering. The georust implementation
// also adds k-means++ initialisation, Hamerly triangle-inequality
// pruning, empty-cluster recovery, and `max_radius` cluster splitting.
// This port favours clarity and ships the textbook Lloyd loop with the
// trivial "first k points" seeding strategy. The remaining knobs are
// deferred (see TODO ms-31-kmeans++ below) and can layer on top once
// profiling motivates them.
//
// TODO ms-31-kmeans++: replace the "first k points" seeding with the
// k-means++ probabilistic init for better initial centroid spread, and
// add Hamerly's bound-pruned assignment loop, empty-cluster recovery,
// and the `max_radius` post-split.

///|
/// K-means clustering with `k` clusters and at most `max_iter` Lloyd
/// iterations.
///
/// Returns `Some((centroids, labels))` where `centroids[j]` is the
/// final coordinate of cluster `j` and `labels[i]` is the cluster
/// assignment (`0..k-1`) for `points[i]`. Returns `None` for invalid
/// configurations:
/// - `points.length() == 0` — no points to cluster.
/// - `k <= 0` — at least one cluster is required.
/// - `k > points.length()` — not enough points to fill the clusters.
///
/// Initialisation: the first `k` input points seed the centroids.
/// k-means++ is left as a follow-up; for well-separated clusters in
/// the test set this baseline already converges to the global minimum.
///
/// Empty clusters produced during iteration keep their previous
/// centroid (no farthest-point recovery). Convergence is declared when
/// no assignment changes between two consecutive iterations.
pub fn kmeans(
  points : Array[@type.Point],
  k : Int,
  max_iter : Int,
) -> (Array[@type.Coord], Array[Int])? {
  let n = points.length()
  if k <= 0 || k > n {
    return None
  }
  // Init: pick the first `k` points as initial centroids.
  let centroids : Array[@type.Coord] = []
  for i = 0; i < k; i = i + 1 {
    centroids.push(points[i].coord())
  }
  // -1 sentinel forces the first iteration's reassignment to register a
  // change so we always do at least one centroid update before exiting.
  let assignments : Array[Int] = Array::make(n, -1)
  let mut iter = 0
  let mut keep_going = true
  while keep_going && iter < max_iter {
    let mut changed = false
    // Assignment step: each point goes to its nearest centroid (by
    // squared Euclidean distance — sqrt is unnecessary for argmin).
    for i = 0; i < n; i = i + 1 {
      let pc = points[i].coord()
      let mut best_idx = 0
      let mut best_d = euclidean_distance_squared_coords(pc, centroids[0])
      for j = 1; j < k; j = j + 1 {
        let d = euclidean_distance_squared_coords(pc, centroids[j])
        if d < best_d {
          best_d = d
          best_idx = j
        }
      }
      if assignments[i] != best_idx {
        assignments[i] = best_idx
        changed = true
      }
    }
    if !changed {
      keep_going = false
    } else {
      // Update step: each centroid becomes the mean of its members.
      let sums_x : Array[Double] = Array::make(k, 0.0)
      let sums_y : Array[Double] = Array::make(k, 0.0)
      let counts : Array[Int] = Array::make(k, 0)
      for i = 0; i < n; i = i + 1 {
        let c = points[i].coord()
        let cluster = assignments[i]
        sums_x[cluster] = sums_x[cluster] + c.x()
        sums_y[cluster] = sums_y[cluster] + c.y()
        counts[cluster] = counts[cluster] + 1
      }
      for j = 0; j < k; j = j + 1 {
        if counts[j] > 0 {
          let cnt = counts[j].to_double()
          centroids[j] = @type.Coord::Coord(sums_x[j] / cnt, sums_y[j] / cnt)
        }
      }
    }
    iter = iter + 1
  }
  Some((centroids, assignments))
}
