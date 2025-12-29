///|
test "GeoJSONTypes::Geometry to JSON" {
  let geojson_types = GeoJSONTypes::geometry(GeoJSONGeometryTypes::point())
  @json.inspect(geojson_types, content="Point")
}

///|
test "GeoJSONTypes::Feature to JSON" {
  let geojson_types = GeoJSONTypes::feature()
  @json.inspect(geojson_types, content="Feature")
}

///|
test "GeoJSONTypes::FeatureCollection to JSON" {
  let geojson_types = GeoJSONTypes::feature_collection()
  @json.inspect(geojson_types, content="FeatureCollection")
}

///|
test "GeoJSONTypes::Geometry::Point from JSON" {
  let geojson_types : GeoJSONTypes = @json.from_json("Point")
  inspect(geojson_types, content="Geometry(Point)")
}

///|
test "GeoJSONTypes::Feature from JSON" {
  let geojson_types : GeoJSONTypes = @json.from_json("Feature")
  inspect(geojson_types, content="Feature")
}

///|
test "GeoJSONTypes::FeatureCollection from JSON" {
  let geojson_types : GeoJSONTypes = @json.from_json("FeatureCollection")
  inspect(geojson_types, content="FeatureCollection")
}
