// Ported from georust/geo-types
// https://github.com/georust/geo/blob/main/geo-types/src/geometry/line.rs

///|
/// A line segment made up of exactly two `Coord`s.
///
/// # Semantics
///
/// The _interior_ and _boundary_ are defined as with a `LineString` containing
/// only the two end points.
pub struct Line {
  start : Coord
  end : Coord
} derive(Eq, Debug, Hash)

///|
/// Creates a new line segment from two coordinates.
pub fn Line::Line(start : Coord, end : Coord) -> Line {
  Line::{ start, end }
}

///|
/// Creates a new line segment from `(x, y)` tuples.
pub fn Line::from_tuples(
  start : (Double, Double),
  end : (Double, Double),
) -> Line {
  Line::{ start: Coord::from_tuple(start), end: Coord::from_tuple(end) }
}

///|
/// Returns the start coordinate.
pub fn Line::start(self : Line) -> Coord {
  self.start
}

///|
/// Returns the end coordinate.
pub fn Line::end(self : Line) -> Coord {
  self.end
}

///|
/// Returns the start point.
pub fn Line::start_point(self : Line) -> Point {
  Point::from_coord(self.start)
}

///|
/// Returns the end point.
pub fn Line::end_point(self : Line) -> Point {
  Point::from_coord(self.end)
}

///|
/// Returns `(start_point, end_point)`.
pub fn Line::points(self : Line) -> (Point, Point) {
  (self.start_point(), self.end_point())
}

///|
/// Calculates the difference in coordinates `(Δx, Δy)`.
pub fn Line::delta(self : Line) -> Coord {
  self.end - self.start
}

///|
/// Calculates the difference in `x` components (Δx).
pub fn Line::dx(self : Line) -> Double {
  self.end.x() - self.start.x()
}

///|
/// Calculates the difference in `y` components (Δy).
pub fn Line::dy(self : Line) -> Double {
  self.end.y() - self.start.y()
}

///|
/// Calculates the slope `Δy / Δx`.
pub fn Line::slope(self : Line) -> Double {
  self.dy() / self.dx()
}

///|
/// Calculates the determinant `start.x * end.y - start.y * end.x`.
pub fn Line::determinant(self : Line) -> Double {
  self.start.x() * self.end.y() - self.start.y() * self.end.x()
}
