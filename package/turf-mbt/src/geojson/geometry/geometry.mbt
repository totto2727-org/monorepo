///|
/// Geometry object.
/// https://tools.ietf.org/html/rfc7946#section-3
#alias(GeometryObject)
pub enum Geometry {
  Point(Point)
  MultiPoint(MultiPoint)
  LineString(LineString)
  MultiLineString(MultiLineString)
  Polygon(Polygon)
  MultiPolygon(MultiPolygon)
  GeometryCollection(GeometryCollection)
} derive(Show, Eq, Compare, Hash)

///|
pub impl @primary.ToGeoJSONObject for Geometry with to_geojson_object(
  self : Geometry,
) -> @primary.GeoJSONObject {
  match self {
    Geometry::Point(p) => p.to_geojson_object()
    Geometry::MultiPoint(p) => p.to_geojson_object()
    Geometry::LineString(p) => p.to_geojson_object()
    Geometry::MultiLineString(p) => p.to_geojson_object()
    Geometry::Polygon(p) => p.to_geojson_object()
    Geometry::MultiPolygon(p) => p.to_geojson_object()
    Geometry::GeometryCollection(p) => p.to_geojson_object()
  }
}

///|
pub impl ToJson for Geometry with to_json(self) {
  match self {
    Geometry::Point(p) => p.to_json()
    Geometry::MultiPoint(p) => p.to_json()
    Geometry::LineString(p) => p.to_json()
    Geometry::MultiLineString(p) => p.to_json()
    Geometry::Polygon(p) => p.to_json()
    Geometry::MultiPolygon(p) => p.to_json()
    Geometry::GeometryCollection(p) => p.to_json()
  }
}

///|
pub impl FromJson for Geometry with from_json(
  json : Json,
  path : @json.JsonPath,
) -> Geometry {
  match @primary.GeoJSONObject::from_json(json, path)._type {
    Geometry(Point) => Point::from_json(json, path).to_geometry()
    Geometry(MultiPoint) => MultiPoint::from_json(json, path).to_geometry()
    Geometry(LineString) => LineString::from_json(json, path).to_geometry()
    Geometry(MultiLineString) =>
      MultiLineString::from_json(json, path).to_geometry()
    Geometry(Polygon) => Polygon::from_json(json, path).to_geometry()
    Geometry(MultiPolygon) => MultiPolygon::from_json(json, path).to_geometry()
    Geometry(GeometryCollection) =>
      GeometryCollection::from_json(json, path).to_geometry()
    _ => raise @json.JsonDecodeError((path, "Invalid geometry type"))
  }
}

///|
pub trait ToGeometry {
  to_geometry(Self) -> Geometry
}
