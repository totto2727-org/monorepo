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
pub(open) trait ToFeatureCollection {
  to_feature_collection(Self) -> FeatureCollection
}

///|
pub fn FeatureCollection::new(
  features : Array[Feature],
  bbox? : BBox? = None,
) -> FeatureCollection {
  FeatureCollection::{ features, bbox }
}

///|
/// Identity Implementation
pub impl ToFeatureCollection for FeatureCollection with to_feature_collection(
  self,
) {
  self
}

///|
pub impl ToGeoJSONObject for FeatureCollection with to_geojson_object(self) {
  GeoJSONObject::new(GeoJSONTypes::feature_collection(), bbox=self.bbox)
}

///|
pub impl GeometryToBBox for FeatureCollection with to_bbox(
  self,
  re_compute? : Bool = false,
) {
  match (self.bbox, re_compute) {
    (Some(bbox), false) => bbox
    _ =>
      self.features
      |> Array::map(Feature::to_bbox(_))
      |> Array::map(BBox::to_bbox_2d)
      |> Array::map(x => [x.min, x.max])
      |> Array::flatten
      |> BBox2D::from_positions
      |> BBox2D::to_bbox
  }
}

///|
pub impl ToGeoJSON for FeatureCollection with to_geojson(self) -> GeoJSON {
  GeoJSON::FeatureCollection(self)
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
  let geojson_object = GeoJSONObject::from_json(json, path)
  match geojson_object._type {
    GeoJSONTypes::FeatureCollection => ()
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
