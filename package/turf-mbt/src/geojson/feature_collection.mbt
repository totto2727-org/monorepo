///|
/// FeatureCollection object.
/// https://tools.ietf.org/html/rfc7946#section-3.3
pub struct FeatureCollection {
  /// The array of features.
  features : Array[Feature]
  /// Bounding box.
  bbox : @primary.BBox?
} derive(Show, Eq)

///|
pub fn FeatureCollection::new(
  features : Array[Feature],
  bbox? : @primary.BBox? = None,
) -> FeatureCollection {
  FeatureCollection::{ features, bbox }
}

///|
pub impl @primary.ToGeoJSONObject for FeatureCollection with to_geojson_object(
  self,
) {
  @primary.GeoJSONObject::new(
    @primary.GeoJSONTypes::feature_collection(),
    bbox=self.bbox,
  )
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
  let geojson_object = @primary.GeoJSONObject::from_json(json, path)
  match geojson_object._type {
    @primary.GeoJSONTypes::FeatureCollection => ()
    _ => raise @json.JsonDecodeError((path, "Invalid FeatureCollection type"))
  }
  let features = match @helper.get_field(json, "features") {
    Some(features) => features
    _ => raise @json.JsonDecodeError((path, "Invalid features"))
  }
  FeatureCollection::new(
    @json.from_json(features, path~),
    bbox=geojson_object.bbox,
  )
}
