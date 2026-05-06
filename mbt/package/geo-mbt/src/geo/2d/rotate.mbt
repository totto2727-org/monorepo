// Ported from georust/geo
// https://github.com/georust/geo/blob/main/geo/src/algorithm/rotate.rs

///|
/// Rotate a geometry around `pivot` by `degrees` (CCW positive).
pub fn rotate_geometry_around(
  g : @type.Geometry,
  degrees : Double,
  pivot : @type.Coord,
) -> @type.Geometry {
  let to_origin = AffineTransform::translate_xy(-pivot.x(), -pivot.y())
  let rotation = AffineTransform::rotate_origin(degrees)
  let from_origin = AffineTransform::translate_xy(pivot.x(), pivot.y())
  let combined = to_origin.compose(rotation).compose(from_origin)
  affine_transform_geometry(g, combined)
}

///|
/// Rotate a geometry around its centroid (or 0 if centroid undefined).
pub fn rotate_geometry_around_centroid(
  g : @type.Geometry,
  degrees : Double,
) -> @type.Geometry {
  let pivot = match centroid_geometry(g) {
    Some(p) => p.coord()
    None => @type.Coord(0.0, 0.0)
  }
  rotate_geometry_around(g, degrees, pivot)
}
