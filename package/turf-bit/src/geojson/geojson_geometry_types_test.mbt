///|
test "GeoJsonGeometryTypes::Point to JSON" {
  let geojson_geometry_types = GeoJsonGeometryTypes::point()
  @json.inspect(geojson_geometry_types, content="Point")
}

///|
test "GeoJsonGeometryTypes::MultiPoint to JSON" {
  let geojson_geometry_types = GeoJsonGeometryTypes::multi_point()
  @json.inspect(geojson_geometry_types, content="MultiPoint")
}

///|
test "GeoJsonGeometryTypes::LineString to JSON" {
  let geojson_geometry_types = GeoJsonGeometryTypes::line_string()
  @json.inspect(geojson_geometry_types, content="LineString")
}

///|
test "GeoJsonGeometryTypes::MultiLineString to JSON" {
  let geojson_geometry_types = GeoJsonGeometryTypes::multi_line_string()
  @json.inspect(geojson_geometry_types, content="MultiLineString")
}

///|
test "GeoJsonGeometryTypes::Polygon to JSON" {
  let geojson_geometry_types = GeoJsonGeometryTypes::polygon()
  @json.inspect(geojson_geometry_types, content="Polygon")
}

///|
test "GeoJsonGeometryTypes::MultiPolygon to JSON" {
  let geojson_geometry_types = GeoJsonGeometryTypes::multi_polygon()
  @json.inspect(geojson_geometry_types, content="MultiPolygon")
}

///|
test "GeoJsonGeometryTypes::GeometryCollection to JSON" {
  let geojson_geometry_types = GeoJsonGeometryTypes::geometry_collection()
  @json.inspect(geojson_geometry_types, content="GeometryCollection")
}

///|
test "GeoJsonGeometryTypes::Point from JSON" {
  let geojson_geometry_types : GeoJsonGeometryTypes = @json.from_json("Point")
  inspect(geojson_geometry_types, content="Point")
}

///|
test "GeoJsonGeometryTypes::MultiPoint from JSON" {
  let geojson_geometry_types : GeoJsonGeometryTypes = @json.from_json(
    "MultiPoint",
  )
  inspect(geojson_geometry_types, content="MultiPoint")
}

///|
test "GeoJsonGeometryTypes::LineString from JSON" {
  let geojson_geometry_types : GeoJsonGeometryTypes = @json.from_json(
    "LineString",
  )
  inspect(geojson_geometry_types, content="LineString")
}

///|
test "GeoJsonGeometryTypes::MultiLineString from JSON" {
  let geojson_geometry_types : GeoJsonGeometryTypes = @json.from_json(
    "MultiLineString",
  )
  inspect(geojson_geometry_types, content="MultiLineString")
}

///|
test "GeoJsonGeometryTypes::Polygon from JSON" {
  let geojson_geometry_types : GeoJsonGeometryTypes = @json.from_json("Polygon")
  inspect(geojson_geometry_types, content="Polygon")
}

///|
test "GeoJsonGeometryTypes::MultiPolygon from JSON" {
  let geojson_geometry_types : GeoJsonGeometryTypes = @json.from_json(
    "MultiPolygon",
  )
  inspect(geojson_geometry_types, content="MultiPolygon")
}

///|
test "GeoJsonGeometryTypes::GeometryCollection from JSON" {
  let geojson_geometry_types : GeoJsonGeometryTypes = @json.from_json(
    "GeometryCollection",
  )
  inspect(geojson_geometry_types, content="GeometryCollection")
}
