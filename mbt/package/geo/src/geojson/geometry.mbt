///|
pub(all) enum Geometry {
  Point(Point)
  LineString(LineString)
  Polygon(Polygon)
  MultiPoint(MultiPoint)
  MultiLineString(MultiLineString)
  MultiPolygon(MultiPolygon)
  GeometryCollection(GeometryCollection)
} derive(Eq, Show)

///|
pub impl GeoJSONTrait for Geometry with to_json(self, with_bbox? = false) {
  match self {
    MultiPolygon(multi_polygon) =>
      GeoJSONTrait::to_json(multi_polygon, with_bbox~)
    MultiLineString(multi_line_string) =>
      GeoJSONTrait::to_json(multi_line_string, with_bbox~)
    MultiPoint(multi_point) => GeoJSONTrait::to_json(multi_point, with_bbox~)
    Polygon(polygon) => GeoJSONTrait::to_json(polygon, with_bbox~)
    LineString(line_string) => GeoJSONTrait::to_json(line_string, with_bbox~)
    Point(point) => GeoJSONTrait::to_json(point, with_bbox~)
    GeometryCollection(geometry_collection) =>
      GeoJSONTrait::to_json(geometry_collection, with_bbox~)
  }
}

///|
pub impl ToJson for Geometry with to_json(self) {
  GeoJSONTrait::to_json(self)
}

///|
pub impl FromJson for Geometry with from_json(json, path) {
  match GeometryType::from_raw_geojson(json, path) {
    MultiPolygon => Geometry::MultiPolygon(MultiPolygon::from_json(json, path))
    MultiLineString =>
      Geometry::MultiLineString(MultiLineString::from_json(json, path))
    MultiPoint => Geometry::MultiPoint(MultiPoint::from_json(json, path))
    Polygon => Geometry::Polygon(Polygon::from_json(json, path))
    LineString => Geometry::LineString(LineString::from_json(json, path))
    Point => Geometry::Point(Point::from_json(json, path))
    GeometryCollection =>
      Geometry::GeometryCollection(GeometryCollection::from_json(json, path))
  }
}

///|
pub impl BBoxTrait for Geometry with bbox(self) {
  match self {
    Point(p) => p.bbox()
    LineString(l) => l.bbox()
    Polygon(p) => p.bbox()
    MultiPoint(mp) => mp.bbox()
    MultiLineString(mls) => mls.bbox()
    MultiPolygon(mpoly) => mpoly.bbox()
    GeometryCollection(gc) => gc.bbox()
  }
}
