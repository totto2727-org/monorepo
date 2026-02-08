///|
pub struct MultiPolygon {
  coordinates : Array[Array[Array[Coordinates]]]
} derive(Eq, Show)

///|
pub fn MultiPolygon::new(
  coordinates : Array[Array[Array[Coordinates]]],
) -> MultiPolygon {
  { coordinates, }
}

///|
pub impl GeoJSONTrait for MultiPolygon with to_json(self, with_bbox? = false) {
  let map = {}
  set_geometry_type(map, GeometryType::MultiPolygon)
  set_coordinates(map, self.coordinates.to_json())
  if with_bbox {
    set_bbox(map, self)
  }
  map.to_json()
}

///|
pub impl ToJson for MultiPolygon with to_json(self) {
  GeoJSONTrait::to_json(self)
}

///|
pub impl FromJson for MultiPolygon with from_json(json, path) {
  let coordinates : Array[Array[Array[Coordinates]]] = get_coordinates(
    json, path,
  )
  MultiPolygon::{ coordinates, }
}

///|
pub impl BBoxTrait for MultiPolygon with bbox(self) {
  BBox::from_coordinate_array(self.coordinates.flatten().flatten())
}
