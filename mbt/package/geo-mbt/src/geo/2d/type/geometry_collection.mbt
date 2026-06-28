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
pub impl HasLength for GeometryCollection with fn length(self) {
  self.geometries.length()
}

///|
pub impl IsEmpty for GeometryCollection with fn is_empty(self) {
  self.geometries.length() == 0
}
