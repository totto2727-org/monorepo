// Ported from georust/geo
// https://github.com/georust/geo/blob/main/geo/src/algorithm/vector_ops.rs

///|
/// Euclidean distance from this coordinate to the origin: `sqrt(x² + y²)`.
pub fn magnitude(c : @type.Coord) -> Double {
  (c.x() * c.x() + c.y() * c.y()).sqrt()
}

///|
/// Squared distance from this coordinate to the origin (avoids the
/// `sqrt` when it is not needed): `x² + y²`.
pub fn magnitude_squared(c : @type.Coord) -> Double {
  c.x() * c.x() + c.y() * c.y()
}

///|
/// Rotate this coordinate around the origin by 90 degrees clockwise:
/// `(x, y) -> (-y, x)`.
pub fn left(c : @type.Coord) -> @type.Coord {
  @type.Coord::new(-c.y(), c.x())
}

///|
/// Rotate this coordinate around the origin by 90 degrees anti-clockwise:
/// `(x, y) -> (y, -x)`.
pub fn right(c : @type.Coord) -> @type.Coord {
  @type.Coord::new(c.y(), -c.x())
}

///|
/// Inner / dot product: `a · b = a.x * b.x + a.y * b.y`.
pub fn dot_product(a : @type.Coord, b : @type.Coord) -> Double {
  a.dot(b)
}

///|
/// 2D wedge / cross product: `a ∧ b = a.x * b.y - a.y * b.x`.
pub fn wedge_product(a : @type.Coord, b : @type.Coord) -> Double {
  a.cross(b)
}

///|
/// Returns whether both `x` and `y` are finite (not NaN, not infinity).
pub fn is_finite(c : @type.Coord) -> Bool {
  // MoonBit Double provides `is_inf` and `is_nan`.
  !c.x().is_inf() && !c.x().is_nan() && !c.y().is_inf() && !c.y().is_nan()
}

///|
/// Try to normalise this vector. Returns `None` if the result is not
/// finite (e.g. the input has zero magnitude that rounds to 0, or NaN /
/// infinite components).
pub fn try_normalize(c : @type.Coord) -> @type.Coord? {
  let mag = magnitude(c)
  let result = c.div(mag)
  if is_finite(result) {
    Some(result)
  } else {
    None
  }
}
