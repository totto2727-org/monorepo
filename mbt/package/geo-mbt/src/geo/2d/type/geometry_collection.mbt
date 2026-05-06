// Ported from georust/geo-types
// https://github.com/georust/geo/blob/main/geo-types/src/geometry/geometry_collection.rs

///|
/// A collection of `Geometry` values. Useful for representing heterogeneous
/// collections (the GeoJSON `GeometryCollection`).
pub struct GeometryCollection {
  geometries : Array[Geometry]
} derive(Eq, Debug, Default)

///|
pub fn GeometryCollection::GeometryCollection(
  geometries : Array[Geometry],
) -> GeometryCollection {
  GeometryCollection::{ geometries, }
}

///|
/// Creates an empty `GeometryCollection`. Mirrors Rust
/// `geo_types::GeometryCollection::empty`.
pub fn GeometryCollection::empty() -> GeometryCollection {
  GeometryCollection::GeometryCollection([])
}

///|
pub fn GeometryCollection::geometries(
  self : GeometryCollection,
) -> Array[Geometry] {
  self.geometries
}

///|
pub fn GeometryCollection::length(self : GeometryCollection) -> Int {
  self.geometries.length()
}

///|
pub fn GeometryCollection::is_empty(self : GeometryCollection) -> Bool {
  self.geometries.length() == 0
}

///|
pub impl HasLength for GeometryCollection with length(self) {
  self.length()
}

///|
pub impl IsEmpty for GeometryCollection with is_empty(self) {
  self.is_empty()
}
