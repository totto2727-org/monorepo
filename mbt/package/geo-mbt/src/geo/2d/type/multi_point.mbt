// Ported from georust/geo-types
// https://github.com/georust/geo/blob/main/geo-types/src/geometry/multi_point.rs

///|
/// A collection of `Point`s. Can be created from a list of points, or from
/// tuples / coords via the helper constructors.
pub struct MultiPoint {
  points : Array[Point]
} derive(Eq, Debug)

///|
pub fn MultiPoint::MultiPoint(points : Array[Point]) -> MultiPoint {
  MultiPoint::{ points, }
}

///|
pub fn MultiPoint::from_tuples(tuples : Array[(Double, Double)]) -> MultiPoint {
  MultiPoint::{ points: tuples.map(Point::from_tuple) }
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
