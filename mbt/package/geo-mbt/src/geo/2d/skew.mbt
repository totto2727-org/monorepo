// Ported from georust/geo
// https://github.com/georust/geo/blob/main/geo/src/algorithm/skew.rs

///|
/// Skew (shear) a geometry by `xs` and `ys` degrees, around the origin.
pub fn skew_geometry(
  g : @type.Geometry,
  xs_degrees : Double,
  ys_degrees : Double,
) -> @type.Geometry {
  affine_transform_geometry(
    g,
    AffineTransform::skew_origin(xs_degrees, ys_degrees),
  )
}

///|
/// Skew a geometry around the given pivot.
pub fn skew_geometry_around(
  g : @type.Geometry,
  xs_degrees : Double,
  ys_degrees : Double,
  pivot : @type.Coord,
) -> @type.Geometry {
  let to_origin = AffineTransform::translate_xy(-pivot.x(), -pivot.y())
  let skew = AffineTransform::skew_origin(xs_degrees, ys_degrees)
  let from_origin = AffineTransform::translate_xy(pivot.x(), pivot.y())
  affine_transform_geometry(g, to_origin.compose(skew).compose(from_origin))
}
