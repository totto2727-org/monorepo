// Ported from georust/geo
// https://github.com/georust/geo/blob/main/geo/src/algorithm/line_locate_point.rs

///|
/// Returns the fraction (0..=1) along the line `line` corresponding to the
/// closest point to `target`. Returns `None` when the line is degenerate
/// (zero length).
pub fn line_locate_point(line : @type.Line, target : @type.Coord) -> Double? {
  let v = line.delta()
  let w = target - line.start()
  let v_dot_v = v.dot(v)
  if v_dot_v == 0.0 {
    return None
  }
  let t = w.dot(v) / v_dot_v
  let clamped = if t < 0.0 { 0.0 } else if t > 1.0 { 1.0 } else { t }
  Some(clamped)
}

///|
/// Returns the normalised position (0..=1) of the closest point on a
/// linestring to `target`, where the position is measured by total length.
pub fn line_string_locate_point(
  ls : @type.LineString,
  target : @type.Coord,
) -> Double? {
  let segments = ls.lines()
  if segments.length() == 0 {
    return None
  }
  let total_length = euclidean_length_line_string(ls)
  if total_length == 0.0 {
    return None
  }
  let mut accumulated = 0.0
  let mut best_position = 0.0
  let mut best_dist = @double.infinity
  for seg in segments {
    let seg_length = euclidean_length_line(seg)
    let location_in_seg = line_locate_point(seg, target).unwrap_or(0.0)
    let projection = seg.start() + seg.delta().mul(location_in_seg)
    let dist = euclidean_distance_squared_coords(projection, target)
    if dist < best_dist {
      best_dist = dist
      best_position = (accumulated + location_in_seg * seg_length) /
        total_length
    }
    accumulated = accumulated + seg_length
  }
  Some(best_position)
}
