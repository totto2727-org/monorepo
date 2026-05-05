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

///|
/// Returns the closest point on a `Line` segment to the given `target`.
pub fn closest_point_on_line(
  line : @type.Line,
  target : @type.Coord,
) -> Closest {
  let v = line.delta()
  let w = target - line.start()
  let v_dot_v = v.dot(v)
  if v_dot_v == 0.0 {
    return if line.start() == target {
      Intersection(line.start())
    } else {
      SinglePoint(line.start())
    }
  }
  let t = w.dot(v) / v_dot_v
  let clamped = if t < 0.0 {
    0.0
  } else if t > 1.0 {
    1.0
  } else {
    t
  }
  let proj = line.start() + v.mul(clamped)
  if proj == target {
    Intersection(proj)
  } else {
    SinglePoint(proj)
  }
}

///|
/// Returns the closest point on a `LineString` to `target`. Returns
/// `Indeterminate` when there are no segments.
pub fn closest_point_on_line_string(
  ls : @type.LineString,
  target : @type.Coord,
) -> Closest {
  let segments = ls.lines()
  if segments.length() == 0 {
    return Indeterminate
  }
  let mut best : @type.Coord? = None
  let mut best_dist = @double.infinity
  let mut intersection_found = false
  for seg in segments {
    match closest_point_on_line(seg, target) {
      Intersection(c) => {
        intersection_found = true
        best = Some(c)
        break
      }
      SinglePoint(c) => {
        let d = euclidean_distance_squared_coords(c, target)
        if d < best_dist {
          best_dist = d
          best = Some(c)
        }
      }
      _ => continue
    }
  }
  match best {
    Some(c) =>
      if intersection_found {
        Intersection(c)
      } else {
        SinglePoint(c)
      }
    None => Indeterminate
  }
}
