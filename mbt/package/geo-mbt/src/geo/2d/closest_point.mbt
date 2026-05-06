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
