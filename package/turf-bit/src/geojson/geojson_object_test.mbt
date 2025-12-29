///|
test "GeoJsonObject(BBox is null) to JSON" {
  let geojson_object = GeoJsonObject::new(
    GeoJsonTypes::geometry(GeoJsonGeometryTypes::point()),
  )
  @json.inspect(geojson_object, content={ "type": "Point" })
}

///|
test "GeoJsonObject(BBox is not null) to JSON" {
  let geojson_object = GeoJsonObject::new(
    GeoJsonTypes::geometry(GeoJsonGeometryTypes::point()),
    bbox=Some(BBox::new2D((1, 2, 3, 4))),
  )
  @json.inspect(geojson_object, content={
    "type": "Point",
    "bbox": [1, 2, 3, 4],
  })
}

///|
test "GeoJsonObject(BBox is null) from JSON" {
  let geojson_object : GeoJsonObject = @json.from_json({ "type": "Point" })
  inspect(geojson_object, content="{_type: Geometry(Point), bbox: None}")
}

///|
test "GeoJsonObject(BBox is not null) from JSON" {
  let geojson_object : GeoJsonObject = @json.from_json({
    "type": "Polygon",
    "bbox": [0, 1, 2, 3],
  })
  inspect(
    geojson_object,
    content="{_type: Geometry(Polygon), bbox: Some(BBox2D(0, 1, 2, 3))}",
  )
}
