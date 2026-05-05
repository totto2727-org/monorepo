// Ported from georust/geo-types
// https://github.com/georust/geo/blob/main/geo-types/src/geometry/geometry_collection.rs

///|
/// A collection of `Geometry` values. Useful for representing heterogeneous
/// collections (the GeoJSON `GeometryCollection`).
pub struct GeometryCollection {
  geometries : Array[Geometry]
} derive(Eq, Debug)

///|
pub fn GeometryCollection::new(
  geometries : Array[Geometry],
) -> GeometryCollection {
  GeometryCollection::{ geometries, }
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
