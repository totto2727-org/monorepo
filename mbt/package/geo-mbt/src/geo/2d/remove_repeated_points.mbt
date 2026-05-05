// Ported from georust/geo
// https://github.com/georust/geo/blob/main/geo/src/algorithm/remove_repeated_points.rs

///|
/// Removes consecutive duplicate coordinates from a `LineString`.
pub fn remove_repeated_points_line_string(
  ls : @type.LineString,
) -> @type.LineString {
  let coords = ls.coords()
  if coords.length() == 0 {
    return ls
  }
  let result : Array[@type.Coord] = [coords[0]]
  for i = 1; i < coords.length(); i = i + 1 {
    if coords[i] != result[result.length() - 1] {
      result.push(coords[i])
    }
  }
  @type.LineString::new(result)
}

///|
/// Removes consecutive duplicate coordinates from each ring of a polygon.
pub fn remove_repeated_points_polygon(p : @type.Polygon) -> @type.Polygon {
  let exterior = remove_repeated_points_line_string(p.exterior())
  let interiors = p.interiors().map(remove_repeated_points_line_string)
  @type.Polygon::new(exterior, interiors)
}
