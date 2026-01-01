///|
test "GeoJSONObject(BBox is null) to JSON" {
  let geojson_object = GeoJSONObject::new(
    GeoJSONTypes::geometry(GeoJSONGeometryTypes::point()),
  )
  @json.inspect(geojson_object, content={ "type": "Point" })
}

///|
test "GeoJSONObject(BBox is not null) to JSON" {
  let geojson_object = GeoJSONObject::new(
    GeoJSONTypes::geometry(GeoJSONGeometryTypes::point()),
    bbox=Some(
      @bbox.BBox2D::new(
        @position.Position2D::new((1, 2)),
        @position.Position2D::new((3, 4)),
      ).to_bbox(),
    ),
  )
  @json.inspect(geojson_object, content={
    "type": "Point",
    "bbox": [1, 2, 3, 4],
  })
}

///|
test "GeoJSONObject(BBox is null) from JSON" {
  let geojson_object : GeoJSONObject = @json.from_json({ "type": "Point" })
  inspect(geojson_object, content="{_type: Geometry(Point), bbox: None}")
}

///|
test "GeoJSONObject(BBox is not null) from JSON" {
  let geojson_object : GeoJSONObject = @json.from_json({
    "type": "Polygon",
    "bbox": [0, 1, 2, 3],
  })
  inspect(
    geojson_object,
    content="{_type: Geometry(Polygon), bbox: Some(BBox2D({min: {x: 0, y: 1}, max: {x: 2, y: 3}}))}",
  )
}
