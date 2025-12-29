///|
/// The value values for the "type" property of GeoJSON Objects.
/// https://tools.ietf.org/html/rfc7946#section-1.4
pub enum GeoJsonTypes {
  Geometry(GeoJsonGeometryTypes)
  Feature
  FeatureCollection
} derive(Show, Eq, Compare, Hash)

///|
pub fn GeoJsonTypes::geometry(geometry : GeoJsonGeometryTypes) -> GeoJsonTypes {
  GeoJsonTypes::Geometry(geometry)
}

///|
pub fn GeoJsonTypes::feature() -> GeoJsonTypes {
  GeoJsonTypes::Feature
}

///|
pub fn GeoJsonTypes::feature_collection() -> GeoJsonTypes {
  GeoJsonTypes::FeatureCollection
}

///|
pub impl ToJson for GeoJsonTypes with to_json(self) {
  match self {
    GeoJsonTypes::Geometry(geometry) => geometry.to_json()
    GeoJsonTypes::Feature => "Feature"
    GeoJsonTypes::FeatureCollection => "FeatureCollection"
  }
}

///|
pub impl FromJson for GeoJsonTypes with from_json(json, path) {
  match json {
    String("Feature") => GeoJsonTypes::Feature
    String("FeatureCollection") => GeoJsonTypes::FeatureCollection
    json => GeoJsonTypes::Geometry(GeoJsonGeometryTypes::from_json(json, path))
  }
}

///|
pub trait ToGeoJsonTypes {
  to_geojson_types(Self) -> GeoJsonTypes
}
