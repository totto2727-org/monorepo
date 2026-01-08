///|
test "LineString to_json - simple" {
  let line_string = LineString::new([
    Position2D::new((0.0, 0.0)).to_position(),
    Position2D::new((1.0, 1.0)).to_position(),
  ])
  @json.inspect(line_string, content={
    "type": "LineString",
    "coordinates": [[0, 0], [1, 1]],
  })
}

///|
test "LineString to_json - with bbox" {
  let line_string = LineString::new(
    [
      Position2D::new((0.0, 0.0)).to_position(),
      Position2D::new((1.0, 1.0)).to_position(),
    ],
    bbox=Some(
      BBox2D::new(Position2D::new((0.0, 0.0)), Position2D::new((1.0, 1.0))).to_bbox(),
    ),
  )
  @json.inspect(line_string, content={
    "type": "LineString",
    "bbox": [0, 0, 1, 1],
    "coordinates": [[0, 0], [1, 1]],
  })
}

///|
test "LineString from_json - simple" {
  let decoded : LineString = @json.from_json({
    "type": "LineString",
    "coordinates": [[10, 20], [30, 40]],
  })
  inspect(
    decoded,
    content="{coordinates: [Position2D({x: 10, y: 20}), Position2D({x: 30, y: 40})], bbox: None}",
  )
}

///|
test "LineString from_json - with bbox" {
  let decoded : LineString = @json.from_json({
    "type": "LineString",
    "coordinates": [[10, 20], [30, 40]],
    "bbox": [10, 20, 30, 40],
  })
  inspect(
    decoded,
    content="{coordinates: [Position2D({x: 10, y: 20}), Position2D({x: 30, y: 40})], bbox: Some(BBox2D({min: {x: 10, y: 20}, max: {x: 30, y: 40}}))}",
  )
}

///|
test "panic_LineString from_json - invalid type" {
  let _ : LineString = @json.from_json({
    "type": "LineString",
    "geometries": [],
    "bbox": [10, 20, 30, 40],
  })

}

///|
test "LineString to_bbox - without bbox" {
  let line_string = LineString::new([
    Position2D::new((0.0, 0.0)).to_position(),
    Position2D::new((10.0, 10.0)).to_position(),
  ])
  let bbox = line_string.to_bbox()
  inspect(bbox, content="BBox2D({min: {x: 0, y: 0}, max: {x: 10, y: 10}})")
}

///|
test "LineString to_bbox - with bbox (no re-compute)" {
  let custom_bbox = BBox2D::new(
    Position2D::new((0.0, 0.0)),
    Position2D::new((0.0, 0.0)),
  ).to_bbox()
  let line_string = LineString::new(
    [
      Position2D::new((0.0, 0.0)).to_position(),
      Position2D::new((10.0, 10.0)).to_position(),
    ],
    bbox=Some(custom_bbox),
  )
  let result = line_string.to_bbox(re_compute=false)
  inspect(result, content="BBox2D({min: {x: 0, y: 0}, max: {x: 0, y: 0}})")
  assert_eq(result, custom_bbox)
}

///|
test "LineString to_bbox - with bbox (force re-compute)" {
  let custom_bbox = BBox2D::new(
    Position2D::new((0.0, 0.0)),
    Position2D::new((0.0, 0.0)),
  ).to_bbox()
  let line_string = LineString::new(
    [
      Position2D::new((0.0, 0.0)).to_position(),
      Position2D::new((10.0, 10.0)).to_position(),
    ],
    bbox=Some(custom_bbox),
  )
  let result = line_string.to_bbox(re_compute=true)
  inspect(result, content="BBox2D({min: {x: 0, y: 0}, max: {x: 10, y: 10}})")
  assert_not_eq(result, custom_bbox)
}
