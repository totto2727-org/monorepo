///|
/// Point geometry object.
/// https://tools.ietf.org/html/rfc7946#section-3.1.2
pub struct Point {
  coordinates : Position
  bbox : BBox?
} derive(Show, Eq)

///|
pub fn Point::new(coordinates : Position, bbox? : BBox? = None) -> Point {
  Point::{ coordinates, bbox }
}

///|
pub impl ToPosition for Point with to_position(self) {
  self.coordinates
}

///|
pub impl ToMultiPoint for Point with to_multi_point(self) {
  MultiPoint::new([self])
}

///|
pub impl ToGeoJSONObject for Point with to_geojson_object(self) {
  GeoJSONObject::new(
    GeoJSONTypes::geometry(GeoJSONGeometryTypes::point()),
    bbox=self.bbox,
  )
}

///|
pub impl GeometryToBBox for Point with to_bbox(self, re_compute? = false) {
  match (self.bbox, re_compute) {
    (Some(bbox), false) => bbox
    _ => BBox2D::from_positions([self.coordinates.to_position_2d()]).to_bbox()
  }
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
    bbox=GeoJSONObject::from_json(json, path).bbox,
  )
}
