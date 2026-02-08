///|
pub struct MultiLineString {
  coordinates : Array[Array[Coordinates]]
} derive(Eq, Show)

///|
pub fn MultiLineString::new(
  coordinates : Array[Array[Coordinates]],
) -> MultiLineString {
  { coordinates, }
}

///|
pub impl GeoJSONTrait for MultiLineString with to_json(self, with_bbox? = false) {
  let map = {}
  set_geometry_type(map, GeometryType::MultiLineString)
  set_coordinates(map, self.coordinates.to_json())
  if with_bbox {
    set_bbox(map, self)
  }
  map.to_json()
}

///|
pub impl ToJson for MultiLineString with to_json(self) {
  GeoJSONTrait::to_json(self)
}

///|
pub impl FromJson for MultiLineString with from_json(json, path) {
  let coordinates : Array[Array[Coordinates]] = get_coordinates(json, path)
  MultiLineString::{ coordinates, }
}

///|
pub impl BBoxTrait for MultiLineString with bbox(self) {
  BBox::from_coordinate_array(self.coordinates.flatten())
}
