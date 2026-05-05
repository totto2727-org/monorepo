// Ported from georust/geo-types
// https://github.com/georust/geo/blob/main/geo-types/src/geometry/line_string.rs

///|
/// An ordered collection of two or more `Coord`s, representing a path between
/// locations.
///
/// # Semantics
///
/// - 0 or 1 points: empty interior and boundary, treated as invalid in many APIs.
/// - 2 or more points: interior is the union of the line segments; boundary is
///   the start and end coordinate (open) or empty (closed, i.e. start == end).
pub struct LineString {
  coords : Array[Coord]
} derive(Eq, Debug)

///|
/// Creates a new `LineString` from an array of `Coord`s.
pub fn LineString::new(coords : Array[Coord]) -> LineString {
  LineString::{ coords, }
}

///|
/// Creates a new `LineString` from `(x, y)` tuples.
pub fn LineString::from_tuples(tuples : Array[(Double, Double)]) -> LineString {
  let coords = tuples.map(Coord::from_tuple)
  LineString::{ coords, }
}

///|
/// Returns the underlying coordinate array.
pub fn LineString::coords(self : LineString) -> Array[Coord] {
  self.coords
}

///|
/// Returns the number of coordinates in the line string.
pub fn LineString::length(self : LineString) -> Int {
  self.coords.length()
}

///|
/// Returns whether the line string has no coordinates.
pub fn LineString::is_empty(self : LineString) -> Bool {
  self.coords.length() == 0
}

///|
/// Returns whether the line string is closed: the first and last coordinates
/// are equal. An empty line string is **not** closed.
pub fn LineString::is_closed(self : LineString) -> Bool {
  let n = self.coords.length()
  if n < 2 {
    return false
  }
  self.coords[0] == self.coords[n - 1]
}

///|
/// Returns the line segments composing this line string.
///
/// An empty line string and a single-coordinate line string yield an empty
/// segment array.
pub fn LineString::lines(self : LineString) -> Array[Line] {
  let n = self.coords.length()
  if n < 2 {
    return []
  }
  let result = Array::new(capacity=n - 1)
  for i = 0; i < n - 1; i = i + 1 {
    result.push(Line::new(self.coords[i], self.coords[i + 1]))
  }
  result
}

///|
/// Closes the line string in place by appending the start coordinate if it is
/// not already closed.
pub fn LineString::close(self : LineString) -> Unit {
  if !self.is_closed() && self.coords.length() > 0 {
    self.coords.push(self.coords[0])
  }
}
