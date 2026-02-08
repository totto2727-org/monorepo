///|
pub struct LineString {
  coordinates : Array[Coordinates]
} derive(Eq, Show)

///|
pub fn LineString::new(
  coordinates : Array[Coordinates],
) -> LineString raise InvalidGeoJSONError {
  if coordinates.length() < 2 {
    raise InvalidGeoJSONError("LineString must have at least 2 coordinates")
  }
  { coordinates, }
}

///|
pub impl GeoJSONTrait for LineString with to_json(self, with_bbox? = false) {
  let map = {}
  set_geometry_type(map, GeometryType::LineString)
  set_coordinates(map, self.coordinates.to_json())
  if with_bbox {
    set_bbox(map, self)
  }
  map.to_json()
}

///|
pub impl ToJson for LineString with to_json(self) {
  GeoJSONTrait::to_json(self)
}

///|
pub impl FromJson for LineString with from_json(json, path) {
  let coordinates : Array[Coordinates] = get_coordinates(json, path)
  LineString::new(coordinates) catch {
    InvalidGeoJSONError(msg) => raise geojson_decode_error(path, msg, json)
  }
}

///|
pub impl BBoxTrait for LineString with bbox(self) {
  BBox::from_coordinate_array(self.coordinates)
}
