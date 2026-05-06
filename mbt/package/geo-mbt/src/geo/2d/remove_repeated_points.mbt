// Ported from georust/geo
// https://github.com/georust/geo/blob/main/geo/src/algorithm/remove_repeated_points.rs

///|
/// Removes consecutive duplicate coordinates from a `LineString`.
pub fn remove_repeated_points_line_string(
  ls : @type.LineString,
) -> @type.LineString {
  let coords = ls.coords()
  let n = coords.length()
  if n == 0 {
    return ls
  }
  // Index-based filter chain: keep index 0 unconditionally, then keep
  // every other index iff its coord differs from the previous one.
  // Output length is variable, so iterator-collect is the immutable form.
  let kept = (0).until(n)
    .filter(fn(i) { i == 0 || coords[i] != coords[i - 1] })
    .map(fn(i) { coords[i] })
    .collect()
  @type.LineString::LineString(kept)
}

///|
/// Removes consecutive duplicate coordinates from each ring of a polygon.
pub fn remove_repeated_points_polygon(p : @type.Polygon) -> @type.Polygon {
  let exterior = remove_repeated_points_line_string(p.exterior())
  let interiors = p.interiors().map(remove_repeated_points_line_string)
  @type.Polygon::Polygon(exterior, interiors)
}
