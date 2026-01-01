///|
test "is inside Switzerland" {
  let json_string = @fs.read_file_to_string(
    "src/util/point_in_polygon/test/fixtures/switzerland.geojson",
  )
  let json = @json.parse(json_string)
  let feature : @geojson.Feature = @json.from_json(json)
  guard feature.geometry is Some(@geojson.Geometry::Polygon(poly))
  let result = @point_in_polygon.point_in_polygon(
    @geojson.Position2D::new((8.0, 46.5)),
    poly,
  )
  inspect(result, content="Inside")
}

///|
test "is outside Switzerland" {
  let json_string = @fs.read_file_to_string(
    "src/util/point_in_polygon/test/fixtures/switzerland.geojson",
  )
  let json = @json.parse(json_string)
  let feature : @geojson.Feature = @json.from_json(json)
  guard feature.geometry is Some(@geojson.Geometry::Polygon(poly))
  let result = @point_in_polygon.point_in_polygon(
    @geojson.Position2D::new((8.0, 44.0)),
    poly,
  )
  inspect(result, content="Outside")
}

///|
test "is inside kinked Switzerland" {
  let json_string = @fs.read_file_to_string(
    "src/util/point_in_polygon/test/fixtures/switzerlandKinked.geojson",
  )
  let json = @json.parse(json_string)
  let feature : @geojson.Feature = @json.from_json(json)
  guard feature.geometry is Some(@geojson.Geometry::Polygon(poly))
  let result = @point_in_polygon.point_in_polygon(
    @geojson.Position2D::new((8.0, 46.5)),
    poly,
  )
  inspect(result, content="Inside")
}

///|
test "is outside kinked Switzerland" {
  let json_string = @fs.read_file_to_string(
    "src/util/point_in_polygon/test/fixtures/switzerlandKinked.geojson",
  )
  let json = @json.parse(json_string)
  let feature : @geojson.Feature = @json.from_json(json)
  guard feature.geometry is Some(@geojson.Geometry::Polygon(poly))
  let result = @point_in_polygon.point_in_polygon(
    @geojson.Position2D::new((8.0, 44.0)),
    poly,
  )
  inspect(result, content="Outside")
}
