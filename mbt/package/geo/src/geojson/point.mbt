///|
pub struct Point {
  coordinates : Coordinates
} derive(Eq, Show)

///|
pub fn Point::new(coordinates : Coordinates) -> Point {
  { coordinates, }
}

///|
pub impl GeoJSONTrait for Point with to_json(self, with_bbox? = false) {
  let map = {}
  set_geometry_type(map, GeometryType::Point)
  set_coordinates(map, self.coordinates.to_json())
  if with_bbox {
    set_bbox(map, self)
  }
  map.to_json()
}

///|
pub impl ToJson for Point with to_json(self) {
  GeoJSONTrait::to_json(self)
}

///|
pub impl FromJson for Point with from_json(json, path) {
  let coordinates = get_coordinates(json, path)
  Point::{ coordinates, }
}

///|
pub impl BBoxTrait for Point with bbox(self) {
  BBox::from_coordinate_array([self.coordinates])
}
