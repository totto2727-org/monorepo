///|
/// LineString geometry object.
/// https://tools.ietf.org/html/rfc7946#section-3.1.4
pub struct LineString {
  coordinates : Array[@position.Position]
  bbox : @bbox.BBox?
} derive(Show, Eq, Compare, Hash)

///|
pub fn LineString::new(
  coordinates : Array[@position.Position],
  bbox? : @bbox.BBox? = None,
) -> LineString {
  LineString::{ coordinates, bbox }
}

///|
pub impl @primary.ToGeoJSONObject for LineString with to_geojson_object(self) {
  @primary.GeoJSONObject::new(
    @primary.GeoJSONTypes::geometry(
      @primary.GeoJSONGeometryTypes::line_string(),
    ),
    bbox=self.bbox,
  )
}

///|
pub impl ToBBox for LineString with to_bbox(self, re_compute? = false) {
  match (self.bbox, re_compute) {
    (Some(bbox), false) => bbox
    _ => {
      let position_array = self.coordinates.map(p => p.to_2d())
      @bbox.BBox2D::from_positions(position_array).to_bbox()
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
    bbox=@primary.GeoJSONObject::from_json(json, path).bbox,
  )
}
