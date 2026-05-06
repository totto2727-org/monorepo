// Ported from georust/geo-types
// https://github.com/georust/geo/blob/main/geo-types/src/geometry/triangle.rs

///|
/// A bounded 2D area whose three vertices are defined by `Coord`s.
pub struct Triangle {
  v0 : Coord
  v1 : Coord
  v2 : Coord
} derive(Eq, Debug, Hash)

///|
pub fn Triangle::Triangle(v0 : Coord, v1 : Coord, v2 : Coord) -> Triangle {
  Triangle::{ v0, v1, v2 }
}

///|
pub fn Triangle::v0(self : Triangle) -> Coord {
  self.v0
}

///|
pub fn Triangle::v1(self : Triangle) -> Coord {
  self.v1
}

///|
pub fn Triangle::v2(self : Triangle) -> Coord {
  self.v2
}

///|
/// Returns the three line segments that make up this triangle in `(v0->v1,
/// v1->v2, v2->v0)` order.
pub fn Triangle::to_lines(self : Triangle) -> Array[Line] {
  [
    Line::Line(self.v0, self.v1),
    Line::Line(self.v1, self.v2),
    Line::Line(self.v2, self.v0),
  ]
}

///|
/// Converts to a closed `Polygon` representation.
pub fn Triangle::to_polygon(self : Triangle) -> Polygon {
  let exterior = LineString::LineString([self.v0, self.v1, self.v2, self.v0])
  Polygon::Polygon(exterior, [])
}
