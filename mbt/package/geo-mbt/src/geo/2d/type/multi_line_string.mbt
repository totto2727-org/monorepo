// Ported from georust/geo-types
// https://github.com/georust/geo/blob/main/geo-types/src/geometry/multi_line_string.rs

///|
/// A collection of `LineString`s.
pub struct MultiLineString {
  line_strings : Array[LineString]
} derive(Eq, Debug, Default)

///|
pub fn MultiLineString::MultiLineString(
  line_strings : Array[LineString],
) -> MultiLineString {
  MultiLineString::{ line_strings, }
}

///|
/// Creates an empty `MultiLineString`. Mirrors Rust
/// `geo_types::MultiLineString::empty`.
pub fn MultiLineString::empty() -> MultiLineString {
  MultiLineString::MultiLineString([])
}

///|
pub fn MultiLineString::line_strings(
  self : MultiLineString,
) -> Array[LineString] {
  self.line_strings
}

///|
pub impl HasLength for MultiLineString with length(self) {
  self.line_strings.length()
}

///|
pub impl IsEmpty for MultiLineString with is_empty(self) {
  self.line_strings.length() == 0
}

///|
/// Returns whether **all** line strings inside are closed. An empty multi line
/// string is considered closed.
pub impl IsClosed for MultiLineString with is_closed(self) {
  self.line_strings.iter().all(IsClosed::is_closed)
}
