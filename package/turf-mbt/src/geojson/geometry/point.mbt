///|
/// Point geometry object.
/// https://tools.ietf.org/html/rfc7946#section-3.1.2
pub struct Point {
  coordinates : @position.Position
  bbox : @bbox.BBox?
} derive(Show, Eq, Compare, Hash)

///|
pub fn Point::new(
  coordinates : @position.Position,
  bbox? : @bbox.BBox? = None,
) -> Point {
  Point::{ coordinates, bbox }
}

///|
pub impl @primary.ToGeoJSONObject for Point with to_geojson_object(self) {
  @primary.GeoJSONObject::new(
    @primary.GeoJSONTypes::geometry(@primary.GeoJSONGeometryTypes::point()),
    bbox=self.bbox,
  )
}

///|
pub impl ToGeometry for Point with to_geometry(self) {
  Geometry::Point(self)
}

///|
pub impl ToJson for Point with to_json(self) {
  let base = self.to_geojson_object().to_json_map()
  base.set("coordinates", self.coordinates.to_json())
  base.to_json()
}

///|
pub impl FromJson for Point with from_json(json : Json, path : @json.JsonPath) {
  Point::new(
    @json.from_json(@helper.get_coordinates_field(json, path), path~),
    bbox=@primary.GeoJSONObject::from_json(json, path).bbox,
  )
}
