///|
test "MultiLineString to JSON" {
  let multi_line_string = MultiLineString::new([
    LineString::new([
      @primary.Position::new2D((0.0, 0.0)),
      @primary.Position::new2D((1.0, 1.0)),
    ]),
    LineString::new([
      @primary.Position::new2D((1.0, 1.0)),
      @primary.Position::new2D((0.0, 0.0)),
    ]),
  ])
  @json.inspect(multi_line_string, content={
    "type": "MultiLineString",
    "coordinates": [[[0, 0], [1, 1]], [[1, 1], [0, 0]]],
  })
}

///|
test "MultiLineString with BBox to JSON" {
  let multi_line_string = MultiLineString::new(
    [
      LineString::new([
        @primary.Position::new2D((0.0, 0.0)),
        @primary.Position::new2D((1.0, 1.0)),
      ]),
      LineString::new([
        @primary.Position::new2D((1.0, 1.0)),
        @primary.Position::new2D((0.0, 0.0)),
      ]),
    ],
    bbox=Some(@primary.BBox::new2D((0.0, 0.0, 1.0, 1.0))),
  )
  @json.inspect(multi_line_string, content={
    "type": "MultiLineString",
    "bbox": [0, 0, 1, 1],
    "coordinates": [[[0, 0], [1, 1]], [[1, 1], [0, 0]]],
  })
}

///|
test "MultiLineString from JSON" {
  let decoded : MultiLineString = @json.from_json({
    "type": "MultiLineString",
    "coordinates": [[[10, 20], [30, 40]], [[50, 60], [70, 80]]],
  })
  inspect(
    decoded,
    content="{lines: [{coordinates: [Position2D((10, 20)), Position2D((30, 40))], bbox: None}, {coordinates: [Position2D((50, 60)), Position2D((70, 80))], bbox: None}], bbox: None}",
  )
}

///|
test "MultiLineString with BBox from JSON" {
  let decoded : MultiLineString = @json.from_json({
    "type": "MultiLineString",
    "coordinates": [[[10, 20], [30, 40]], [[50, 60], [70, 80]]],
    "bbox": [10, 20, 70, 80],
  })
  inspect(
    decoded,
    content="{lines: [{coordinates: [Position2D((10, 20)), Position2D((30, 40))], bbox: None}, {coordinates: [Position2D((50, 60)), Position2D((70, 80))], bbox: None}], bbox: Some(BBox2D((10, 20, 70, 80)))}",
  )
}

///|
test "panic_MultiLineString from JSON with invalid type" {
  let _ : MultiLineString = @json.from_json({
    "type": "MultiLineString",
    "geometries": [],
    "bbox": [10, 20, 30, 40],
  })

}
