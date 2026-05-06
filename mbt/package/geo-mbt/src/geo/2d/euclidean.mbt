// Ported from georust/geo
// https://github.com/georust/geo/blob/main/geo/src/algorithm/euclidean_distance.rs
// and line_measures/{euclidean,bearing,destination}.rs

///|
/// Euclidean distance between two coordinates.
pub fn euclidean_distance_coords(a : @type.Coord, b : @type.Coord) -> Double {
  let dx = b.x() - a.x()
  let dy = b.y() - a.y()
  (dx * dx + dy * dy).sqrt()
}

///|
/// Euclidean distance between two points.
pub fn euclidean_distance_points(a : @type.Point, b : @type.Point) -> Double {
  euclidean_distance_coords(a.coord(), b.coord())
}

///|
/// Squared Euclidean distance between two coordinates (skips the sqrt).
pub fn euclidean_distance_squared_coords(
  a : @type.Coord,
  b : @type.Coord,
) -> Double {
  let dx = b.x() - a.x()
  let dy = b.y() - a.y()
  dx * dx + dy * dy
}

///|
/// Euclidean distance from a coordinate to a line segment, clamped to the
/// segment's bounds.
pub fn euclidean_distance_coord_to_line(
  p : @type.Coord,
  l : @type.Line,
) -> Double {
  let v = l.delta()
  let w = p - l.start()
  let v_dot_v = v.dot(v)
  if v_dot_v == 0.0 {
    return euclidean_distance_coords(p, l.start())
  }
  let t = w.dot(v) / v_dot_v
  let clamped = if t < 0.0 { 0.0 } else if t > 1.0 { 1.0 } else { t }
  let projection = l.start() + v.mul(clamped)
  euclidean_distance_coords(p, projection)
}

///|
/// Euclidean distance from a point to a line segment.
pub fn euclidean_distance_point_to_line(
  p : @type.Point,
  l : @type.Line,
) -> Double {
  euclidean_distance_coord_to_line(p.coord(), l)
}

///|
/// Euclidean distance from a coordinate to a `LineString`. Returns
/// `Double::infinity()` if the line string has fewer than 2 coordinates.
pub fn euclidean_distance_coord_to_line_string(
  p : @type.Coord,
  ls : @type.LineString,
) -> Double {
  ls
  .lines_iter()
  .fold(init=@double.infinity, fn(acc, seg) {
    let d = euclidean_distance_coord_to_line(p, seg)
    if d < acc {
      d
    } else {
      acc
    }
  })
}

///|
/// Euclidean length of a line segment: `sqrt(dx² + dy²)`.
pub fn euclidean_length_line(l : @type.Line) -> Double {
  euclidean_distance_coords(l.start(), l.end())
}

///|
/// Sum of segment lengths in a `LineString`. An empty or single-coord line
/// string has length zero.
pub fn euclidean_length_line_string(ls : @type.LineString) -> Double {
  ls
  .lines_iter()
  .fold(init=0.0, fn(acc, line) { acc + euclidean_length_line(line) })
}

///|
/// Sum of segment lengths in a `MultiLineString`.
pub fn euclidean_length_multi_line_string(
  mls : @type.MultiLineString,
) -> Double {
  mls
  .line_strings()
  .iter()
  .fold(init=0.0, fn(acc, ls) { acc + euclidean_length_line_string(ls) })
}

///|
/// Bearing in degrees from `origin` to `destination` in a planar Euclidean
/// frame. `0` is east (positive x); angle increases counter-clockwise.
/// Returns NaN if origin == destination.
pub fn euclidean_bearing(
  origin : @type.Coord,
  destination : @type.Coord,
) -> Double {
  let dx = destination.x() - origin.x()
  let dy = destination.y() - origin.y()
  @math.atan2(dy, dx) * 180.0 / 3.14159265358979323846
}

///|
/// Returns the destination coordinate when starting at `origin`, heading at
/// `bearing` degrees (0 = east, CCW), and travelling `distance` units in a
/// planar Euclidean frame.
pub fn euclidean_destination(
  origin : @type.Coord,
  bearing_degrees : Double,
  distance : Double,
) -> @type.Coord {
  let radians = bearing_degrees * 3.14159265358979323846 / 180.0
  @type.Coord(
    origin.x() + distance * @math.cos(radians),
    origin.y() + distance * @math.sin(radians),
  )
}
