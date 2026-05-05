// Ported from georust/geo
// https://github.com/georust/geo/blob/main/geo/src/algorithm/winding_order.rs

///|
/// The winding order of a `LineString` ring.
pub(all) enum WindingOrder {
  Clockwise
  CounterClockwise
} derive(Eq, Debug)

///|
/// Returns the winding order of a closed `LineString`. Returns `None` if the
/// signed area is zero (degenerate or open).
pub fn winding_order(ls : @type.LineString) -> WindingOrder? {
  let area = twice_signed_ring_area(ls)
  if area > 0.0 {
    Some(CounterClockwise)
  } else if area < 0.0 {
    Some(Clockwise)
  } else {
    None
  }
}

///|
/// Reverses the order of coordinates in a `LineString`, returning a new
/// `LineString`.
pub fn reverse_line_string(ls : @type.LineString) -> @type.LineString {
  let coords = ls.coords()
  let reversed = Array::new(capacity=coords.length())
  for i = coords.length() - 1; i >= 0; i = i - 1 {
    reversed.push(coords[i])
  }
  @type.LineString::new(reversed)
}
