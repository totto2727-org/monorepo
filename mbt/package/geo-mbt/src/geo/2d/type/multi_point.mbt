// Ported from georust/geo-types
// https://github.com/georust/geo/blob/main/geo-types/src/geometry/multi_point.rs

///|
/// A collection of `Point`s. Can be created from a list of points, or from
/// tuples / coords via the helper constructors.
pub struct MultiPoint {
  points : Array[Point]
} derive(Eq, Debug, Default)

///|
pub fn MultiPoint::MultiPoint(points : Array[Point]) -> MultiPoint {
  MultiPoint::{ points, }
}

///|
pub fn MultiPoint::from_tuples(tuples : Array[(Double, Double)]) -> MultiPoint {
  MultiPoint::MultiPoint(tuples.map(Point::from_tuple))
}

///|
/// Creates a `MultiPoint` containing a single `Point`.
pub fn MultiPoint::from_point(p : Point) -> MultiPoint {
  MultiPoint::MultiPoint([p])
}

///|
/// Creates a `MultiPoint` containing a single `Coord`.
pub fn MultiPoint::from_coord(c : Coord) -> MultiPoint {
  MultiPoint::MultiPoint([Point::from_coord(c)])
}

///|
/// Creates a `MultiPoint` from an `Array[Coord]`.
pub fn MultiPoint::from_coords(coords : Array[Coord]) -> MultiPoint {
  MultiPoint::MultiPoint(coords.map(Point::from_coord))
}

///|
/// Creates an empty `MultiPoint`. Mirrors Rust `geo_types::MultiPoint::empty`.
pub fn MultiPoint::empty() -> MultiPoint {
  MultiPoint::MultiPoint([])
}

///|
pub fn MultiPoint::points(self : MultiPoint) -> Array[Point] {
  self.points
}

///|
pub impl HasLength for MultiPoint with fn length(self) {
  self.points.length()
}

///|
pub impl IsEmpty for MultiPoint with fn is_empty(self) {
  self.points.length() == 0
}
