// Ported from georust/geo
// https://github.com/georust/geo/blob/main/geo/src/algorithm/scale.rs

///|
/// Scale a geometry by `(xfact, yfact)` around `origin`.
pub fn scale_geometry_around(
  g : @type.Geometry,
  xfact : Double,
  yfact : Double,
  origin : @type.Coord,
) -> @type.Geometry {
  let to_origin = AffineTransform::translate_xy(-origin.x(), -origin.y())
  let scaling = AffineTransform::scale_xy(xfact, yfact)
  let from_origin = AffineTransform::translate_xy(origin.x(), origin.y())
  let combined = to_origin.compose(scaling).compose(from_origin)
  affine_transform_geometry(g, combined)
}

///|
/// Uniform scale around the origin.
pub fn scale_geometry(g : @type.Geometry, factor : Double) -> @type.Geometry {
  affine_transform_geometry(g, AffineTransform::scale_xy(factor, factor))
}
