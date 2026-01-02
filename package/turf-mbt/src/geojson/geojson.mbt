///|
/// Union of GeoJSON objects.
pub enum GeoJSON {
  Feature(Feature)
  FeatureCollection(FeatureCollection)
  Geometry(Geometry)
} derive(Show, Eq)

///|
pub trait ToGeoJSON {
  to_geojson(Self) -> GeoJSON
}

///|
pub fn GeoJSON::from_geometry(geometry : Geometry) -> GeoJSON {
  GeoJSON::Geometry(geometry)
}

///|
pub impl GeometryToBBox for GeoJSON with to_bbox(
  self,
  re_compute? : Bool = false,
) {
  match self {
    GeoJSON::Feature(feature) => feature.to_bbox(re_compute~)
    GeoJSON::FeatureCollection(feature_collection) =>
      feature_collection.to_bbox(re_compute~)
    GeoJSON::Geometry(geometry) => geometry.to_bbox(re_compute~)
  }
}

///|
pub impl ToGeoJSONObject for GeoJSON with to_geojson_object(self) {
  match self {
    GeoJSON::Feature(feature) => feature.to_geojson_object()
    GeoJSON::FeatureCollection(feature_collection) =>
      feature_collection.to_geojson_object()
    GeoJSON::Geometry(geometry) => geometry.to_geojson_object()
  }
}

///|
pub impl ToJson for GeoJSON with to_json(self) {
  match self {
    GeoJSON::Feature(feature) => feature.to_json()
    GeoJSON::FeatureCollection(feature_collection) =>
      feature_collection.to_json()
    GeoJSON::Geometry(geometry) => geometry.to_json()
  }
}

///|
pub impl FromJson for GeoJSON with from_json(json, path) {
  match GeoJSONObject::from_json(json, path)._type {
    Feature => Feature::from_json(json, path).to_geojson()
    FeatureCollection => FeatureCollection::from_json(json, path).to_geojson()
    // TODO: from_geometry -> to_geojson
    Geometry(_) => Geometry::from_json(json, path) |> GeoJSON::from_geometry
  }
}
