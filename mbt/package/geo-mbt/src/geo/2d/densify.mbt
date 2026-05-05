// Ported from georust/geo
// https://github.com/georust/geo/blob/main/geo/src/algorithm/line_measures/densify.rs

///|
/// Inserts intermediate coordinates along a `LineString` so that no segment
/// is longer than `max_segment_length`. Endpoints are preserved.
pub fn densify_line_string(
  ls : @type.LineString,
  max_segment_length : Double,
) -> @type.LineString {
  if max_segment_length <= 0.0 {
    return ls
  }
  let coords = ls.coords()
  if coords.length() < 2 {
    return ls
  }
  let result : Array[@type.Coord] = []
  result.push(coords[0])
  for i = 1; i < coords.length(); i = i + 1 {
    let start = coords[i - 1]
    let end = coords[i]
    let length = euclidean_distance_coords(start, end)
    if length > max_segment_length {
      let n_segments = (length / max_segment_length).ceil()
      let n = n_segments.to_int()
      for k = 1; k < n; k = k + 1 {
        let f = k.to_double() / n.to_double()
        result.push(
          @type.Coord::new(
            start.x() + (end.x() - start.x()) * f,
            start.y() + (end.y() - start.y()) * f,
          ),
        )
      }
    }
    result.push(end)
  }
  @type.LineString::new(result)
}

///|
/// Densifies each ring of a polygon.
pub fn densify_polygon(
  polygon : @type.Polygon,
  max_segment_length : Double,
) -> @type.Polygon {
  let exterior = densify_line_string(polygon.exterior(), max_segment_length)
  let interiors = polygon.interiors().map(fn(ls) {
    densify_line_string(ls, max_segment_length)
  })
  @type.Polygon::new(exterior, interiors)
}
