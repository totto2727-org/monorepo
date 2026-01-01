///|
/// Feature object.
/// https://tools.ietf.org/html/rfc7946#section-3.2
pub struct Feature {
  /// The feature's geometry.
  geometry : @geometry.Geometry?
  /// The feature's properties.
  properties : Map[String, Json]?
  /// The feature's ID.
  id : FeatureID?
  /// Bounding box.
  bbox : @bbox.BBox?
} derive(Show, Eq)

///|
pub fn Feature::new(
  geometry? : @geometry.Geometry? = None,
  properties? : Map[String, Json]? = None,
  id? : FeatureID? = None,
  bbox? : @bbox.BBox? = None,
) -> Feature {
  Feature::{ geometry, properties, id, bbox }
}

///|
pub impl @primary.ToGeoJSONObject for Feature with to_geojson_object(self) {
  @primary.GeoJSONObject::new(@primary.GeoJSONTypes::feature(), bbox=self.bbox)
}

///|
pub impl ToJson for Feature with to_json(self) {
  let map : Map[String, Json] = self.to_geojson_object().to_json_map()
  map.set(
    "geometry",
    match self.geometry {
      Some(g) => g.to_json()
      None => null
    },
  )
  map.set(
    "properties",
    match self.properties {
      Some(p) => p.to_json()
      None => null
    },
  )
  match self.id {
    Some(id) => map.set("id", id.to_json())
    None => ()
  }
  map.to_json()
}

///|
pub impl FromJson for Feature with from_json(json, path) {
  let geojson_object = @primary.GeoJSONObject::from_json(json, path)
  match geojson_object._type {
    Feature => ()
    _ as _type =>
      raise @json.JsonDecodeError((path, "Invalid Feature type: \{_type}"))
  }
  let geometry : @geometry.Geometry? = match
    @helper.get_field(json, "geometry") {
    Some(Json::Null) | None => None
    Some(geometry_json) => Some(@json.from_json(geometry_json, path~))
  }
  let properties : Map[String, Json]? = match
    @helper.get_field(json, "properties") {
    Some(Json::Null) | None => None
    Some(properties_json) => Some(@json.from_json(properties_json, path~))
  }
  let id : FeatureID? = match @helper.get_field(json, "id") {
    Some(id_json) => Some(@json.from_json(id_json, path~))
    None => None
  }
  Feature::new(geometry~, properties~, id~, bbox=geojson_object.bbox)
}
