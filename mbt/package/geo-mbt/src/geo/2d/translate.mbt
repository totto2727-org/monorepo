// Ported from georust/geo
// https://github.com/georust/geo/blob/main/geo/src/algorithm/translate.rs

///|
/// Translate a geometry by `(xoff, yoff)`.
pub fn translate_geometry(
  g : @type.Geometry,
  xoff : Double,
  yoff : Double,
) -> @type.Geometry {
  AffineTransform::translate_xy(xoff, yoff).transform_geometry(g)
}

///|
pub fn translate_polygon(
  p : @type.Polygon,
  xoff : Double,
  yoff : Double,
) -> @type.Polygon {
  AffineTransform::translate_xy(xoff, yoff).transform_polygon(p)
}

///|
pub fn translate_point(
  p : @type.Point,
  xoff : Double,
  yoff : Double,
) -> @type.Point {
  AffineTransform::translate_xy(xoff, yoff).transform_point(p)
}
