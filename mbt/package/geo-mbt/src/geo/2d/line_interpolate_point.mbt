// Ported from georust/geo
// https://github.com/georust/geo/blob/main/geo/src/algorithm/line_interpolate_point.rs

///|
/// Returns the point along `line` at the given `fraction` of its length
/// (0.0 = start, 1.0 = end). Values outside [0, 1] are clamped.
pub fn line_interpolate_point(
  line : @type.Line,
  fraction : Double,
) -> @type.Point {
  let f = if fraction < 0.0 {
    0.0
  } else if fraction > 1.0 {
    1.0
  } else {
    fraction
  }
  @type.Point::from_coord(line.start() + line.delta().mul(f))
}

///|
/// Returns the point along `linestring` at the given `fraction` of its total
/// length. Returns `None` for empty / single-coord linestrings.
pub fn line_string_interpolate_point(
  ls : @type.LineString,
  fraction : Double,
) -> @type.Point? {
  let segments = ls.lines()
  if segments.length() == 0 {
    return None
  }
  let total_length = euclidean_length_line_string(ls)
  if total_length == 0.0 {
    return None
  }
  let f = if fraction < 0.0 {
    0.0
  } else if fraction > 1.0 {
    1.0
  } else {
    fraction
  }
  let target = f * total_length
  let mut accumulated = 0.0
  for seg in segments {
    let seg_length = euclidean_length_line(seg)
    if accumulated + seg_length >= target {
      let local_fraction = if seg_length == 0.0 {
        0.0
      } else {
        (target - accumulated) / seg_length
      }
      return Some(line_interpolate_point(seg, local_fraction))
    }
    accumulated = accumulated + seg_length
  }
  // Should not reach here, but return the last endpoint as a safe fallback.
  Some(@type.Point::from_coord(segments[segments.length() - 1].end()))
}
