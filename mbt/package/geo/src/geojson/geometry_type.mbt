///|
pub(all) enum GeometryType {
  Point
  LineString
  Polygon
  MultiPoint
  MultiLineString
  MultiPolygon
  GeometryCollection
} derive(Eq, Show)

///|
pub fn GeometryType::from_raw_geojson(
  json : Json,
  path : @json.JsonPath,
) -> GeometryType raise @json.JsonDecodeError {
  @json_helper.from_json_property("type", json, path).unwrap() catch {
    _ => raise geojson_decode_error(path, "Invalid GeoJSON type", json)
  }
}

///|
pub impl ToJson for GeometryType with to_json(self) {
  match self {
    Point => "Point"
    LineString => "LineString"
    Polygon => "Polygon"
    MultiPoint => "MultiPoint"
    MultiLineString => "MultiLineString"
    MultiPolygon => "MultiPolygon"
    GeometryCollection => "GeometryCollection"
  }
}

///|
pub impl FromJson for GeometryType with from_json(json, path) {
  match json {
    Json::String("Point") => GeometryType::Point
    Json::String("LineString") => GeometryType::LineString
    Json::String("Polygon") => GeometryType::Polygon
    Json::String("MultiPoint") => GeometryType::MultiPoint
    Json::String("MultiLineString") => GeometryType::MultiLineString
    Json::String("MultiPolygon") => GeometryType::MultiPolygon
    Json::String("GeometryCollection") => GeometryType::GeometryCollection
    _ => raise geojson_decode_error(path, "Invalid GeoJSON type", json)
  }
}
