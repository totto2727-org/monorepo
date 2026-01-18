///|
fn geojson_decode_error(
  path : @json.JsonPath,
  msg : String,
  geojson : Json,
) -> @json.JsonDecodeError {
  @json.JsonDecodeError((path, "GeoJSON error: \{msg}\n\{geojson}"))
}

///|
pub(open) trait ToGeoJSON {
  to_geojson(self : Self, with_bbox? : Bool) -> GeoJSON
}

///|
pub suberror GeoJSONDecodeError {
  GeoJSONDecodeError(String)
}

///|
pub fn GeoJSONDecodeError::new(msg : String) -> GeoJSONDecodeError {
  GeoJSONDecodeError(msg)
}

///|
pub(open) trait FromGeoJSON {
  from_geojson_geometry(geometry : Geometry) -> Self raise GeoJSONDecodeError
}

///|
pub enum GeoJSON {
  FeatureCollection(FeatureCollection)
  Feature(Feature)
  Geometry(Geometry)
} derive(Eq, Show)

///|
trait GeoJSONTrait: FromJson + ToJson {
  to_json(self : Self, with_bbox? : Bool) -> Json
}

///|
pub impl GeoJSONTrait for GeoJSON with to_json(self, with_bbox? = false) {
  match self {
    Feature(feature) => GeoJSONTrait::to_json(feature, with_bbox~)
    FeatureCollection(feature_collection) =>
      GeoJSONTrait::to_json(feature_collection, with_bbox~)
    Geometry(geometry) => GeoJSONTrait::to_json(geometry, with_bbox~)
  }
}

///|
pub impl ToJson for GeoJSON with to_json(self) {
  GeoJSONTrait::to_json(self)
}

///|
pub impl FromJson for GeoJSON with from_json(json, path) {
  match GeoJSONType::from_raw_geojson(json, path) {
    GeoJSONType::FeatureCollection =>
      GeoJSON::FeatureCollection(FeatureCollection::from_json(json, path))
    GeoJSONType::Feature => GeoJSON::Feature(Feature::from_json(json, path))
    GeoJSONType::Geometry(_) =>
      GeoJSON::Geometry(Geometry::from_json(json, path))
  }
}

///|
fn set_geojson_type(
  map : Map[String, Json],
  geojson_type : GeoJSONType,
) -> Unit {
  map.set("type", geojson_type.to_json())
}

///|
pub(all) struct FeatureCollection {
  features : Array[Feature]
} derive(Eq, Show)

///|
pub impl GeoJSONTrait for FeatureCollection with to_json(
  self,
  with_bbox? = false,
) {
  let map = {}
  set_geojson_type(map, GeoJSONType::FeatureCollection)
  map.set("features", self.features.to_json())
  if with_bbox {
    ...
  }
  map.to_json()
}

///|
pub impl ToJson for FeatureCollection with to_json(self) {
  GeoJSONTrait::to_json(self)
}

///|
pub impl FromJson for FeatureCollection with from_json(json, path) {
  FeatureCollection::{
    features: @json_helper.from_json_property_or_array_or_empty(
      "features", json, path,
    ),
  }
}

///|
pub(all) struct Feature {
  geometry : Geometry?
  properties : Map[String, Json]?
  id : ID?
} derive(Eq, Show)

///|
pub impl GeoJSONTrait for Feature with to_json(self, with_bbox? = false) {
  let map = {}
  set_geojson_type(map, GeoJSONType::Feature)
  @json_helper.to_nullable_json(map, "geometry", self.geometry)
  @json_helper.to_nullable_json(map, "properties", self.properties)
  @json_helper.to_optional_json(map, "id", self.id)
  if with_bbox {
    ...
  }
  map.to_json()
}

///|
pub impl ToJson for Feature with to_json(self) {
  GeoJSONTrait::to_json(self)
}

///|
pub impl FromJson for Feature with from_json(json, path) {
  Feature::{
    geometry: @json_helper.from_json_property("geometry", json, path),
    properties: @json_helper.from_json_property("properties", json, path),
    id: @json_helper.from_json_property("id", json, path),
  }
}

///|
pub(all) enum ID {
  String(String)
  Number(Double)
} derive(Eq, Show)

///|
pub impl ToJson for ID with to_json(self) {
  match self {
    String(string) => string.to_json()
    Number(number) => number.to_json()
  }
}

///|
pub impl FromJson for ID with from_json(json, path) {
  match json {
    Json::String(string) => ID::String(string)
    Json::Number(number, ..) => ID::Number(number)
    _ => raise geojson_decode_error(path, "Invalid ID", json)
  }
}

///|
pub enum Geometry {
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
  let _type = GeometryType::from_raw_geojson(json, path)
  match _type {
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
fn set_geometry_type(
  map : Map[String, Json],
  geometry_type : GeometryType,
) -> Unit {
  map.set("type", geometry_type.to_json())
}

///|
fn set_coordinates(map : Map[String, Json], coordinates : Json) -> Unit {
  map.set("coordinates", coordinates)
}

///|
fn[T : FromJson] get_coordinates(
  json : Json,
  path : @json.JsonPath,
) -> T raise @json.JsonDecodeError {
  @json_helper.from_json_property_or_throw("coordinates", json, path)
}

///|
pub(all) struct Point {
  coordinates : Coordinates
} derive(Eq, Show)

///|
pub impl GeoJSONTrait for Point with to_json(self, with_bbox? = false) {
  let map = {}
  set_geometry_type(map, GeometryType::Point)
  set_coordinates(map, self.coordinates.to_json())
  if with_bbox {
    ...
  }
  map.to_json()
}

///|
pub impl ToJson for Point with to_json(self) {
  GeoJSONTrait::to_json(self)
}

///|
pub impl FromJson for Point with from_json(json, path) {
  let coordinates = get_coordinates(json, path)
  Point::{ coordinates, }
}

///|
pub(all) struct LineString {
  coordinates : Array[Coordinates]
} derive(Eq, Show)

///|
pub impl GeoJSONTrait for LineString with to_json(self, with_bbox? = false) {
  let map = {}
  set_geometry_type(map, GeometryType::LineString)
  set_coordinates(map, self.coordinates.to_json())
  if with_bbox {
    ...
  }
  map.to_json()
}

///|
pub impl ToJson for LineString with to_json(self) {
  GeoJSONTrait::to_json(self)
}

///|
pub impl FromJson for LineString with from_json(json, path) {
  let coordinates : Array[Coordinates] = get_coordinates(json, path)
  if coordinates.length() < 2 {
    raise geojson_decode_error(
      path, "LineString must have at least 2 coordinates", json,
    )
  }
  LineString::{ coordinates, }
}

///|
pub(all) struct Polygon {
  coordinates : Array[Array[Coordinates]]
} derive(Eq, Show)

///|
pub impl GeoJSONTrait for Polygon with to_json(self, with_bbox? = false) {
  let map = {}
  set_geometry_type(map, GeometryType::Polygon)
  set_coordinates(map, self.coordinates.to_json())
  if with_bbox {
    ...
  }
  map.to_json()
}

///|
pub impl ToJson for Polygon with to_json(self) {
  GeoJSONTrait::to_json(self)
}

///|
pub impl FromJson for Polygon with from_json(json, path) {
  let coordinates : Array[Array[Coordinates]] = get_coordinates(json, path)
  if coordinates.length() < 1 {
    raise geojson_decode_error(path, "Polygon must have at least 1 ring", json)
  }
  for ring in coordinates {
    if ring.length() < 3 {
      raise geojson_decode_error(
        path, "Polygon ring must have at least 3 coordinates", json,
      )
    }
    if ring[0] != ring[ring.length() - 1] {
      raise geojson_decode_error(
        path, "Polygon ring must have the same first and last coordinates", json,
      )
    }
  }
  Polygon::{ coordinates, }
}

///|
pub(all) struct MultiPoint {
  coordinates : Array[Coordinates]
} derive(Eq, Show)

///|
pub impl GeoJSONTrait for MultiPoint with to_json(self, with_bbox? = false) {
  let map = {}
  set_geometry_type(map, GeometryType::MultiPoint)
  set_coordinates(map, self.coordinates.to_json())
  if with_bbox {
    ...
  }
  map.to_json()
}

///|
pub impl ToJson for MultiPoint with to_json(self) {
  GeoJSONTrait::to_json(self)
}

///|
pub impl FromJson for MultiPoint with from_json(json, path) {
  let coordinates : Array[Coordinates] = get_coordinates(json, path)
  MultiPoint::{ coordinates, }
}

///|
pub(all) struct MultiLineString {
  coordinates : Array[Array[Coordinates]]
} derive(Eq, Show)

///|
pub impl GeoJSONTrait for MultiLineString with to_json(self, with_bbox? = false) {
  let map = {}
  set_geometry_type(map, GeometryType::MultiLineString)
  set_coordinates(map, self.coordinates.to_json())
  if with_bbox {
    ...
  }
  map.to_json()
}

///|
pub impl ToJson for MultiLineString with to_json(self) {
  GeoJSONTrait::to_json(self)
}

///|
pub impl FromJson for MultiLineString with from_json(json, path) {
  let coordinates : Array[Array[Coordinates]] = get_coordinates(json, path)
  MultiLineString::{ coordinates, }
}

///|
pub(all) struct MultiPolygon {
  coordinates : Array[Array[Array[Coordinates]]]
} derive(Eq, Show)

///|
pub impl GeoJSONTrait for MultiPolygon with to_json(self, with_bbox? = false) {
  let map = {}
  set_geometry_type(map, GeometryType::MultiPolygon)
  set_coordinates(map, self.coordinates.to_json())
  if with_bbox {
    ...
  }
  map.to_json()
}

///|
pub impl ToJson for MultiPolygon with to_json(self) {
  GeoJSONTrait::to_json(self)
}

///|
pub impl FromJson for MultiPolygon with from_json(json, path) {
  let coordinates : Array[Array[Array[Coordinates]]] = get_coordinates(
    json, path,
  )
  MultiPolygon::{ coordinates, }
}

///|
pub(all) struct GeometryCollection {
  geometries : Array[Geometry]
} derive(Eq, Show)

///|
pub impl GeoJSONTrait for GeometryCollection with to_json(
  self,
  with_bbox? = false,
) {
  let map = {}
  set_geometry_type(map, GeometryType::GeometryCollection)
  map.set(
    "geometries",
    self.geometries.map(GeoJSONTrait::to_json(_, with_bbox~)).to_json(),
  )
  // TODO: set bbox
  map.to_json()
}

///|
pub impl ToJson for GeometryCollection with to_json(self) {
  GeoJSONTrait::to_json(self)
}

///|
pub impl FromJson for GeometryCollection with from_json(json, path) {
  let geometries : Array[Geometry] = @json_helper.from_json_property_or_array_or_empty(
    "geometries", json, path,
  )
  GeometryCollection::{ geometries, }
}

///|
pub(all) enum GeoJSONType {
  FeatureCollection
  Feature
  Geometry(GeometryType)
} derive(Eq, Show)

///|
pub fn GeoJSONType::from_raw_geojson(
  json : Json,
  path : @json.JsonPath,
) -> GeoJSONType raise @json.JsonDecodeError {
  @json_helper.from_json_property_or_throw("type", json, path)
}

///|
pub impl ToJson for GeoJSONType with to_json(self) {
  match self {
    FeatureCollection => "FeatureCollection"
    Feature => "Feature"
    Geometry(geometry_type) => geometry_type.to_json()
  }
}

///|
pub impl FromJson for GeoJSONType with from_json(json, path) {
  match json {
    Json::String("FeatureCollection") => GeoJSONType::FeatureCollection
    Json::String("Feature") => GeoJSONType::Feature
    _ => GeoJSONType::Geometry(GeometryType::from_json(json, path))
  }
}

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

///|
pub(all) enum BBox {
  BBox2D(Double, Double, Double, Double)
  BBox3D(Double, Double, Double, Double, Double, Double)
} derive(Eq, Show)

///|
pub impl ToJson for BBox with to_json(self) {
  match self {
    BBox2D(x1, y1, x2, y2) => [x1, y1, x2, y2]
    BBox3D(x1, y1, z1, x2, y2, z2) => [x1, y1, z1, x2, y2, z2]
  }
}

///|
pub impl FromJson for BBox with from_json(json, path) {
  match json {
    Json::Array(
      [
        Json::Number(x1, ..),
        Json::Number(y1, ..),
        Json::Number(x2, ..),
        Json::Number(y2, ..),
      ]
    ) => BBox::BBox2D(x1, y1, x2, y2)
    Json::Array(
      [
        Json::Number(x1, ..),
        Json::Number(y1, ..),
        Json::Number(z1, ..),
        Json::Number(x2, ..),
        Json::Number(y2, ..),
        Json::Number(z2, ..),
      ]
    ) => BBox::BBox3D(x1, y1, z1, x2, y2, z2)
    _ => raise geojson_decode_error(path, "Invalid BBox", json)
  }
}

///|
pub(all) enum Coordinates {
  XY(Double, Double)
  XYZ_OR_XYM(Double, Double, Double)
  XYZM(Double, Double, Double, Double)
} derive(Eq, Show)

///|
pub impl ToJson for Coordinates with to_json(self) {
  match self {
    XY(x, y) => [x, y]
    XYZ_OR_XYM(x, y, z) => [x, y, z]
    XYZM(x, y, z, m) => [x, y, z, m]
  }
}

///|
pub impl FromJson for Coordinates with from_json(json, path) {
  match json {
    Json::Array([Json::Number(x, ..), Json::Number(y, ..)]) =>
      Coordinates::XY(x, y)
    Json::Array([Json::Number(x, ..), Json::Number(y, ..), Json::Number(z, ..)]) =>
      Coordinates::XYZ_OR_XYM(x, y, z)
    Json::Array(
      [
        Json::Number(x, ..),
        Json::Number(y, ..),
        Json::Number(z, ..),
        Json::Number(m, ..),
      ]
    ) => Coordinates::XYZM(x, y, z, m)
    _ => raise geojson_decode_error(path, "Invalid Coordinates", json)
  }
}
