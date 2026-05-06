// Ported from georust/geo-types
// https://github.com/georust/geo/blob/main/geo-types/src/geometry/coord.rs

///|
/// A lightweight struct used to store coordinates on the 2-dimensional Cartesian plane.
///
/// Unlike `Point` (which in the future may contain additional information such as
/// an envelope, a precision model, and spatial reference system information), a
/// `Coord` only contains ordinate values and accessor methods.
///
/// This type implements the vector-space operations: `add`, `sub`, `neg`, `zero`,
/// `mul`, `div` (the last two by scalar), and `dot`.
///
/// # Semantics
///
/// This type does not represent any geospatial primitive, but is used in their
/// definitions. The only requirement is that the coordinates it contains are
/// valid numbers (e.g. not `NaN`).
pub struct Coord {
  x : Double
  y : Double
} derive(Eq, Debug, Hash, Default)

///|
/// Creates a new `Coord` from the given `x` and `y` ordinate values.
pub fn Coord::Coord(x : Double, y : Double) -> Coord {
  Coord::{ x, y }
}

///|
/// Creates a `Coord` at the origin (0.0, 0.0).
pub fn Coord::zero() -> Coord {
  Coord::{ x: 0.0, y: 0.0 }
}

///|
/// Returns whether this `Coord` is at the origin.
pub fn Coord::is_zero(self : Coord) -> Bool {
  self.x == 0.0 && self.y == 0.0
}

///|
/// Returns the `x` component of this coordinate.
pub fn Coord::x(self : Coord) -> Double {
  self.x
}

///|
/// Returns the `y` component of this coordinate.
pub fn Coord::y(self : Coord) -> Double {
  self.y
}

///|
/// Returns a tuple `(x, y)` of this coordinate's components.
pub fn Coord::x_y(self : Coord) -> (Double, Double) {
  (self.x, self.y)
}

// Conversions ----------------------------------------------------------------

///|
/// Builds a `Coord` from a `(x, y)` tuple.
pub fn Coord::from_tuple(t : (Double, Double)) -> Coord {
  Coord::{ x: t.0, y: t.1 }
}

///|
/// Builds a `Coord` from a 2-element array `[x, y]`.
/// Aborts when the input length is not 2.
pub fn Coord::from_array(a : Array[Double]) -> Coord {
  if a.length() != 2 {
    abort("Coord::from_array expects an array of length 2")
  }
  Coord::{ x: a[0], y: a[1] }
}

///|
/// Builds a 2-element array `[x, y]`.
pub fn Coord::to_array(self : Coord) -> Array[Double] {
  [self.x, self.y]
}

// Arithmetic -----------------------------------------------------------------

///|
/// Negates this coordinate.
pub impl Neg for Coord with neg(self) {
  Coord::{ x: -self.x, y: -self.y }
}

///|
/// Adds two coordinates component-wise.
pub impl Add for Coord with add(self, other) {
  Coord::{ x: self.x + other.x, y: self.y + other.y }
}

///|
/// Subtracts another coordinate from this one component-wise.
pub impl Sub for Coord with sub(self, other) {
  Coord::{ x: self.x - other.x, y: self.y - other.y }
}

///|
/// Multiplies this coordinate component-wise by a scalar.
///
/// MoonBit's trait system cannot express the Rust `Mul<T>` overload across
/// different types, so we expose this as a regular method instead.
pub fn Coord::mul(self : Coord, scalar : Double) -> Coord {
  Coord::{ x: self.x * scalar, y: self.y * scalar }
}

///|
/// Divides this coordinate component-wise by a scalar.
///
/// MoonBit's trait system cannot express the Rust `Div<T>` overload across
/// different types, so we expose this as a regular method instead.
pub fn Coord::div(self : Coord, scalar : Double) -> Coord {
  Coord::{ x: self.x / scalar, y: self.y / scalar }
}

///|
/// Returns the dot product of this coordinate with another.
pub fn Coord::dot(self : Coord, other : Coord) -> Double {
  self.x * other.x + self.y * other.y
}

///|
/// Returns the 2D cross / wedge product (signed area of the parallelogram).
pub fn Coord::cross(self : Coord, other : Coord) -> Double {
  self.x * other.y - self.y * other.x
}
