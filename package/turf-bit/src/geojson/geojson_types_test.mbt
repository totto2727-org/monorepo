///|
test "GeoJsonTypes::Geometry to JSON" {
  let geojson_types = GeoJsonTypes::geometry(GeoJsonGeometryTypes::point())
  @json.inspect(geojson_types, content="Point")
}

///|
test "GeoJsonTypes::Feature to JSON" {
  let geojson_types = GeoJsonTypes::feature()
  @json.inspect(geojson_types, content="Feature")
}

///|
test "GeoJsonTypes::FeatureCollection to JSON" {
  let geojson_types = GeoJsonTypes::feature_collection()
  @json.inspect(geojson_types, content="FeatureCollection")
}

///|
test "GeoJsonTypes::Geometry::Point from JSON" {
  let geojson_types : GeoJsonTypes = @json.from_json("Point")
  inspect(geojson_types, content="Geometry(Point)")
}

///|
test "GeoJsonTypes::Feature from JSON" {
  let geojson_types : GeoJsonTypes = @json.from_json("Feature")
  inspect(geojson_types, content="Feature")
}

///|
test "GeoJsonTypes::FeatureCollection from JSON" {
  let geojson_types : GeoJsonTypes = @json.from_json("FeatureCollection")
  inspect(geojson_types, content="FeatureCollection")
}
