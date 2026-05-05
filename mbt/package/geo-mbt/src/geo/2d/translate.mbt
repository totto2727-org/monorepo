// Ported from georust/geo
// https://github.com/georust/geo/blob/main/geo/src/algorithm/translate.rs

///|
/// Translate a geometry by `(xoff, yoff)`.
pub fn translate_geometry(
  g : @type.Geometry,
  xoff : Double,
  yoff : Double,
) -> @type.Geometry {
  affine_transform_geometry(g, AffineTransform::translate_xy(xoff, yoff))
}

///|
pub fn translate_polygon(
  p : @type.Polygon,
  xoff : Double,
  yoff : Double,
) -> @type.Polygon {
  affine_transform_polygon(p, AffineTransform::translate_xy(xoff, yoff))
}

///|
pub fn translate_point(
  p : @type.Point,
  xoff : Double,
  yoff : Double,
) -> @type.Point {
  affine_transform_point(p, AffineTransform::translate_xy(xoff, yoff))
}
