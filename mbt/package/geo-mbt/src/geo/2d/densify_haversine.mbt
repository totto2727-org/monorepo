// Ported from georust/geo
// https://github.com/georust/geo/blob/main/geo/src/algorithm/densify_haversine.rs
// (and the metric-space `Densifiable` impls in
// `algorithm/line_measures/densify.rs` which the deprecated
// `densify_haversine` now delegates to)
//
// Inserts intermediate vertices into a geometry so no two consecutive
// coordinates are farther apart than `max_segment_length` along a haversine
// great-circle path. New vertices are interpolated by `Haversine()`-based
// `point_at_ratio_between`.

///|
/// Inserts haversine-interpolated points so consecutive coords are no farther
/// apart than `max_segment_length` (meters). Pushes intermediate points into
/// `out` (the caller controls the start/end push). Asserts
/// `max_segment_length > 0`.
fn densify_between_haversine(
  start : @type.Point,
  end : @type.Point,
  out : Array[@type.Point],
  max_segment_length : Double,
) -> Unit {
  let h = haversine()
  let dist = h.distance(start, end)
  let num_segments = @math.ceil(dist / max_segment_length).to_int()
  if num_segments <= 1 {
    return
  }
  let frac = 1.0 / num_segments.to_double()
  for k in 1..<num_segments {
    let ratio = frac * k.to_double()
    let p = point_at_ratio_between(start, end, ratio)
    out.push(p)
  }
}

///|
/// Densifies a `Line` along a haversine path. Returns a `LineString`
/// starting from `line.start()`, ending at `line.end()`, with intermediate
/// great-circle points inserted as needed.
pub fn densify_haversine_line(
  line : @type.Line,
  max_segment_length : Double,
) -> @type.LineString {
  let pts : Array[@type.Point] = []
  pts.push(@type.Point::from_coord(line.start()))
  densify_between_haversine(
    @type.Point::from_coord(line.start()),
    @type.Point::from_coord(line.end()),
    pts,
    max_segment_length,
  )
  pts.push(@type.Point::from_coord(line.end()))
  @type.LineString::LineString(pts.map(@type.Point::coord))
}

///|
/// Densifies a `LineString` along haversine paths. Empty input returns
/// `LineString::empty()`. Single-coord input returns the input unchanged.
pub fn densify_haversine_line_string(
  ls : @type.LineString,
  max_segment_length : Double,
) -> @type.LineString {
  let coords = ls.coords()
  let n = coords.length()
  if n == 0 {
    return @type.LineString::empty()
  }
  if n == 1 {
    return ls
  }
  let pts : Array[@type.Point] = []
  for i in 0..<(n - 1) {
    let start = @type.Point::from_coord(coords[i])
    let end = @type.Point::from_coord(coords[i + 1])
    pts.push(start)
    densify_between_haversine(start, end, pts, max_segment_length)
  }
  pts.push(@type.Point::from_coord(coords[n - 1]))
  @type.LineString::LineString(pts.map(@type.Point::coord))
}

///|
/// Densifies all rings of a `Polygon` along haversine paths.
pub fn densify_haversine_polygon(
  polygon : @type.Polygon,
  max_segment_length : Double,
) -> @type.Polygon {
  let exterior = densify_haversine_line_string(
    polygon.exterior(),
    max_segment_length,
  )
  let interiors = polygon
    .interiors()
    .map(fn(ring) { densify_haversine_line_string(ring, max_segment_length) })
  @type.Polygon::Polygon(exterior, interiors)
}

///|
/// Densifies all line strings of a `MultiLineString` along haversine paths.
pub fn densify_haversine_multi_line_string(
  mls : @type.MultiLineString,
  max_segment_length : Double,
) -> @type.MultiLineString {
  @type.MultiLineString::MultiLineString(
    mls
    .line_strings()
    .map(fn(ls) { densify_haversine_line_string(ls, max_segment_length) }),
  )
}

///|
/// Densifies all polygons of a `MultiPolygon` along haversine paths.
pub fn densify_haversine_multi_polygon(
  mp : @type.MultiPolygon,
  max_segment_length : Double,
) -> @type.MultiPolygon {
  @type.MultiPolygon::MultiPolygon(
    mp
    .polygons()
    .map(fn(p) { densify_haversine_polygon(p, max_segment_length) }),
  )
}
