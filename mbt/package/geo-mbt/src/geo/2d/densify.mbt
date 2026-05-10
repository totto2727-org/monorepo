// Ported from georust/geo
// https://github.com/georust/geo/blob/main/geo/src/algorithm/line_measures/densify.rs

///|
/// For one segment `start -> end`, returns the coordinates that should
/// follow `start` in the densified output: zero or more interpolated
/// coords (when the segment exceeds `max_segment_length`) followed by
/// `end`. The number of output coords is `ceil(length / max) + 1` minus
/// the leading `start` (which the caller has already emitted).
fn densify_one_segment(
  start : @type.Coord,
  end : @type.Coord,
  max_segment_length : Double,
) -> Array[@type.Coord] {
  let length = euclidean_distance_coords(start, end)
  if length <= max_segment_length {
    return [end]
  }
  let n_segments = (length / max_segment_length).ceil().to_int()
  // Yield n coords: k = 1..n where k = n is `end` itself (f = 1.0).
  Array::makei(n_segments, fn(k) {
    let f = (k + 1).to_double() / n_segments.to_double()
    @type.Coord(
      start.x() + (end.x() - start.x()) * f,
      start.y() + (end.y() - start.y()) * f,
    )
  })
}

///|
/// Inserts intermediate coordinates along a `LineString` so that no segment
/// is longer than `max_segment_length`. Endpoints are preserved.
fn densify_line_string(
  ls : @type.LineString,
  max_segment_length : Double,
) -> @type.LineString {
  if max_segment_length <= 0.0 {
    return ls
  }
  let coords = ls.coords()
  let n = coords.length()
  if n < 2 {
    return ls
  }
  // First coord is preserved as-is, then each segment's contribution
  // (interpolated coords + end) follows.
  let tail = (1)
    .until(n)
    .flat_map(fn(i) {
      densify_one_segment(coords[i - 1], coords[i], max_segment_length).iter()
    })
    .collect()
  @type.LineString::LineString([coords[0], ..tail])
}

///|
/// Densifies each ring of a polygon.
fn densify_polygon(
  polygon : @type.Polygon,
  max_segment_length : Double,
) -> @type.Polygon {
  let exterior = densify_line_string(polygon.exterior(), max_segment_length)
  let interiors = polygon
    .interiors()
    .map(fn(ls) { densify_line_string(ls, max_segment_length) })
  @type.Polygon::Polygon(exterior, interiors)
}

// MARK: trait Densify + impls -----------------------------------------------

///|
/// Densification with a maximum segment length. Returns a value of the same
/// type with extra coords inserted along long segments.
pub(open) trait Densify {
  densify(Self, Double) -> Self
}

///|
pub impl Densify for @type.LineString with densify(self, max_segment_length) {
  densify_line_string(self, max_segment_length)
}

///|
pub impl Densify for @type.Polygon with densify(self, max_segment_length) {
  densify_polygon(self, max_segment_length)
}
