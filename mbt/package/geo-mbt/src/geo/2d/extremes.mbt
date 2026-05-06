// Ported from georust/geo
// https://github.com/georust/geo/blob/main/geo/src/algorithm/extremes.rs

///|
/// Indices and coordinates of the extreme points of a geometry along the four
/// cardinal directions.
pub(all) struct Outcome {
  x_min : @type.Coord
  x_max : @type.Coord
  y_min : @type.Coord
  y_max : @type.Coord
} derive(Eq, Debug)

///|
/// Canonical constructor for `Outcome`.
pub fn Outcome::Outcome(
  x_min : @type.Coord,
  x_max : @type.Coord,
  y_min : @type.Coord,
  y_max : @type.Coord,
) -> Outcome {
  Outcome::{ x_min, x_max, y_min, y_max }
}

///|
/// Returns the extremes (xmin, xmax, ymin, ymax) of a coordinate array. Returns
/// `None` for an empty array.
pub fn extremes_of_coords(coords : Array[@type.Coord]) -> Outcome? {
  if coords.length() == 0 {
    return None
  }
  let mut x_min = coords[0]
  let mut x_max = coords[0]
  let mut y_min = coords[0]
  let mut y_max = coords[0]
  for i = 1; i < coords.length(); i = i + 1 {
    let c = coords[i]
    if c.x() < x_min.x() {
      x_min = c
    }
    if c.x() > x_max.x() {
      x_max = c
    }
    if c.y() < y_min.y() {
      y_min = c
    }
    if c.y() > y_max.y() {
      y_max = c
    }
  }
  Some(Outcome(x_min, x_max, y_min, y_max))
}

///|
pub fn extremes_of_geometry(g : @type.Geometry) -> Outcome? {
  extremes_of_coords(coords_of_geometry(g))
}
