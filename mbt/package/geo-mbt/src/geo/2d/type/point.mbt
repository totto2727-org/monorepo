// Ported from georust/geo-types
// https://github.com/georust/geo/blob/main/geo-types/src/geometry/point.rs

///|
/// A single point in 2D space.
///
/// # Semantics
///
/// The _interior_ of the point is itself (a singleton set), and its _boundary_
/// is empty. A point is _valid_ if and only if its `Coord` is valid.
pub struct Point {
  coord : Coord
} derive(Eq, Debug, Hash, Default)

///|
/// Creates a new point.
pub fn Point::Point(x : Double, y : Double) -> Point {
  Point::{ coord: Coord(x, y) }
}

///|
/// Creates a point from a `Coord`.
pub fn Point::from_coord(c : Coord) -> Point {
  Point::{ coord: c }
}

///|
/// Creates a point from a `(x, y)` tuple.
pub fn Point::from_tuple(t : (Double, Double)) -> Point {
  Point::{ coord: Coord(t.0, t.1) }
}

///|
/// Returns the underlying `Coord`.
pub fn Point::coord(self : Point) -> Coord {
  self.coord
}

///|
/// Returns the `x`/horizontal component.
pub fn Point::x(self : Point) -> Double {
  self.coord.x()
}

///|
/// Returns the `y`/vertical component.
pub fn Point::y(self : Point) -> Double {
  self.coord.y()
}

///|
/// Returns a `(x, y)` tuple.
pub fn Point::x_y(self : Point) -> (Double, Double) {
  self.coord.x_y()
}

///|
/// Returns a new point with `x` set, the original `y` preserved.
pub fn Point::with_x(self : Point, x : Double) -> Point {
  Point::{ coord: Coord(x, self.coord.y()) }
}

///|
/// Returns a new point with `y` set, the original `x` preserved.
pub fn Point::with_y(self : Point, y : Double) -> Point {
  Point::{ coord: Coord(self.coord.x(), y) }
}

///|
/// Returns the dot product of the two points: `x1 * x2 + y1 * y2`.
pub fn Point::dot(self : Point, other : Point) -> Double {
  self.coord.dot(other.coord)
}

///|
/// Returns the cross product of three points.
///
/// A positive value implies `self → b → c` is counter-clockwise; a negative
/// value implies clockwise; zero implies collinear. This function is **not**
/// robust against floating-point error — see `src/robust/orient2d.mbt`.
pub fn Point::cross_prod(self : Point, b : Point, c : Point) -> Double {
  (b.x() - self.x()) * (c.y() - self.y()) -
  (b.y() - self.y()) * (c.x() - self.x())
}

///|
pub impl Neg for Point with neg(self) {
  Point::{ coord: -self.coord }
}

///|
pub impl Add for Point with add(self, other) {
  Point::{ coord: self.coord + other.coord }
}

///|
pub impl Sub for Point with sub(self, other) {
  Point::{ coord: self.coord - other.coord }
}

///|
/// Multiplies the point's coordinates by a scalar.
pub fn Point::mul(self : Point, scalar : Double) -> Point {
  Point::{ coord: self.coord.mul(scalar) }
}

///|
/// Divides the point's coordinates by a scalar.
pub fn Point::div(self : Point, scalar : Double) -> Point {
  Point::{ coord: self.coord.div(scalar) }
}
