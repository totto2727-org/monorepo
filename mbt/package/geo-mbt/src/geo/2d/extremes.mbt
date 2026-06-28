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
  let init = (coords[0], coords[0], coords[0], coords[0])
  let acc = coords
    .iter()
    .fold(init~, fn(acc, c) {
      let x_min = if c.x() < acc.0.x() { c } else { acc.0 }
      let x_max = if c.x() > acc.1.x() { c } else { acc.1 }
      let y_min = if c.y() < acc.2.y() { c } else { acc.2 }
      let y_max = if c.y() > acc.3.y() { c } else { acc.3 }
      (x_min, x_max, y_min, y_max)
    })
  let (x_min, x_max, y_min, y_max) = acc
  Some(Outcome(x_min, x_max, y_min, y_max))
}

// MARK: trait HasExtremes + impls -------------------------------------------

///|
/// Anything whose extreme coordinates (xmin / xmax / ymin / ymax) can be
/// taken. Returns `None` when there are no coordinates at all.
pub(open) trait HasExtremes {
  fn extremes(Self) -> Outcome?
}

///|
pub impl HasExtremes for @type.Point with fn extremes(self) {
  extremes_of_coords(CoordsCarrier::coords(self))
}

///|
pub impl HasExtremes for @type.Line with fn extremes(self) {
  extremes_of_coords(CoordsCarrier::coords(self))
}

///|
pub impl HasExtremes for @type.LineString with fn extremes(self) {
  extremes_of_coords(CoordsCarrier::coords(self))
}

///|
pub impl HasExtremes for @type.MultiPoint with fn extremes(self) {
  extremes_of_coords(CoordsCarrier::coords(self))
}

///|
pub impl HasExtremes for @type.MultiLineString with fn extremes(self) {
  extremes_of_coords(CoordsCarrier::coords(self))
}

///|
pub impl HasExtremes for @type.Polygon with fn extremes(self) {
  extremes_of_coords(CoordsCarrier::coords(self))
}

///|
pub impl HasExtremes for @type.MultiPolygon with fn extremes(self) {
  extremes_of_coords(CoordsCarrier::coords(self))
}

///|
pub impl HasExtremes for @type.Rect with fn extremes(self) {
  extremes_of_coords(CoordsCarrier::coords(self))
}

///|
pub impl HasExtremes for @type.Triangle with fn extremes(self) {
  extremes_of_coords(CoordsCarrier::coords(self))
}

///|
pub impl HasExtremes for @type.GeometryCollection with fn extremes(self) {
  extremes_of_coords(CoordsCarrier::coords(self))
}

///|
pub impl HasExtremes for @type.Geometry with fn extremes(self) {
  extremes_of_coords(CoordsCarrier::coords(self))
}
