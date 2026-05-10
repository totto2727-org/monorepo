// Ported from georust/geo
// https://github.com/georust/geo/blob/main/geo/src/algorithm/line_intersection.rs

///|
/// The result of intersecting two line segments.
pub(all) enum LineIntersection {
  /// A single point of intersection. The boolean is `true` if the
  /// intersection is a "proper" intersection (the segments cross each other
  /// in their interiors), `false` if it is at an endpoint of one or both
  /// segments.
  SinglePoint(@type.Coord, Bool)
  /// The two segments are collinear and overlap on a sub-segment.
  Collinear(@type.Line)
} derive(Eq, Debug)

///|
/// Returns the intersection of two line segments, if any.
pub fn line_intersection(l1 : @type.Line, l2 : @type.Line) -> LineIntersection? {
  let p1 = l1.start()
  let p2 = l1.end()
  let q1 = l2.start()
  let q2 = l2.end()
  let r = @type.Coord(p2.x() - p1.x(), p2.y() - p1.y())
  let s = @type.Coord(q2.x() - q1.x(), q2.y() - q1.y())
  let r_cross_s = r.x() * s.y() - r.y() * s.x()
  let q_minus_p = @type.Coord(q1.x() - p1.x(), q1.y() - p1.y())
  if r_cross_s == 0.0 {
    // Parallel
    let q_minus_p_cross_r = q_minus_p.x() * r.y() - q_minus_p.y() * r.x()
    if q_minus_p_cross_r != 0.0 {
      return None
    }
    // Collinear: find overlap
    // We project both segments onto the same axis and find the intersection
    let r_dot_r = r.dot(r)
    if r_dot_r == 0.0 {
      // l1 is a point
      if coord_on_line(p1, l2) {
        return Some(SinglePoint(p1, false))
      }
      return None
    }
    let t0 = q_minus_p.dot(r) / r_dot_r
    let q2_minus_p = @type.Coord(q2.x() - p1.x(), q2.y() - p1.y())
    let t1 = q2_minus_p.dot(r) / r_dot_r
    let (t_lo, t_hi) = if t0 < t1 { (t0, t1) } else { (t1, t0) }
    if t_hi < 0.0 || t_lo > 1.0 {
      return None
    }
    let clamp_lo = if t_lo < 0.0 { 0.0 } else { t_lo }
    let clamp_hi = if t_hi > 1.0 { 1.0 } else { t_hi }
    let start = @type.Coord(
      p1.x() + clamp_lo * r.x(),
      p1.y() + clamp_lo * r.y(),
    )
    let end = @type.Coord(p1.x() + clamp_hi * r.x(), p1.y() + clamp_hi * r.y())
    if start == end {
      return Some(SinglePoint(start, false))
    }
    return Some(Collinear(@type.Line::Line(start, end)))
  }
  // Not parallel
  let t = (q_minus_p.x() * s.y() - q_minus_p.y() * s.x()) / r_cross_s
  let u = (q_minus_p.x() * r.y() - q_minus_p.y() * r.x()) / r_cross_s
  if t < 0.0 || t > 1.0 || u < 0.0 || u > 1.0 {
    return None
  }
  let intersection = @type.Coord(p1.x() + t * r.x(), p1.y() + t * r.y())
  // Proper if both t and u are strictly inside (0, 1)
  let proper = t > 0.0 && t < 1.0 && u > 0.0 && u < 1.0
  Some(SinglePoint(intersection, proper))
}
