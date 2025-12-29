///|
/// The value values for the "type" property of GeoJSON Objects.
/// https://tools.ietf.org/html/rfc7946#section-1.4
pub enum GeoJSONTypes {
  Geometry(GeoJSONGeometryTypes)
  Feature
  FeatureCollection
} derive(Show, Eq, Compare, Hash)

///|
pub fn GeoJSONTypes::geometry(geometry : GeoJSONGeometryTypes) -> GeoJSONTypes {
  GeoJSONTypes::Geometry(geometry)
}

///|
pub fn GeoJSONTypes::feature() -> GeoJSONTypes {
  GeoJSONTypes::Feature
}

///|
pub fn GeoJSONTypes::feature_collection() -> GeoJSONTypes {
  GeoJSONTypes::FeatureCollection
}

///|
pub impl ToJson for GeoJSONTypes with to_json(self) {
  match self {
    GeoJSONTypes::Geometry(geometry) => geometry.to_json()
    GeoJSONTypes::Feature => "Feature"
    GeoJSONTypes::FeatureCollection => "FeatureCollection"
  }
}

///|
pub impl FromJson for GeoJSONTypes with from_json(json, path) {
  match json {
    String("Feature") => GeoJSONTypes::Feature
    String("FeatureCollection") => GeoJSONTypes::FeatureCollection
    json => GeoJSONTypes::Geometry(GeoJSONGeometryTypes::from_json(json, path))
  }
}

///|
pub trait ToGeoJSONTypes {
  to_geojson_types(Self) -> GeoJSONTypes
}
