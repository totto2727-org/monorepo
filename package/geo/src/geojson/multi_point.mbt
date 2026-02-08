///|
pub struct MultiPoint {
  coordinates : Array[Coordinates]
} derive(Eq, Show)

///|
pub fn MultiPoint::new(coordinates : Array[Coordinates]) -> MultiPoint {
  { coordinates, }
}

///|
pub impl GeoJSONTrait for MultiPoint with to_json(self, with_bbox? = false) {
  let map = {}
  set_geometry_type(map, GeometryType::MultiPoint)
  set_coordinates(map, self.coordinates.to_json())
  if with_bbox {
    set_bbox(map, self)
  }
  map.to_json()
}

///|
pub impl ToJson for MultiPoint with to_json(self) {
  GeoJSONTrait::to_json(self)
}

///|
pub impl FromJson for MultiPoint with from_json(json, path) {
  let coordinates : Array[Coordinates] = get_coordinates(json, path)
  MultiPoint::{ coordinates, }
}

///|
pub impl BBoxTrait for MultiPoint with bbox(self) {
  BBox::from_coordinate_array(self.coordinates)
}
