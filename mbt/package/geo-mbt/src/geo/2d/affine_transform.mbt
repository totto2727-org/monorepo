// Ported from georust/geo
// https://github.com/georust/geo/blob/main/geo/src/algorithm/affine_ops.rs
// Adapted to a pair-of-rows struct: an `AffineTransform` is the named pair
// `{ row_x, row_y }` of `AffineRow`s. The full 3×3 row-major matrix it
// represents is
//   [[row_x.scale, row_x.skew,  row_x.translate],
//    [row_y.skew,  row_y.scale, row_y.translate],
//    [    0,            0,             1        ]]
// so applying it to `(x, y)` gives
//   x' = row_x.scale * x + row_x.skew * y + row_x.translate
//   y' = row_y.skew  * x + row_y.scale * y + row_y.translate
// (note the `scale` field of each row is the *diagonal* element of the
// matrix, so for `row_y` it pairs with `c.y()` and `skew` with `c.x()`).

///|
/// One row of the affine matrix:
/// `output = scale * own_axis + skew * other_axis + translate`.
pub struct AffineRow {
  scale : Double
  skew : Double
  translate : Double
} derive(Eq, Debug)

///|
/// Canonical constructor for `AffineRow`.
pub fn AffineRow::AffineRow(
  scale : Double,
  skew : Double,
  translate : Double,
) -> AffineRow {
  AffineRow::{ scale, skew, translate }
}

///|
/// 2D affine transformation: a pair of rows of the underlying 3×3 row-major
/// matrix. The implicit third row is `[0, 0, 1]`.
pub struct AffineTransform {
  row_x : AffineRow
  row_y : AffineRow
} derive(Eq, Debug)

///|
/// Canonical constructor for `AffineTransform`.
pub fn AffineTransform::AffineTransform(
  row_x : AffineRow,
  row_y : AffineRow,
) -> AffineTransform {
  AffineTransform::{ row_x, row_y }
}

///|
/// The identity affine transform: `(x, y) -> (x, y)`.
pub fn AffineTransform::identity() -> AffineTransform {
  AffineTransform(AffineRow(1.0, 0.0, 0.0), AffineRow(1.0, 0.0, 0.0))
}

///|
/// A pure translation by `(xoff, yoff)`.
pub fn AffineTransform::translate_xy(
  xoff : Double,
  yoff : Double,
) -> AffineTransform {
  AffineTransform(AffineRow(1.0, 0.0, xoff), AffineRow(1.0, 0.0, yoff))
}

///|
/// A pure (axis-aligned) scaling by `(xfact, yfact)`.
pub fn AffineTransform::scale_xy(
  xfact : Double,
  yfact : Double,
) -> AffineTransform {
  AffineTransform(AffineRow(xfact, 0.0, 0.0), AffineRow(yfact, 0.0, 0.0))
}

///|
/// A rotation around the origin by `degrees` (CCW positive).
///
/// Upstream Rust matrix is `[[cos, -sin, 0], [sin, cos, 0], [0,0,1]]`:
/// - row x: `a=cos, b=-sin` → `scale=cos, skew=-sin`
/// - row y: `d=sin, e=cos`  → `skew=sin, scale=cos`
pub fn AffineTransform::rotate_origin(degrees : Double) -> AffineTransform {
  let rad = degrees * 3.14159265358979323846 / 180.0
  let c = @math.cos(rad)
  let s = @math.sin(rad)
  AffineTransform(AffineRow(c, -s, 0.0), AffineRow(c, s, 0.0))
}

///|
/// Skew (shear) around the origin by `xs_degrees` and `ys_degrees`.
///
/// Upstream Rust matrix is `[[1, tan(xs), 0], [tan(ys), 1, 0], [0,0,1]]`:
/// - row x: `a=1, b=tan(xs)` → `scale=1, skew=tan(xs)`
/// - row y: `d=tan(ys), e=1` → `skew=tan(ys), scale=1`
pub fn AffineTransform::skew_origin(
  xs_degrees : Double,
  ys_degrees : Double,
) -> AffineTransform {
  let tan_x = @math.tan(xs_degrees * 3.14159265358979323846 / 180.0)
  let tan_y = @math.tan(ys_degrees * 3.14159265358979323846 / 180.0)
  AffineTransform(AffineRow(1.0, tan_x, 0.0), AffineRow(1.0, tan_y, 0.0))
}

///|
/// Apply this transform to a coordinate.
pub fn AffineTransform::apply(
  self : AffineTransform,
  c : @type.Coord,
) -> @type.Coord {
  @type.Coord(
    self.row_x.scale * c.x() + self.row_x.skew * c.y() + self.row_x.translate,
    self.row_y.skew * c.x() + self.row_y.scale * c.y() + self.row_y.translate,
  )
}

///|
/// Compose two affine transforms: applying `self.compose(other)` to a coord
/// is equivalent to first applying `self`, then `other`. In matrix terms the
/// result is `other * self`.
pub fn AffineTransform::compose(
  self : AffineTransform,
  other : AffineTransform,
) -> AffineTransform {
  // Mapping back to upstream `(a, b, xoff, d, e, yoff)`:
  //   self.a    = self.row_x.scale,  self.b    = self.row_x.skew
  //   self.xoff = self.row_x.translate
  //   self.d    = self.row_y.skew,   self.e    = self.row_y.scale
  //   self.yoff = self.row_y.translate
  // (likewise for `other`).
  let new_x = AffineRow(
    other.row_x.scale * self.row_x.scale + other.row_x.skew * self.row_y.skew,
    other.row_x.scale * self.row_x.skew + other.row_x.skew * self.row_y.scale,
    other.row_x.scale * self.row_x.translate +
    other.row_x.skew * self.row_y.translate +
    other.row_x.translate,
  )
  let new_y = AffineRow(
    other.row_y.skew * self.row_x.scale + other.row_y.scale * self.row_y.skew,
    other.row_y.skew * self.row_x.skew + other.row_y.scale * self.row_y.scale,
    other.row_y.skew * self.row_x.translate +
    other.row_y.scale * self.row_y.translate +
    other.row_y.translate,
  )
  AffineTransform(new_x, new_y)
}

///|
/// Apply this transform to a geometry.
pub fn AffineTransform::transform_geometry(
  self : AffineTransform,
  g : @type.Geometry,
) -> @type.Geometry {
  map_coords_in_geometry(g, fn(c) { self.apply(c) })
}

///|
/// Apply this transform to a polygon.
pub fn AffineTransform::transform_polygon(
  self : AffineTransform,
  p : @type.Polygon,
) -> @type.Polygon {
  map_coords_in_polygon(p, fn(c) { self.apply(c) })
}

///|
/// Apply this transform to a line string.
pub fn AffineTransform::transform_line_string(
  self : AffineTransform,
  ls : @type.LineString,
) -> @type.LineString {
  map_coords_in_line_string(ls, fn(c) { self.apply(c) })
}

///|
/// Apply this transform to a point.
pub fn AffineTransform::transform_point(
  self : AffineTransform,
  p : @type.Point,
) -> @type.Point {
  map_coords_in_point(p, fn(c) { self.apply(c) })
}
