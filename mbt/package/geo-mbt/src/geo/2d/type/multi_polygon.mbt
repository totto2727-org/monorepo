// Ported from georust/geo-types
// https://github.com/georust/geo/blob/main/geo-types/src/geometry/multi_polygon.rs

///|
/// A collection of `Polygon`s.
pub struct MultiPolygon {
  polygons : Array[Polygon]
} derive(Eq, Debug)

///|
pub fn MultiPolygon::MultiPolygon(polygons : Array[Polygon]) -> MultiPolygon {
  MultiPolygon::{ polygons, }
}

///|
/// Creates an empty `MultiPolygon`. Mirrors Rust
/// `geo_types::MultiPolygon::empty`.
pub fn MultiPolygon::empty() -> MultiPolygon {
  MultiPolygon::MultiPolygon([])
}

///|
pub fn MultiPolygon::polygons(self : MultiPolygon) -> Array[Polygon] {
  self.polygons
}

///|
pub fn MultiPolygon::length(self : MultiPolygon) -> Int {
  self.polygons.length()
}

///|
pub fn MultiPolygon::is_empty(self : MultiPolygon) -> Bool {
  self.polygons.length() == 0
}
