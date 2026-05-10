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
/// Stores vertices as-given (no winding normalisation). Semantically equivalent
/// to upstream `Triangle::unchecked_winding`.
pub fn Triangle::Triangle(v0 : Coord, v1 : Coord, v2 : Coord) -> Triangle {
  Triangle::{ v0, v1, v2 }
}

///|
/// Creates a `Triangle` with counter-clockwise (CCW) winding.
///
/// Winding is determined by the signed double-area cross product
/// `(v1 − v0) × (v2 − v0)` (non-robust, matching geo-types
/// `Triangle::new`). If the input vertices are clockwise, `v1` and `v2`
/// are swapped to produce CCW winding. Collinear input is stored as-is.
pub fn Triangle::ccw(v0 : Coord, v1 : Coord, v2 : Coord) -> Triangle {
  let cross = (v1.x() - v0.x()) * (v2.y() - v0.y()) -
    (v1.y() - v0.y()) * (v2.x() - v0.x())
  if cross >= 0.0 {
    Triangle::Triangle(v0, v1, v2)
  } else {
    Triangle::Triangle(v0, v2, v1)
  }
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
