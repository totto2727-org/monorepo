///|
test "LineString to JSON" {
  let line_string = LineString::new([
    @position.Position2D::new((0.0, 0.0)).to_position(),
    @position.Position2D::new((1.0, 1.0)).to_position(),
  ])
  @json.inspect(line_string, content={
    "type": "LineString",
    "coordinates": [[0, 0], [1, 1]],
  })
}

///|
test "LineString with BBox to JSON" {
  let line_string = LineString::new(
    [
      @position.Position2D::new((0.0, 0.0)).to_position(),
      @position.Position2D::new((1.0, 1.0)).to_position(),
    ],
    bbox=Some(
      @bbox.BBox2D::new(
        @position.Position2D::new((0.0, 0.0)),
        @position.Position2D::new((1.0, 1.0)),
      ).to_bbox(),
    ),
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
