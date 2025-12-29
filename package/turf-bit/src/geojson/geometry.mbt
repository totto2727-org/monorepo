///|
pub suberror GeoJsonError String derive(Show, Eq)

///|
/// Geometry object.
/// https://tools.ietf.org/html/rfc7946#section-3
#alias(GeometryObject)
pub enum Geometry {
  /// Point geometry object.
  /// https://tools.ietf.org/html/rfc7946#section-3.1.2
  Point(coordinates~ : Position, bbox~ : BBox?)
  /// MultiPoint geometry object.
  /// https://tools.ietf.org/html/rfc7946#section-3.1.3
  MultiPoint(coordinates~ : Array[Position], bbox~ : BBox?)
  /// LineString geometry object.
  /// https://tools.ietf.org/html/rfc7946#section-3.1.4
  LineString(coordinates~ : Array[Position], bbox~ : BBox?)
  /// MultiLineString geometry object.
  /// https://tools.ietf.org/html/rfc7946#section-3.1.5
  MultiLineString(coordinates~ : Array[Array[Position]], bbox~ : BBox?)
  /// Polygon geometry object.
  /// https://tools.ietf.org/html/rfc7946#section-3.1.6
  ///
  /// A LinearRing is a closed LineString with four or more positions.
  /// The first and last positions are equivalent, and they MUST contain
  /// identical values; their representation SHOULD also be identical.
  Polygon(coordinates~ : Array[Array[Position]], bbox~ : BBox?)
  /// MultiPolygon geometry object.
  /// https://tools.ietf.org/html/rfc7946#section-3.1.7
  MultiPolygon(coordinates~ : Array[Array[Array[Position]]], bbox~ : BBox?)
  /// GeometryCollection geometry object.
  /// https://tools.ietf.org/html/rfc7946#section-3.1.8
  ///
  /// To maximize interoperability, implementations SHOULD avoid nested GeometryCollections.
  /// Furthermore, GeometryCollections SHOULD avoid a structure that has only a single member,
  /// and implementations SHOULD avoid nesting other Geometry types within a GeometryCollection
  /// when a more specific Geometry type is available.
  GeometryCollection(geometries~ : Array[Geometry], bbox~ : BBox?)
} derive(Show, Eq, Compare, Hash)

///|
pub impl ToGeoJsonGeometryTypes for Geometry with to_geojson_geometry_types(
  self : Geometry,
) -> GeoJsonGeometryTypes {
  match self {
    Geometry::Point(_) => GeoJsonGeometryTypes::Point
    Geometry::MultiPoint(_) => GeoJsonGeometryTypes::MultiPoint
    Geometry::LineString(_) => GeoJsonGeometryTypes::LineString
    Geometry::MultiLineString(_) => GeoJsonGeometryTypes::MultiLineString
    Geometry::Polygon(_) => GeoJsonGeometryTypes::Polygon
    Geometry::MultiPolygon(_) => GeoJsonGeometryTypes::MultiPolygon
    Geometry::GeometryCollection(_) => GeoJsonGeometryTypes::GeometryCollection
  }
}

///|
pub impl ToGeoJsonTypes for Geometry with to_geojson_types(self : Geometry) -> GeoJsonTypes {
  GeoJsonTypes::Geometry(self.to_geojson_geometry_types())
}

///|
pub fn Geometry::get_bbox(self : Geometry) -> BBox? {
  match self {
    Geometry::Point(bbox~, ..) => bbox
    Geometry::MultiPoint(bbox~, ..) => bbox
    Geometry::LineString(bbox~, ..) => bbox
    Geometry::MultiLineString(bbox~, ..) => bbox
    Geometry::Polygon(bbox~, ..) => bbox
    Geometry::MultiPolygon(bbox~, ..) => bbox
    Geometry::GeometryCollection(bbox~, ..) => bbox
  }
}

///|
pub impl ToGeoJsonObject for Geometry with to_geojson_object(self : Geometry) -> GeoJsonObject {
  GeoJsonObject::new(self.to_geojson_types(), bbox=self.get_bbox())
}

///|
pub fn Geometry::point(
  coordinates : Position,
  bbox? : BBox? = None,
) -> Geometry {
  Geometry::Point(coordinates~, bbox~)
}

///|
pub fn Geometry::multi_point(
  coordinates : Array[Position],
  bbox? : BBox? = None,
) -> Geometry {
  Geometry::MultiPoint(coordinates~, bbox~)
}

///|
pub fn Geometry::line_string(
  coordinates : Array[Position],
  bbox? : BBox? = None,
) -> Geometry {
  Geometry::LineString(coordinates~, bbox~)
}

///|
pub fn Geometry::multi_line_string(
  coordinates : Array[Array[Position]],
  bbox? : BBox? = None,
) -> Geometry {
  Geometry::MultiLineString(coordinates~, bbox~)
}

///|
fn check_linear_ring(ring : Array[Position]) -> Unit raise GeoJsonError {
  if ring.length() < 4 {
    raise GeoJsonError(
      "Each LinearRing of a Polygon must have 4 or more Positions.",
    )
  }
  if ring[0] != ring[ring.length() - 1] {
    raise GeoJsonError("First and last Position are not equivalent.")
  }
}

///|
pub fn Geometry::polygon(
  coordinates : Array[Array[Position]],
  bbox? : BBox? = None,
) -> Geometry raise GeoJsonError {
  for ring in coordinates {
    check_linear_ring(ring)
  }
  Geometry::Polygon(coordinates~, bbox~)
}

///|
pub fn Geometry::multi_polygon(
  coordinates : Array[Array[Array[Position]]],
  bbox? : BBox? = None,
) -> Geometry raise GeoJsonError {
  for polygon in coordinates {
    for ring in polygon {
      check_linear_ring(ring)
    }
  }
  Geometry::MultiPolygon(coordinates~, bbox~)
}

///|
pub fn Geometry::geometry_collection(
  geometries : Array[Geometry],
  bbox? : BBox? = None,
) -> Geometry {
  Geometry::GeometryCollection(geometries~, bbox~)
}

///|
pub impl ToJson for Geometry with to_json(self) {
  let map : Map[String, Json] = {}
  map.set("type", self.to_geojson_geometry_types().to_json())
  match self.get_bbox() {
    Some(bbox) => map.set("bbox", bbox.to_json())
    None => ()
  }
  match self {
    Geometry::Point(coordinates~, ..) =>
      map.set("coordinates", coordinates.to_json())
    Geometry::MultiPoint(coordinates~, ..) =>
      map.set("coordinates", coordinates.to_json())
    Geometry::LineString(coordinates~, ..) =>
      map.set("coordinates", coordinates.to_json())
    Geometry::MultiLineString(coordinates~, ..) =>
      map.set("coordinates", coordinates.to_json())
    Geometry::Polygon(coordinates~, ..) =>
      map.set("coordinates", coordinates.to_json())
    Geometry::MultiPolygon(coordinates~, ..) =>
      map.set("coordinates", coordinates.to_json())
    Geometry::GeometryCollection(geometries~, ..) =>
      map.set("geometries", geometries.to_json())
  }
  map.to_json()
}

///|
pub impl @json.FromJson for Geometry with from_json(
  json : Json,
  path : @json.JsonPath,
) -> Geometry {
  let geojson_object : GeoJsonObject = @json.from_json(json, path~)
  fn get_geometries_json() raise @json.JsonDecodeError {
    match json {
      { "geometries": Json::Array(_) as geometries, .. } => geometries
      _ => raise @json.JsonDecodeError((path, "Invalid geometries"))
    }
  }

  fn get_coordinates_json() raise @json.JsonDecodeError {
    match json {
      { "coordinates": Json::Array(_) as coordinates, .. } => coordinates
      _ => raise @json.JsonDecodeError((path, "Invalid coordinates"))
    }
  }

  match geojson_object._type {
    Geometry(Point) =>
      Geometry::point(
        @json.from_json(get_coordinates_json(), path~),
        bbox=geojson_object.bbox,
      )
    Geometry(MultiPoint) =>
      Geometry::multi_point(
        @json.from_json(get_coordinates_json(), path~),
        bbox=geojson_object.bbox,
      )
    Geometry(LineString) =>
      Geometry::line_string(
        @json.from_json(get_coordinates_json(), path~),
        bbox=geojson_object.bbox,
      )
    Geometry(MultiLineString) =>
      Geometry::multi_line_string(
        @json.from_json(get_coordinates_json(), path~),
        bbox=geojson_object.bbox,
      )
    Geometry(Polygon) =>
      Geometry::polygon(
        @json.from_json(get_coordinates_json(), path~),
        bbox=geojson_object.bbox,
      ) catch {
        GeoJsonError(msg) =>
          raise @json.JsonDecodeError((path, "Invalid Polygon: \{msg}"))
        _ => raise @json.JsonDecodeError((path, "Invalid Polygon"))
      }
    Geometry(MultiPolygon) =>
      Geometry::multi_polygon(
        @json.from_json(get_coordinates_json(), path~),
        bbox=geojson_object.bbox,
      ) catch {
        GeoJsonError(msg) =>
          raise @json.JsonDecodeError((path, "Invalid MultiPolygon: \{msg}"))
        _ => raise @json.JsonDecodeError((path, "Invalid MultiPolygon"))
      }
    Geometry(GeometryCollection) =>
      Geometry::geometry_collection(
        @json.from_json(get_geometries_json(), path~),
        bbox=geojson_object.bbox,
      )
    _ => raise @json.JsonDecodeError((path, "Invalid geometry type"))
  }
}
