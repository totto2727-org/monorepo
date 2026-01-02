///|
/// MultiPoint geometry object.
/// https://tools.ietf.org/html/rfc7946#section-3.1.3
pub struct MultiPoint {
  points : Array[Point]
  bbox : BBox?
} derive(Show, Eq, Compare, Hash)

///|
pub(open) trait ToMultiPoint {
  to_multi_point(Self) -> MultiPoint
}

///|
pub fn MultiPoint::new(
  points : Array[Point],
  bbox? : BBox? = None,
) -> MultiPoint {
  MultiPoint::{ points, bbox }
}

///|
/// Identity Implementation
pub impl ToMultiPoint for MultiPoint with to_multi_point(self) {
  self
}

///|
pub impl ToGeoJSONObject for MultiPoint with to_geojson_object(self) {
  GeoJSONObject::new(
    GeoJSONTypes::geometry(GeoJSONGeometryTypes::multi_point()),
    bbox=self.bbox,
  )
}

///|
pub impl GeometryToBBox for MultiPoint with to_bbox(self, re_compute? = false) {
  match (self.bbox, re_compute) {
    (Some(bbox), false) => bbox
    _ => {
      let position_array = self.points.map(p => p.coordinates.to_position_2d())
      BBox2D::from_positions(position_array).to_bbox()
    }
  }
}

///|
pub impl ToGeometry for MultiPoint with to_geometry(self) {
  Geometry::MultiPoint(self)
}

///|
pub impl ToJson for MultiPoint with to_json(self) {
  let base = self.to_geojson_object().to_json_map()
  let coordinates = self.points |> Array::map(p => p.coordinates.to_json())
  base.set("coordinates", coordinates.to_json())
  base.to_json()
}

///|
pub impl FromJson for MultiPoint with from_json(
  json : Json,
  path : @json.JsonPath,
) {
  let points = match @helper.get_coordinates_field(json, path) {
    Array(array) => array.map(json => Point::new(@json.from_json(json, path~)))
    _ =>
      raise @json.JsonDecodeError(
        (path, "Invalid coordinates in json: \{json}"),
      )
  }
  MultiPoint::new(points, bbox=GeoJSONObject::from_json(json, path).bbox)
}
