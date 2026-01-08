///|
/// The valid values for the "type" property of GeoJSON geometry objects.
/// https://tools.ietf.org/html/rfc7946#section-1.4
pub enum GeoJSONGeometryTypes {
  Point
  MultiPoint
  LineString
  MultiLineString
  Polygon
  MultiPolygon
  GeometryCollection
} derive(Show, Eq, ToJson, FromJson)

///|
pub fn GeoJSONGeometryTypes::point() -> GeoJSONGeometryTypes {
  GeoJSONGeometryTypes::Point
}

///|
pub fn GeoJSONGeometryTypes::multi_point() -> GeoJSONGeometryTypes {
  GeoJSONGeometryTypes::MultiPoint
}

///|
pub fn GeoJSONGeometryTypes::line_string() -> GeoJSONGeometryTypes {
  GeoJSONGeometryTypes::LineString
}

///|
pub fn GeoJSONGeometryTypes::multi_line_string() -> GeoJSONGeometryTypes {
  GeoJSONGeometryTypes::MultiLineString
}

///|
pub fn GeoJSONGeometryTypes::polygon() -> GeoJSONGeometryTypes {
  GeoJSONGeometryTypes::Polygon
}

///|
pub fn GeoJSONGeometryTypes::multi_polygon() -> GeoJSONGeometryTypes {
  GeoJSONGeometryTypes::MultiPolygon
}

///|
pub fn GeoJSONGeometryTypes::geometry_collection() -> GeoJSONGeometryTypes {
  GeoJSONGeometryTypes::GeometryCollection
}
