///|
/// LineString geometry object.
/// https://tools.ietf.org/html/rfc7946#section-3.1.4
pub struct LineString {
  coordinates : Array[Position]
  bbox : BBox?
} derive(Show, Eq, Compare, Hash)

///|
pub fn LineString::new(
  coordinates : Array[Position],
  bbox? : BBox? = None,
) -> LineString {
  LineString::{ coordinates, bbox }
}

///|
pub impl ToMultiLineString for LineString with to_multi_line_string(self) {
  MultiLineString::new([self])
}

///|
pub impl ToGeoJSONObject for LineString with to_geojson_object(self) {
  GeoJSONObject::new(
    GeoJSONTypes::geometry(GeoJSONGeometryTypes::line_string()),
    bbox=self.bbox,
  )
}

///|
pub impl GeometryToBBox for LineString with to_bbox(self, re_compute? = false) {
  match (self.bbox, re_compute) {
    (Some(bbox), false) => bbox
    _ => {
      let position_array = self.coordinates.map(p => p.to_position_2d())
      BBox2D::from_positions(position_array).to_bbox()
    }
  }
}

///|
pub impl ToGeometry for LineString with to_geometry(self) {
  Geometry::LineString(self)
}

///|
pub impl ToJson for LineString with to_json(self) {
  let base = self.to_geojson_object().to_json_map()
  base.set("coordinates", self.coordinates.to_json())
  base.to_json()
}

///|
pub impl FromJson for LineString with from_json(
  json : Json,
  path : @json.JsonPath,
) {
  LineString::new(
    @json.from_json(@helper.get_coordinates_field(json, path), path~),
    bbox=GeoJSONObject::from_json(json, path).bbox,
  )
}
