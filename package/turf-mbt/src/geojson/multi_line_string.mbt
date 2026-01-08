///|
/// MultiLineString geometry object.
/// https://tools.ietf.org/html/rfc7946#section-3.1.5
pub struct MultiLineString {
  lines : Array[LineString]
  bbox : BBox?
} derive(Show, Eq)

///|
pub(open) trait ToMultiLineString {
  to_multi_line_string(Self) -> MultiLineString
}

///|
pub fn MultiLineString::new(
  lines : Array[LineString],
  bbox? : BBox? = None,
) -> MultiLineString {
  MultiLineString::{ lines, bbox }
}

///|
/// Identity Implementation
pub impl ToMultiLineString for MultiLineString with to_multi_line_string(self) {
  self
}

///|
pub impl ToGeoJSONObject for MultiLineString with to_geojson_object(self) {
  GeoJSONObject::new(
    GeoJSONTypes::geometry(GeoJSONGeometryTypes::multi_line_string()),
    bbox=self.bbox,
  )
}

///|
pub impl GeometryToBBox for MultiLineString with to_bbox(
  self,
  re_compute? = false,
) {
  match (self.bbox, re_compute) {
    (Some(bbox), false) => bbox
    _ => {
      let position_array = self.lines
        .map(l => l.to_bbox().to_bbox_2d())
        .map(bbox => [bbox.min, bbox.max])
        .flatten()
      BBox2D::from_positions(position_array).to_bbox()
    }
  }
}

///|
pub impl ToGeometry for MultiLineString with to_geometry(self) {
  Geometry::MultiLineString(self)
}

///|
pub impl ToJson for MultiLineString with to_json(self) {
  let base = self.to_geojson_object().to_json_map()
  let coordinates = self.lines |> Array::map(l => l.coordinates.to_json())
  base.set("coordinates", coordinates.to_json())
  base.to_json()
}

///|
pub impl FromJson for MultiLineString with from_json(
  json : Json,
  path : @json.JsonPath,
) {
  let lines = match @helper.get_coordinates_field(json, path) {
    Array(array) =>
      array.map(json => LineString::new(@json.from_json(json, path~)))
    _ =>
      raise @json.JsonDecodeError(
        (path, "Invalid coordinates in json: \{json}"),
      )
  }
  MultiLineString::new(lines, bbox=GeoJSONObject::from_json(json, path).bbox)
}
