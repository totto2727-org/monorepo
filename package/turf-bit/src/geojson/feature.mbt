///|
/// Feature object.
/// https://tools.ietf.org/html/rfc7946#section-3.2
pub struct Feature {
  /// The feature's geometry.
  geometry : Geometry?
  /// The feature's properties.
  properties : Map[String, Json]?
  /// The feature's ID.
  id : FeatureID?
  /// Bounding box.
  bbox : BBox?
} derive(Show, Eq)

///|
pub fn Feature::new(
  geometry? : Geometry? = None,
  properties? : Map[String, Json]? = None,
  id? : FeatureID? = None,
  bbox? : BBox? = None,
) -> Feature {
  Feature::{ geometry, properties, id, bbox }
}

///|
pub impl ToGeoJSONTypes for Feature with to_geojson_types(_self) {
  GeoJSONTypes::Feature
}

///|
pub impl ToGeoJSONObject for Feature with to_geojson_object(self) {
  GeoJSONObject::new(self.to_geojson_types(), bbox=self.bbox)
}

///|
pub impl ToJson for Feature with to_json(self) {
  let map : Map[String, Json] = {}
  map.set("type", "Feature")
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
  match self.bbox {
    Some(bbox) => map.set("bbox", bbox.to_json())
    None => ()
  }
  map.to_json()
}

///|
pub impl FromJson for Feature with from_json(json, path) {
  let geojson_object : GeoJSONObject = @json.from_json(json, path~)
  if geojson_object._type != GeoJSONTypes::Feature {
    raise @json.JsonDecodeError((path, "Invalid Feature type"))
  }
  fn get_field(name : String) -> Json? {
    match json {
      Object(map) => map.get(name)
      _ => None
    }
  }

  let geometry : Geometry? = match get_field("geometry") {
    Some(Json::Null) | None => None
    Some(geometry_json) => Some(@json.from_json(geometry_json, path~))
  }
  let properties : Map[String, Json]? = match get_field("properties") {
    Some(Json::Null) | None => None
    Some(properties_json) => Some(@json.from_json(properties_json, path~))
  }
  let id : FeatureID? = match get_field("id") {
    Some(id_json) => Some(@json.from_json(id_json, path~))
    None => None
  }
  Feature::new(geometry~, properties~, id~, bbox=geojson_object.bbox)
}
