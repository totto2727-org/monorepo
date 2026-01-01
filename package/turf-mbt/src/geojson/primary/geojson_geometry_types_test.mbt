///|
test "GeoJSONGeometryTypes to_json - Point" {
  let geojson_geometry_types = GeoJSONGeometryTypes::point()
  @json.inspect(geojson_geometry_types, content="Point")
}

///|
test "GeoJSONGeometryTypes to_json - MultiPoint" {
  let geojson_geometry_types = GeoJSONGeometryTypes::multi_point()
  @json.inspect(geojson_geometry_types, content="MultiPoint")
}

///|
test "GeoJSONGeometryTypes to_json - LineString" {
  let geojson_geometry_types = GeoJSONGeometryTypes::line_string()
  @json.inspect(geojson_geometry_types, content="LineString")
}

///|
test "GeoJSONGeometryTypes to_json - MultiLineString" {
  let geojson_geometry_types = GeoJSONGeometryTypes::multi_line_string()
  @json.inspect(geojson_geometry_types, content="MultiLineString")
}

///|
test "GeoJSONGeometryTypes to_json - Polygon" {
  let geojson_geometry_types = GeoJSONGeometryTypes::polygon()
  @json.inspect(geojson_geometry_types, content="Polygon")
}

///|
test "GeoJSONGeometryTypes to_json - MultiPolygon" {
  let geojson_geometry_types = GeoJSONGeometryTypes::multi_polygon()
  @json.inspect(geojson_geometry_types, content="MultiPolygon")
}

///|
test "GeoJSONGeometryTypes to_json - GeometryCollection" {
  let geojson_geometry_types = GeoJSONGeometryTypes::geometry_collection()
  @json.inspect(geojson_geometry_types, content="GeometryCollection")
}

///|
test "GeoJSONGeometryTypes from_json - Point" {
  let geojson_geometry_types : GeoJSONGeometryTypes = @json.from_json("Point")
  inspect(geojson_geometry_types, content="Point")
}

///|
test "GeoJSONGeometryTypes from_json - MultiPoint" {
  let geojson_geometry_types : GeoJSONGeometryTypes = @json.from_json(
    "MultiPoint",
  )
  inspect(geojson_geometry_types, content="MultiPoint")
}

///|
test "GeoJSONGeometryTypes from_json - LineString" {
  let geojson_geometry_types : GeoJSONGeometryTypes = @json.from_json(
    "LineString",
  )
  inspect(geojson_geometry_types, content="LineString")
}

///|
test "GeoJSONGeometryTypes from_json - MultiLineString" {
  let geojson_geometry_types : GeoJSONGeometryTypes = @json.from_json(
    "MultiLineString",
  )
  inspect(geojson_geometry_types, content="MultiLineString")
}

///|
test "GeoJSONGeometryTypes from_json - Polygon" {
  let geojson_geometry_types : GeoJSONGeometryTypes = @json.from_json("Polygon")
  inspect(geojson_geometry_types, content="Polygon")
}

///|
test "GeoJSONGeometryTypes from_json - MultiPolygon" {
  let geojson_geometry_types : GeoJSONGeometryTypes = @json.from_json(
    "MultiPolygon",
  )
  inspect(geojson_geometry_types, content="MultiPolygon")
}

///|
test "GeoJSONGeometryTypes from_json - GeometryCollection" {
  let geojson_geometry_types : GeoJSONGeometryTypes = @json.from_json(
    "GeometryCollection",
  )
  inspect(geojson_geometry_types, content="GeometryCollection")
}
