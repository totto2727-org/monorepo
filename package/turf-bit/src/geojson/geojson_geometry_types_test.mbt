///|
test "GeoJSONGeometryTypes::Point to JSON" {
  let geojson_geometry_types = GeoJSONGeometryTypes::point()
  @json.inspect(geojson_geometry_types, content="Point")
}

///|
test "GeoJSONGeometryTypes::MultiPoint to JSON" {
  let geojson_geometry_types = GeoJSONGeometryTypes::multi_point()
  @json.inspect(geojson_geometry_types, content="MultiPoint")
}

///|
test "GeoJSONGeometryTypes::LineString to JSON" {
  let geojson_geometry_types = GeoJSONGeometryTypes::line_string()
  @json.inspect(geojson_geometry_types, content="LineString")
}

///|
test "GeoJSONGeometryTypes::MultiLineString to JSON" {
  let geojson_geometry_types = GeoJSONGeometryTypes::multi_line_string()
  @json.inspect(geojson_geometry_types, content="MultiLineString")
}

///|
test "GeoJSONGeometryTypes::Polygon to JSON" {
  let geojson_geometry_types = GeoJSONGeometryTypes::polygon()
  @json.inspect(geojson_geometry_types, content="Polygon")
}

///|
test "GeoJSONGeometryTypes::MultiPolygon to JSON" {
  let geojson_geometry_types = GeoJSONGeometryTypes::multi_polygon()
  @json.inspect(geojson_geometry_types, content="MultiPolygon")
}

///|
test "GeoJSONGeometryTypes::GeometryCollection to JSON" {
  let geojson_geometry_types = GeoJSONGeometryTypes::geometry_collection()
  @json.inspect(geojson_geometry_types, content="GeometryCollection")
}

///|
test "GeoJSONGeometryTypes::Point from JSON" {
  let geojson_geometry_types : GeoJSONGeometryTypes = @json.from_json("Point")
  inspect(geojson_geometry_types, content="Point")
}

///|
test "GeoJSONGeometryTypes::MultiPoint from JSON" {
  let geojson_geometry_types : GeoJSONGeometryTypes = @json.from_json(
    "MultiPoint",
  )
  inspect(geojson_geometry_types, content="MultiPoint")
}

///|
test "GeoJSONGeometryTypes::LineString from JSON" {
  let geojson_geometry_types : GeoJSONGeometryTypes = @json.from_json(
    "LineString",
  )
  inspect(geojson_geometry_types, content="LineString")
}

///|
test "GeoJSONGeometryTypes::MultiLineString from JSON" {
  let geojson_geometry_types : GeoJSONGeometryTypes = @json.from_json(
    "MultiLineString",
  )
  inspect(geojson_geometry_types, content="MultiLineString")
}

///|
test "GeoJSONGeometryTypes::Polygon from JSON" {
  let geojson_geometry_types : GeoJSONGeometryTypes = @json.from_json("Polygon")
  inspect(geojson_geometry_types, content="Polygon")
}

///|
test "GeoJSONGeometryTypes::MultiPolygon from JSON" {
  let geojson_geometry_types : GeoJSONGeometryTypes = @json.from_json(
    "MultiPolygon",
  )
  inspect(geojson_geometry_types, content="MultiPolygon")
}

///|
test "GeoJSONGeometryTypes::GeometryCollection from JSON" {
  let geojson_geometry_types : GeoJSONGeometryTypes = @json.from_json(
    "GeometryCollection",
  )
  inspect(geojson_geometry_types, content="GeometryCollection")
}
