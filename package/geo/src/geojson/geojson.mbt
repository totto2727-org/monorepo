///|
pub(open) trait FromGeoJSON {
  from_geojson_geometry(geometry : Geometry) -> Self raise InvalidGeoJSONError
}

///|
pub(open) trait ToGeoJSON {
  to_geojson(self : Self, with_bbox? : Bool) -> GeoJSON
}

///|
pub(all) enum GeoJSON {
  FeatureCollection(FeatureCollection)
  Feature(Feature)
  Geometry(Geometry)
} derive(Eq, Show)

///|
pub(open) trait GeoJSONTrait: FromJson + ToJson {
  to_json(self : Self, with_bbox? : Bool) -> Json
}

///|
pub impl GeoJSONTrait for GeoJSON with to_json(self, with_bbox? = false) {
  match self {
    Feature(feature) => GeoJSONTrait::to_json(feature, with_bbox~)
    FeatureCollection(feature_collection) =>
      GeoJSONTrait::to_json(feature_collection, with_bbox~)
    Geometry(geometry) => GeoJSONTrait::to_json(geometry, with_bbox~)
  }
}

///|
pub impl ToJson for GeoJSON with to_json(self) {
  GeoJSONTrait::to_json(self)
}

///|
pub impl FromJson for GeoJSON with from_json(json, path) {
  match GeoJSONType::from_raw_geojson(json, path) {
    GeoJSONType::FeatureCollection =>
      GeoJSON::FeatureCollection(FeatureCollection::from_json(json, path))
    GeoJSONType::Feature => GeoJSON::Feature(Feature::from_json(json, path))
    GeoJSONType::Geometry(_) =>
      GeoJSON::Geometry(Geometry::from_json(json, path))
  }
}

///|
pub impl BBoxTrait for GeoJSON with bbox(self) -> BBox {
  match self {
    FeatureCollection(fc) => fc.bbox()
    Feature(f) => f.bbox()
    Geometry(g) => g.bbox()
  }
}
