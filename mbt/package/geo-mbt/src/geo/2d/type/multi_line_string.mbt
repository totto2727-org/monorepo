// Ported from georust/geo-types
// https://github.com/georust/geo/blob/main/geo-types/src/geometry/multi_line_string.rs

///|
/// A collection of `LineString`s.
pub struct MultiLineString {
  line_strings : Array[LineString]
} derive(Eq, Debug)

///|
pub fn MultiLineString::new(
  line_strings : Array[LineString],
) -> MultiLineString {
  MultiLineString::{ line_strings, }
}

///|
pub fn MultiLineString::line_strings(
  self : MultiLineString,
) -> Array[LineString] {
  self.line_strings
}

///|
pub fn MultiLineString::length(self : MultiLineString) -> Int {
  self.line_strings.length()
}

///|
pub fn MultiLineString::is_empty(self : MultiLineString) -> Bool {
  self.line_strings.length() == 0
}

///|
/// Returns whether **all** line strings inside are closed. An empty multi line
/// string is considered closed.
pub fn MultiLineString::is_closed(self : MultiLineString) -> Bool {
  for ls in self.line_strings {
    if !ls.is_closed() {
      return false
    }
  }
  true
}
