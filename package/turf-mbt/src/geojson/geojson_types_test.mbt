///|
test "GeoJSONTypes to_json - Geometry" {
  let geojson_types = GeoJSONTypes::geometry(GeoJSONGeometryTypes::point())
  @json.inspect(geojson_types, content="Point")
}

///|
test "GeoJSONTypes to_json - Feature" {
  let geojson_types = GeoJSONTypes::feature()
  @json.inspect(geojson_types, content="Feature")
}

///|
test "GeoJSONTypes to_json - FeatureCollection" {
  let geojson_types = GeoJSONTypes::feature_collection()
  @json.inspect(geojson_types, content="FeatureCollection")
}

///|
test "GeoJSONTypes from_json - Geometry Point" {
  let geojson_types : GeoJSONTypes = @json.from_json("Point")
  inspect(geojson_types, content="Geometry(Point)")
}

///|
test "GeoJSONTypes from_json - Feature" {
  let geojson_types : GeoJSONTypes = @json.from_json("Feature")
  inspect(geojson_types, content="Feature")
}

///|
test "GeoJSONTypes from_json - FeatureCollection" {
  let geojson_types : GeoJSONTypes = @json.from_json("FeatureCollection")
  inspect(geojson_types, content="FeatureCollection")
}
