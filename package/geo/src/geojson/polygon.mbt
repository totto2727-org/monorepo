///|
pub struct Polygon {
  coordinates : Array[Array[Coordinates]]
} derive(Eq, Show)

///|
pub fn Polygon::new(
  coordinates : Array[Array[Coordinates]],
) -> Polygon raise InvalidGeoJSONError {
  if coordinates.length() < 1 {
    raise InvalidGeoJSONError("Polygon must have at least 1 ring")
  }
  for ring in coordinates {
    if ring.length() < 4 {
      raise InvalidGeoJSONError("Polygon ring must have at least 4 coordinates")
    }
    if ring[0] != ring[ring.length() - 1] {
      raise InvalidGeoJSONError(
        "Polygon ring must have the same first and last coordinates",
      )
    }
  }
  { coordinates, }
}

///|
pub impl GeoJSONTrait for Polygon with to_json(self, with_bbox? = false) {
  let map = {}
  set_geometry_type(map, GeometryType::Polygon)
  set_coordinates(map, self.coordinates.to_json())
  if with_bbox {
    set_bbox(map, self)
  }
  map.to_json()
}

///|
pub impl ToJson for Polygon with to_json(self) {
  GeoJSONTrait::to_json(self)
}

///|
pub impl FromJson for Polygon with from_json(json, path) {
  let coordinates : Array[Array[Coordinates]] = get_coordinates(json, path)
  Polygon::new(coordinates) catch {
    InvalidGeoJSONError(msg) => raise geojson_decode_error(path, msg, json)
  }
}

///|
pub impl BBoxTrait for Polygon with bbox(self) {
  BBox::from_coordinate_array(self.coordinates.flatten())
}
