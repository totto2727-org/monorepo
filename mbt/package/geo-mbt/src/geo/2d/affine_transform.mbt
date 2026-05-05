// Ported from georust/geo
// https://github.com/georust/geo/blob/main/geo/src/algorithm/affine_ops.rs
// Adapted to the simpler MoonBit struct (6-element row-major affine matrix
// representing [[a, b, xoff], [d, e, yoff], [0, 0, 1]]).

///|
/// 6-parameter row-major 2D affine transformation. Transforms `(x, y)` to:
///
/// - `x' = a * x + b * y + xoff`
/// - `y' = d * x + e * y + yoff`
pub struct AffineTransform {
  a : Double
  b : Double
  xoff : Double
  d : Double
  e : Double
  yoff : Double
} derive(Eq, Debug)

///|
pub fn AffineTransform::new(
  a : Double,
  b : Double,
  xoff : Double,
  d : Double,
  e : Double,
  yoff : Double,
) -> AffineTransform {
  AffineTransform::{ a, b, xoff, d, e, yoff }
}

///|
pub fn AffineTransform::identity() -> AffineTransform {
  AffineTransform::new(1.0, 0.0, 0.0, 0.0, 1.0, 0.0)
}

///|
pub fn AffineTransform::translate_xy(
  xoff : Double,
  yoff : Double,
) -> AffineTransform {
  AffineTransform::new(1.0, 0.0, xoff, 0.0, 1.0, yoff)
}

///|
pub fn AffineTransform::scale_xy(
  xfact : Double,
  yfact : Double,
) -> AffineTransform {
  AffineTransform::new(xfact, 0.0, 0.0, 0.0, yfact, 0.0)
}

///|
/// Builds a rotation transform around the origin. Angle is in degrees, CCW
/// positive (standard mathematical convention).
pub fn AffineTransform::rotate_origin(degrees : Double) -> AffineTransform {
  let rad = degrees * 3.14159265358979323846 / 180.0
  let c = @math.cos(rad)
  let s = @math.sin(rad)
  AffineTransform::new(c, -s, 0.0, s, c, 0.0)
}

///|
/// Skew (shear) by `xs` and `ys` degrees.
pub fn AffineTransform::skew_origin(
  xs_degrees : Double,
  ys_degrees : Double,
) -> AffineTransform {
  let tan_x = @math.tan(xs_degrees * 3.14159265358979323846 / 180.0)
  let tan_y = @math.tan(ys_degrees * 3.14159265358979323846 / 180.0)
  AffineTransform::new(1.0, tan_x, 0.0, tan_y, 1.0, 0.0)
}

///|
/// Apply this transform to a coordinate.
pub fn AffineTransform::apply(
  self : AffineTransform,
  c : @type.Coord,
) -> @type.Coord {
  @type.Coord::new(
    self.a * c.x() + self.b * c.y() + self.xoff,
    self.d * c.x() + self.e * c.y() + self.yoff,
  )
}

///|
/// Compose two affine transforms: applying `compose(a, b)` to a coord is
/// equivalent to first applying `a` then `b`.
pub fn AffineTransform::compose(
  self : AffineTransform,
  other : AffineTransform,
) -> AffineTransform {
  // self is applied first (gives intermediate coords), then `other`.
  // Multiplying matrices: result = other * self (since transforms apply
  // right-to-left when written `M_new = other_matrix * self_matrix`).
  AffineTransform::new(
    other.a * self.a + other.b * self.d,
    other.a * self.b + other.b * self.e,
    other.a * self.xoff + other.b * self.yoff + other.xoff,
    other.d * self.a + other.e * self.d,
    other.d * self.b + other.e * self.e,
    other.d * self.xoff + other.e * self.yoff + other.yoff,
  )
}

///|
/// Apply an affine transform to a geometry.
pub fn affine_transform_geometry(
  g : @type.Geometry,
  t : AffineTransform,
) -> @type.Geometry {
  map_coords_in_geometry(g, fn(c) { t.apply(c) })
}

///|
/// Apply an affine transform to a polygon.
pub fn affine_transform_polygon(
  p : @type.Polygon,
  t : AffineTransform,
) -> @type.Polygon {
  map_coords_in_polygon(p, fn(c) { t.apply(c) })
}

///|
/// Apply an affine transform to a line string.
pub fn affine_transform_line_string(
  ls : @type.LineString,
  t : AffineTransform,
) -> @type.LineString {
  map_coords_in_line_string(ls, fn(c) { t.apply(c) })
}

///|
/// Apply an affine transform to a point.
pub fn affine_transform_point(
  p : @type.Point,
  t : AffineTransform,
) -> @type.Point {
  map_coords_in_point(p, fn(c) { t.apply(c) })
}
