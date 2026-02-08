///|
pub struct Feature {
  geometry : Geometry?
  properties : Map[String, Json]?
  id : ID?
} derive(Eq, Show)

///|
pub fn Feature::new(
  geometry? : Geometry? = None,
  properties? : Map[String, Json]? = None,
  id? : ID? = None,
) -> Feature {
  { geometry, properties, id }
}

///|
pub impl GeoJSONTrait for Feature with to_json(self, with_bbox? = false) {
  let map = {}
  set_geojson_type(map, GeoJSONType::Feature)
  @json_helper.to_nullable_json(map, "geometry", self.geometry)
  @json_helper.to_nullable_json(map, "properties", self.properties)
  @json_helper.to_optional_json(map, "id", self.id)
  if with_bbox {
    set_bbox(map, self)
  }
  map.to_json()
}

///|
pub impl ToJson for Feature with to_json(self) {
  GeoJSONTrait::to_json(self)
}

///|
pub impl FromJson for Feature with from_json(json, path) {
  Feature::{
    geometry: @json_helper.from_json_property("geometry", json, path),
    properties: @json_helper.from_json_property("properties", json, path),
    id: @json_helper.from_json_property("id", json, path),
  }
}

///|
pub impl BBoxTrait for Feature with bbox(self) {
  match self.geometry {
    Some(geom) => geom.bbox()
    None => BBox::new_2d(0.0, 0.0, 0.0, 0.0)
  }
}
