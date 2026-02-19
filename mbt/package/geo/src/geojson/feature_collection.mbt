///|
pub struct FeatureCollection {
  features : Array[Feature]
} derive(Eq, Show)

///|
pub fn FeatureCollection::new(features : Array[Feature]) -> FeatureCollection {
  { features, }
}

///|
pub impl GeoJSONTrait for FeatureCollection with to_json(
  self,
  with_bbox? = false,
) {
  let map = {}
  set_geojson_type(map, GeoJSONType::FeatureCollection)
  map.set("features", self.features.to_json())
  if with_bbox {
    set_bbox(map, self)
  }
  map.to_json()
}

///|
pub impl ToJson for FeatureCollection with to_json(self) {
  GeoJSONTrait::to_json(self)
}

///|
pub impl FromJson for FeatureCollection with from_json(json, path) {
  FeatureCollection::{
    features: @json_helper.from_json_property_or_array_or_empty(
      "features", json, path,
    ),
  }
}

///|
pub impl BBoxTrait for FeatureCollection with bbox(self) {
  let coords = self.features
    .filter_map(feature => feature.geometry)
    .map(geom => {
      match geom.bbox() {
        BBox2D(x1, y1, x2, y2) => [Coordinates::XY(x1, y1), XY(x2, y2)]
        BBox3D(x1, y1, z1, x2, y2, z2) =>
          [Coordinates::XYZ_OR_XYM(x1, y1, z1), XYZ_OR_XYM(x2, y2, z2)]
      }
    })
    .flatten()
  BBox::from_coordinate_array(coords) catch {
    _ => BBox::new_2d(0.0, 0.0, 0.0, 0.0)
  }
}
