///|
/// FeatureCollection object.
/// https://tools.ietf.org/html/rfc7946#section-3.3
pub struct FeatureCollection {
  /// The array of features.
  features : Array[Feature]
  /// Bounding box.
  bbox : @bbox.BBox?
} derive(Show, Eq)

///|
pub fn FeatureCollection::new(
  features : Array[Feature],
  bbox? : @bbox.BBox? = None,
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
pub impl @geometry.ToBBox for FeatureCollection with to_bbox(
  self,
  re_compute? : Bool = false,
) {
  match (self.bbox, re_compute) {
    (Some(bbox), false) => bbox
    _ =>
      self.features
      |> Array::map(Feature::to_bbox(_))
      |> Array::map(@bbox.BBox::to_2d)
      |> Array::map(x => [x.min, x.max])
      |> Array::flatten
      |> Array::map(@position.Position2D::to_2d)
      |> @bbox.BBox2D::from_positions
      |> @bbox.BBox2D::to_bbox
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
