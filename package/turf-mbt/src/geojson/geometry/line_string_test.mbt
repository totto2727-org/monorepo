///|
test "LineString to JSON" {
  let line_string = LineString::new([
    @primary.Position::new2D((0.0, 0.0)),
    @primary.Position::new2D((1.0, 1.0)),
  ])
  @json.inspect(line_string, content={
    "type": "LineString",
    "coordinates": [[0, 0], [1, 1]],
  })
}

///|
test "LineString with BBox to JSON" {
  let line_string = LineString::new(
    [@primary.Position::new2D((0.0, 0.0)), @primary.Position::new2D((1.0, 1.0))],
    bbox=Some(@primary.BBox::new2D((0.0, 0.0, 1.0, 1.0))),
  )
  @json.inspect(line_string, content={
    "type": "LineString",
    "bbox": [0, 0, 1, 1],
    "coordinates": [[0, 0], [1, 1]],
  })
}

///|
test "LineString from JSON" {
  let decoded : LineString = @json.from_json({
    "type": "LineString",
    "coordinates": [[10, 20], [30, 40]],
  })
  inspect(
    decoded,
    content="{coordinates: [Position2D((10, 20)), Position2D((30, 40))], bbox: None}",
  )
}

///|
test "LineString with BBox from JSON" {
  let decoded : LineString = @json.from_json({
    "type": "LineString",
    "coordinates": [[10, 20], [30, 40]],
    "bbox": [10, 20, 30, 40],
  })
  inspect(
    decoded,
    content="{coordinates: [Position2D((10, 20)), Position2D((30, 40))], bbox: Some(BBox2D((10, 20, 30, 40)))}",
  )
}

///|
test "panic_LineString from JSON with invalid type" {
  let _ : LineString = @json.from_json({
    "type": "LineString",
    "geometries": [],
    "bbox": [10, 20, 30, 40],
  })

}
