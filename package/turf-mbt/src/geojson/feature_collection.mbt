///|
/// FeatureCollection object.
/// https://tools.ietf.org/html/rfc7946#section-3.3
pub struct FeatureCollection {
  /// The array of features.
  features : Array[Feature]
  /// Bounding box.
  bbox : BBox?
} derive(Show, Eq)

///|
pub fn FeatureCollection::new(
  features : Array[Feature],
  bbox? : BBox? = None,
) -> FeatureCollection {
  FeatureCollection::{ features, bbox }
}

///|
pub impl ToGeoJSONTypes for FeatureCollection with to_geojson_types(_self) {
  GeoJSONTypes::FeatureCollection
}

///|
pub impl ToGeoJSONObject for FeatureCollection with to_geojson_object(self) {
  GeoJSONObject::new(self.to_geojson_types(), bbox=self.bbox)
}

///|
pub impl ToJson for FeatureCollection with to_json(self) {
  let map : Map[String, Json] = {}
  map.set("type", "FeatureCollection")
  map.set("features", self.features.to_json())
  match self.bbox {
    Some(bbox) => map.set("bbox", bbox.to_json())
    None => ()
  }
  map.to_json()
}

///|
pub impl FromJson for FeatureCollection with from_json(json, path) {
  let geojson_object : GeoJSONObject = @json.from_json(json, path~)
  if geojson_object._type != GeoJSONTypes::FeatureCollection {
    raise @json.JsonDecodeError((path, "Invalid FeatureCollection type"))
  }
  fn get_features_json() raise @json.JsonDecodeError {
    match json {
      Object(map) =>
        match map.get("features") {
          Some(Json::Array(_) as features) => features
          _ => raise @json.JsonDecodeError((path, "Invalid features"))
        }
      _ => raise @json.JsonDecodeError((path, "Invalid features"))
    }
  }

  let features : Array[Feature] = @json.from_json(get_features_json(), path~)
  FeatureCollection::new(features, bbox=geojson_object.bbox)
}
