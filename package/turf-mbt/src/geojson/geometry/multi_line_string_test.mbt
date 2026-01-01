///|
test "MultiLineString to JSON" {
  let multi_line_string = MultiLineString::new([
    LineString::new([
      @position.Position2D::new((0.0, 0.0)).to_position(),
      @position.Position2D::new((1.0, 1.0)).to_position(),
    ]),
    LineString::new([
      @position.Position2D::new((1.0, 1.0)).to_position(),
      @position.Position2D::new((0.0, 0.0)).to_position(),
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
        @position.Position2D::new((0.0, 0.0)).to_position(),
        @position.Position2D::new((1.0, 1.0)).to_position(),
      ]),
      LineString::new([
        @position.Position2D::new((1.0, 1.0)).to_position(),
        @position.Position2D::new((0.0, 0.0)).to_position(),
      ]),
    ],
    bbox=Some(
      @bbox.BBox2D::new(
        @position.Position2D::new((0.0, 0.0)),
        @position.Position2D::new((1.0, 1.0)),
      ).to_bbox(),
    ),
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
