///|
/// The valid values for the "type" property of GeoJSON geometry objects.
/// https://tools.ietf.org/html/rfc7946#section-1.4
pub enum GeoJsonGeometryTypes {
  Point
  MultiPoint
  LineString
  MultiLineString
  Polygon
  MultiPolygon
  GeometryCollection
} derive(Show, Eq, Compare, Hash, ToJson, FromJson)

///|
pub fn GeoJsonGeometryTypes::point() -> GeoJsonGeometryTypes {
  GeoJsonGeometryTypes::Point
}

///|
pub fn GeoJsonGeometryTypes::multi_point() -> GeoJsonGeometryTypes {
  GeoJsonGeometryTypes::MultiPoint
}

///|
pub fn GeoJsonGeometryTypes::line_string() -> GeoJsonGeometryTypes {
  GeoJsonGeometryTypes::LineString
}

///|
pub fn GeoJsonGeometryTypes::multi_line_string() -> GeoJsonGeometryTypes {
  GeoJsonGeometryTypes::MultiLineString
}

///|
pub fn GeoJsonGeometryTypes::polygon() -> GeoJsonGeometryTypes {
  GeoJsonGeometryTypes::Polygon
}

///|
pub fn GeoJsonGeometryTypes::multi_polygon() -> GeoJsonGeometryTypes {
  GeoJsonGeometryTypes::MultiPolygon
}

///|
pub fn GeoJsonGeometryTypes::geometry_collection() -> GeoJsonGeometryTypes {
  GeoJsonGeometryTypes::GeometryCollection
}

///|
pub trait ToGeoJsonGeometryTypes {
  to_geojson_geometry_types(Self) -> GeoJsonGeometryTypes
}
