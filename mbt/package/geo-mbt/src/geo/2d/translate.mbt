// Ported from georust/geo
// https://github.com/georust/geo/blob/main/geo/src/algorithm/translate.rs

///|
/// Translate a geometry by `(xoff, yoff)`. Callers working with concrete
/// `MapCoords` types (e.g. `Polygon`, `Point`) can call
/// `AffineTransform::translate_xy(xoff, yoff).transform(value)` directly.
pub fn translate_geometry(
  g : @type.Geometry,
  xoff : Double,
  yoff : Double,
) -> @type.Geometry {
  AffineTransform::translate_xy(xoff, yoff).transform(g)
}
