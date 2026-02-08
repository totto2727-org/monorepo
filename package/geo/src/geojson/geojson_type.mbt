///|
pub(all) enum GeoJSONType {
  FeatureCollection
  Feature
  Geometry(GeometryType)
} derive(Eq, Show)

///|
pub fn GeoJSONType::from_raw_geojson(
  json : Json,
  path : @json.JsonPath,
) -> GeoJSONType raise @json.JsonDecodeError {
  @json_helper.from_json_property_or_throw("type", json, path)
}

///|
pub impl ToJson for GeoJSONType with to_json(self) {
  match self {
    FeatureCollection => "FeatureCollection"
    Feature => "Feature"
    Geometry(geometry_type) => geometry_type.to_json()
  }
}

///|
pub impl FromJson for GeoJSONType with from_json(json, path) {
  match json {
    Json::String("FeatureCollection") => GeoJSONType::FeatureCollection
    Json::String("Feature") => GeoJSONType::Feature
    _ => GeoJSONType::Geometry(GeometryType::from_json(json, path))
  }
}
