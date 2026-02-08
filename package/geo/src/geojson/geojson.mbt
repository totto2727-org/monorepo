///|
fn geojson_decode_error(
  path : @json.JsonPath,
  msg : String,
  geojson : Json,
) -> @json.JsonDecodeError {
  @json.JsonDecodeError((path, "GeoJSON error: \{msg}\n\{geojson}"))
}

///|
pub suberror InvalidGeoJSONError {
  InvalidGeoJSONError(String)
}

///|
pub fn InvalidGeoJSONError::new(msg : String) -> InvalidGeoJSONError {
  InvalidGeoJSONError(msg)
}

///|
pub(open) trait FromGeoJSON {
  from_geojson_geometry(geometry : Geometry) -> Self raise InvalidGeoJSONError
}

///|
pub(open) trait ToGeoJSON {
  to_geojson(self : Self, with_bbox? : Bool) -> GeoJSON
}

///|
pub(all) enum GeoJSON {
  FeatureCollection(FeatureCollection)
  Feature(Feature)
  Geometry(Geometry)
} derive(Eq, Show)

///|
pub(open) trait GeoJSONTrait: FromJson + ToJson {
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
pub impl BBoxTrait for GeoJSON with bbox(self) -> BBox {
  match self {
    FeatureCollection(fc) => fc.bbox()
    Feature(f) => f.bbox()
    Geometry(g) => g.bbox()
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
fn[T : BBoxTrait] set_bbox(map : Map[String, Json], bbox : T) -> Unit {
  try bbox.bbox() catch {
    _ => ()
  } noraise {
    bbox => map.set("bbox", bbox.to_json())
  }
}

///|
pub struct FeatureCollection {
  features : Array[Feature]
} derive(Eq, Show)

///|
pub fn FeatureCollection::new(features : Array[Feature]) -> FeatureCollection {
  { features, }
}

///|
pub impl GeoJSONTrait for FeatureCollection with to_json(
  self,
  with_bbox? = false,
) {
  let map = {}
  set_geojson_type(map, GeoJSONType::FeatureCollection)
  map.set("features", self.features.to_json())
  if with_bbox {
    set_bbox(map, self)
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
pub impl BBoxTrait for FeatureCollection with bbox(self) {
  let coords = self.features
    .filter_map(feature => feature.geometry)
    .map(geom => match geom.bbox() {
      BBox2D(x1, y1, x2, y2) => [Coordinates::XY(x1, y1), XY(x2, y2)]
      BBox3D(x1, y1, z1, x2, y2, z2) =>
        [Coordinates::XYZ_OR_XYM(x1, y1, z1), XYZ_OR_XYM(x2, y2, z2)]
    })
    .flatten()
  BBox::from_coordinate_array(coords) catch {
    _ => BBox::new_2d(0.0, 0.0, 0.0, 0.0)
  }
}

///|
pub struct Feature {
  geometry : Geometry?
  properties : Map[String, Json]?
  id : ID?
} derive(Eq, Show)

///|
pub fn Feature::new(
  geometry? : Geometry? = None,
  properties? : Map[String, Json]? = None,
  id? : ID? = None,
) -> Feature {
  { geometry, properties, id }
}

///|
pub impl GeoJSONTrait for Feature with to_json(self, with_bbox? = false) {
  let map = {}
  set_geojson_type(map, GeoJSONType::Feature)
  @json_helper.to_nullable_json(map, "geometry", self.geometry)
  @json_helper.to_nullable_json(map, "properties", self.properties)
  @json_helper.to_optional_json(map, "id", self.id)
  if with_bbox {
    set_bbox(map, self)
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
pub impl BBoxTrait for Feature with bbox(self) {
  match self.geometry {
    Some(geom) => geom.bbox()
    None => BBox::new_2d(0.0, 0.0, 0.0, 0.0)
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
pub struct Point {
  coordinates : Coordinates
} derive(Eq, Show)

///|
pub fn Point::new(coordinates : Coordinates) -> Point {
  { coordinates, }
}

///|
pub impl GeoJSONTrait for Point with to_json(self, with_bbox? = false) {
  let map = {}
  set_geometry_type(map, GeometryType::Point)
  set_coordinates(map, self.coordinates.to_json())
  if with_bbox {
    set_bbox(map, self)
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
pub impl BBoxTrait for Point with bbox(self) {
  BBox::from_coordinate_array([self.coordinates])
}

///|
pub struct LineString {
  coordinates : Array[Coordinates]
} derive(Eq, Show)

///|
pub fn LineString::new(
  coordinates : Array[Coordinates],
) -> LineString raise InvalidGeoJSONError {
  if coordinates.length() < 2 {
    raise InvalidGeoJSONError("LineString must have at least 2 coordinates")
  }
  { coordinates, }
}

///|
pub impl GeoJSONTrait for LineString with to_json(self, with_bbox? = false) {
  let map = {}
  set_geometry_type(map, GeometryType::LineString)
  set_coordinates(map, self.coordinates.to_json())
  if with_bbox {
    set_bbox(map, self)
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
  LineString::new(coordinates) catch {
    InvalidGeoJSONError(msg) => raise geojson_decode_error(path, msg, json)
  }
}

///|
pub impl BBoxTrait for LineString with bbox(self) {
  BBox::from_coordinate_array(self.coordinates)
}

///|
pub struct Polygon {
  coordinates : Array[Array[Coordinates]]
} derive(Eq, Show)

///|
pub fn Polygon::new(
  coordinates : Array[Array[Coordinates]],
) -> Polygon raise InvalidGeoJSONError {
  if coordinates.length() < 1 {
    raise InvalidGeoJSONError("Polygon must have at least 1 ring")
  }
  for ring in coordinates {
    if ring.length() < 4 {
      raise InvalidGeoJSONError("Polygon ring must have at least 4 coordinates")
    }
    if ring[0] != ring[ring.length() - 1] {
      raise InvalidGeoJSONError(
        "Polygon ring must have the same first and last coordinates",
      )
    }
  }
  { coordinates, }
}

///|
pub impl GeoJSONTrait for Polygon with to_json(self, with_bbox? = false) {
  let map = {}
  set_geometry_type(map, GeometryType::Polygon)
  set_coordinates(map, self.coordinates.to_json())
  if with_bbox {
    set_bbox(map, self)
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
  Polygon::new(coordinates) catch {
    InvalidGeoJSONError(msg) => raise geojson_decode_error(path, msg, json)
  }
}

///|
pub impl BBoxTrait for Polygon with bbox(self) {
  BBox::from_coordinate_array(self.coordinates.flatten())
}

///|
pub struct MultiPoint {
  coordinates : Array[Coordinates]
} derive(Eq, Show)

///|
pub fn MultiPoint::new(coordinates : Array[Coordinates]) -> MultiPoint {
  { coordinates, }
}

///|
pub impl GeoJSONTrait for MultiPoint with to_json(self, with_bbox? = false) {
  let map = {}
  set_geometry_type(map, GeometryType::MultiPoint)
  set_coordinates(map, self.coordinates.to_json())
  if with_bbox {
    set_bbox(map, self)
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
pub impl BBoxTrait for MultiPoint with bbox(self) {
  BBox::from_coordinate_array(self.coordinates)
}

///|
pub struct MultiLineString {
  coordinates : Array[Array[Coordinates]]
} derive(Eq, Show)

///|
pub fn MultiLineString::new(
  coordinates : Array[Array[Coordinates]],
) -> MultiLineString {
  { coordinates, }
}

///|
pub impl GeoJSONTrait for MultiLineString with to_json(self, with_bbox? = false) {
  let map = {}
  set_geometry_type(map, GeometryType::MultiLineString)
  set_coordinates(map, self.coordinates.to_json())
  if with_bbox {
    set_bbox(map, self)
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
pub impl BBoxTrait for MultiLineString with bbox(self) {
  BBox::from_coordinate_array(self.coordinates.flatten())
}

///|
pub struct MultiPolygon {
  coordinates : Array[Array[Array[Coordinates]]]
} derive(Eq, Show)

///|
pub fn MultiPolygon::new(
  coordinates : Array[Array[Array[Coordinates]]],
) -> MultiPolygon {
  { coordinates, }
}

///|
pub impl GeoJSONTrait for MultiPolygon with to_json(self, with_bbox? = false) {
  let map = {}
  set_geometry_type(map, GeometryType::MultiPolygon)
  set_coordinates(map, self.coordinates.to_json())
  if with_bbox {
    set_bbox(map, self)
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
pub impl BBoxTrait for MultiPolygon with bbox(self) {
  BBox::from_coordinate_array(self.coordinates.flatten().flatten())
}

///|
pub struct GeometryCollection {
  geometries : Array[Geometry]
} derive(Eq, Show)

///|
pub fn GeometryCollection::new(
  geometries : Array[Geometry],
) -> GeometryCollection {
  { geometries, }
}

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
  if with_bbox {
    set_bbox(map, self)
  }
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
pub impl BBoxTrait for GeometryCollection with bbox(self) {
  let coords = self.geometries
    .map(geom => match geom.bbox() {
      BBox2D(x1, y1, x2, y2) => [Coordinates::XY(x1, y1), XY(x2, y2)]
      BBox3D(x1, y1, z1, x2, y2, z2) =>
        [Coordinates::XYZ_OR_XYM(x1, y1, z1), XYZ_OR_XYM(x2, y2, z2)]
    })
    .flatten()
  BBox::from_coordinate_array(coords)
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
pub(open) trait BBoxTrait {
  bbox(Self) -> BBox raise InvalidGeoJSONError
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
pub fn BBox::new_2d(
  min_x : Double,
  min_y : Double,
  max_x : Double,
  max_y : Double,
) -> BBox {
  let x1 = @cmp.minimum(min_x, max_x)
  let y1 = @cmp.minimum(min_y, max_y)
  let x2 = @cmp.maximum(min_x, max_x)
  let y2 = @cmp.maximum(min_y, max_y)
  BBox2D(x1, y1, x2, y2)
}

///|
pub fn BBox::new_3d(
  min_x : Double,
  min_y : Double,
  min_z : Double,
  max_x : Double,
  max_y : Double,
  max_z : Double,
) -> BBox {
  let x1 = @cmp.minimum(min_x, max_x)
  let y1 = @cmp.minimum(min_y, max_y)
  let z1 = @cmp.minimum(min_z, max_z)
  let x2 = @cmp.maximum(min_x, max_x)
  let y2 = @cmp.maximum(min_y, max_y)
  let z2 = @cmp.maximum(min_z, max_z)
  BBox3D(x1, y1, z1, x2, y2, z2)
}

///|
pub fn BBox::from_coordinate_array(
  coords : Array[Coordinates],
) -> BBox raise InvalidGeoJSONError {
  if coords.length() == 0 {
    raise InvalidGeoJSONError("Coordinates array is empty")
  }
  let dim = coords[0].dimension()
  for i = 1; i < coords.length(); i = i + 1 {
    if coords[i].dimension() != dim {
      raise InvalidGeoJSONError("Coordinates must have the same dimension")
    }
  }
  match dim {
    2 => {
      // すでに長さの検証を行っているため、unwrapは安全
      let min_x = coords.iter().map(_.x()).minimum().unwrap()
      let max_x = coords.iter().map(_.x()).maximum().unwrap()
      let min_y = coords.iter().map(_.y()).minimum().unwrap()
      let max_y = coords.iter().map(_.y()).maximum().unwrap()
      BBox2D(min_x, min_y, max_x, max_y)
    }
    _ => {
      let min_x = coords.iter().map(_.x()).minimum().unwrap()
      let max_x = coords.iter().map(_.x()).maximum().unwrap()
      let min_y = coords.iter().map(_.y()).minimum().unwrap()
      let max_y = coords.iter().map(_.y()).maximum().unwrap()
      let min_z = coords
        .iter()
        // 3次元であることを保証しているため、unwrapは安全
        .map(coords => try! coords.z())
        .minimum()
        .unwrap()
      let max_z = coords
        .iter()
        // 3次元であることを保証しているため、unwrapは安全
        .map(coords => try! coords.z())
        .maximum()
        .unwrap()
      BBox3D(min_x, min_y, min_z, max_x, max_y, max_z)
    }
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

///|
pub fn Coordinates::dimension(self : Coordinates) -> Int {
  match self {
    XY(_, _) => 2
    XYZ_OR_XYM(_, _, _) => 3
    XYZM(_, _, _, _) => 4
  }
}

///|
pub fn Coordinates::x(self : Coordinates) -> Double {
  match self {
    XY(x, _) => x
    XYZ_OR_XYM(x, _, _) => x
    XYZM(x, _, _, _) => x
  }
}

///|
pub fn Coordinates::y(self : Coordinates) -> Double {
  match self {
    XY(_, y) => y
    XYZ_OR_XYM(_, y, _) => y
    XYZM(_, y, _, _) => y
  }
}

///|
pub fn Coordinates::z(self : Coordinates) -> Double raise InvalidGeoJSONError {
  match self {
    XY(_, _) =>
      raise InvalidGeoJSONError("Coordinates::z called on 2D coordinates")
    XYZ_OR_XYM(_, _, z) => z
    XYZM(_, _, z, _) => z
  }
}
