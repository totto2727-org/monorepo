// Ported from georust/geo
// https://github.com/georust/geo/blob/main/geo/src/algorithm/closest_point.rs

///|
/// Result of querying the closest point on a geometry.
pub(all) enum Closest {
  /// The query point is exactly on the geometry.
  Intersection(@type.Coord)
  /// A unique closest point that does not lie on the query.
  SinglePoint(@type.Coord)
  /// Multiple closest points equidistant — the geometry is degenerate or
  /// has been queried from a special location.
  Indeterminate
} derive(Eq, Debug)

// MARK: trait ClosestPoint + impls ------------------------------------------

///|
/// Computes the closest point on `self` to a target coordinate.
pub(open) trait ClosestPoint {
  fn closest_point(Self, @type.Coord) -> Closest
}

///|
pub impl ClosestPoint for @type.Line with fn closest_point(self, target) {
  let v = self.delta()
  let w = target - self.start()
  let v_dot_v = v.dot(v)
  if v_dot_v == 0.0 {
    return if self.start() == target {
      Intersection(self.start())
    } else {
      SinglePoint(self.start())
    }
  }
  let t = w.dot(v) / v_dot_v
  let clamped = if t < 0.0 { 0.0 } else if t > 1.0 { 1.0 } else { t }
  let proj = self.start() + v.mul(clamped)
  if proj == target {
    Intersection(proj)
  } else {
    SinglePoint(proj)
  }
}

///|
pub impl ClosestPoint for @type.LineString with fn closest_point(self, target) {
  let segments = self.lines()
  if segments.length() == 0 {
    return Indeterminate
  }
  // Fold tracks the best candidate so far. Once an `Intersection` is seen
  // the result is locked in and remains stable across the rest of the fold.
  segments
  .iter()
  .fold(init=Closest::Indeterminate, fn(acc, seg) {
    match acc {
      Intersection(_) => acc
      _ =>
        match ClosestPoint::closest_point(seg, target) {
          Intersection(c) => Intersection(c)
          SinglePoint(c) =>
            match acc {
              SinglePoint(prev) => {
                let d_new = euclidean_distance_squared_coords(c, target)
                let d_prev = euclidean_distance_squared_coords(prev, target)
                if d_new < d_prev {
                  SinglePoint(c)
                } else {
                  acc
                }
              }
              _ => SinglePoint(c)
            }
          Indeterminate => acc
        }
    }
  })
}
