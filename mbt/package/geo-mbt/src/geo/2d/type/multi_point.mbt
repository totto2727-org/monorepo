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
/// Creates an empty `MultiPoint`. Mirrors Rust `geo_types::MultiPoint::empty`.
pub fn MultiPoint::empty() -> MultiPoint {
  MultiPoint::MultiPoint([])
}

///|
pub fn MultiPoint::points(self : MultiPoint) -> Array[Point] {
  self.points
}

///|
pub fn MultiPoint::length(self : MultiPoint) -> Int {
  self.points.length()
}

///|
pub fn MultiPoint::is_empty(self : MultiPoint) -> Bool {
  self.points.length() == 0
}
