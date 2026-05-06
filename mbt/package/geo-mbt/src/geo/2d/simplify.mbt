// Ported from georust/geo
// https://github.com/georust/geo/blob/main/geo/src/algorithm/simplify.rs

///|
/// Recursive Ramer-Douglas-Peucker. Adds the indices of retained coords to
/// `keep` (except for the start and end which are always kept). The caller
/// adds the start/end indices once at the top level.
fn rdp_recurse(
  coords : Array[@type.Coord],
  start : Int,
  end : Int,
  epsilon : Double,
  keep : Array[Int],
) -> Unit {
  if end <= start + 1 {
    return
  }
  let line = @type.Line::Line(coords[start], coords[end])
  let mut max_dist = 0.0
  let mut max_index = start
  for i = start + 1; i < end; i = i + 1 {
    let d = euclidean_distance_coord_to_line(coords[i], line)
    if d > max_dist {
      max_dist = d
      max_index = i
    }
  }
  if max_dist > epsilon {
    rdp_recurse(coords, start, max_index, epsilon, keep)
    keep.push(max_index)
    rdp_recurse(coords, max_index, end, epsilon, keep)
  }
}

///|
/// Simplifies a `LineString` using the Ramer-Douglas-Peucker algorithm.
/// Coordinates whose perpendicular distance to the working segment is less
/// than `epsilon` are removed.
pub fn simplify_line_string(
  ls : @type.LineString,
  epsilon : Double,
) -> @type.LineString {
  let coords = ls.coords()
  if coords.length() < 3 {
    return ls
  }
  let kept_indices : Array[Int] = []
  kept_indices.push(0)
  rdp_recurse(coords, 0, coords.length() - 1, epsilon, kept_indices)
  kept_indices.push(coords.length() - 1)
  @type.LineString::LineString(kept_indices.map(fn(idx) { coords[idx] }))
}

///|
/// Returns the indices of the coordinates retained when simplifying with the
/// RDP algorithm.
pub fn simplify_line_string_indices(
  ls : @type.LineString,
  epsilon : Double,
) -> Array[Int] {
  let coords = ls.coords()
  if coords.length() < 3 {
    return Array::makei(coords.length(), fn(i) { i })
  }
  let kept_indices : Array[Int] = []
  kept_indices.push(0)
  rdp_recurse(coords, 0, coords.length() - 1, epsilon, kept_indices)
  kept_indices.push(coords.length() - 1)
  kept_indices
}

///|
/// Simplifies a `Polygon` by simplifying each ring with RDP.
pub fn simplify_polygon(
  polygon : @type.Polygon,
  epsilon : Double,
) -> @type.Polygon {
  let exterior = simplify_line_string(polygon.exterior(), epsilon)
  let interiors = polygon
    .interiors()
    .map(fn(ls) { simplify_line_string(ls, epsilon) })
  @type.Polygon::Polygon(exterior, interiors)
}
