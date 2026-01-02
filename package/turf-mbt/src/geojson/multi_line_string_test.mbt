///|
test "MultiLineString to_json - simple" {
  let multi_line_string = MultiLineString::new([
    LineString::new([
      Position2D::new((0.0, 0.0)).to_position(),
      Position2D::new((1.0, 1.0)).to_position(),
    ]),
    LineString::new([
      Position2D::new((1.0, 1.0)).to_position(),
      Position2D::new((0.0, 0.0)).to_position(),
    ]),
  ])
  @json.inspect(multi_line_string, content={
    "type": "MultiLineString",
    "coordinates": [[[0, 0], [1, 1]], [[1, 1], [0, 0]]],
  })
}

///|
test "MultiLineString to_json - with bbox" {
  let multi_line_string = MultiLineString::new(
    [
      LineString::new([
        Position2D::new((0.0, 0.0)).to_position(),
        Position2D::new((1.0, 1.0)).to_position(),
      ]),
      LineString::new([
        Position2D::new((1.0, 1.0)).to_position(),
        Position2D::new((0.0, 0.0)).to_position(),
      ]),
    ],
    bbox=Some(
      BBox2D::new(Position2D::new((0.0, 0.0)), Position2D::new((1.0, 1.0))).to_bbox(),
    ),
  )
  @json.inspect(multi_line_string, content={
    "type": "MultiLineString",
    "bbox": [0, 0, 1, 1],
    "coordinates": [[[0, 0], [1, 1]], [[1, 1], [0, 0]]],
  })
}

///|
test "MultiLineString from_json - simple" {
  let decoded : MultiLineString = @json.from_json({
    "type": "MultiLineString",
    "coordinates": [[[10, 20], [30, 40]], [[50, 60], [70, 80]]],
  })
  inspect(
    decoded,
    content="{lines: [{coordinates: [Position2D({x: 10, y: 20}), Position2D({x: 30, y: 40})], bbox: None}, {coordinates: [Position2D({x: 50, y: 60}), Position2D({x: 70, y: 80})], bbox: None}], bbox: None}",
  )
}

///|
test "MultiLineString from_json - with bbox" {
  let decoded : MultiLineString = @json.from_json({
    "type": "MultiLineString",
    "coordinates": [[[10, 20], [30, 40]], [[50, 60], [70, 80]]],
    "bbox": [10, 20, 70, 80],
  })
  inspect(
    decoded,
    content="{lines: [{coordinates: [Position2D({x: 10, y: 20}), Position2D({x: 30, y: 40})], bbox: None}, {coordinates: [Position2D({x: 50, y: 60}), Position2D({x: 70, y: 80})], bbox: None}], bbox: Some(BBox2D({min: {x: 10, y: 20}, max: {x: 70, y: 80}}))}",
  )
}

///|
test "panic_MultiLineString from_json - invalid type" {
  let _ : MultiLineString = @json.from_json({
    "type": "MultiLineString",
    "geometries": [],
    "bbox": [10, 20, 30, 40],
  })

}

///|
test "MultiLineString to_bbox - without bbox" {
  let multi_line_string = MultiLineString::new([
    LineString::new([
      Position2D::new((0.0, 0.0)).to_position(),
      Position2D::new((10.0, 10.0)).to_position(),
    ]),
  ])
  let bbox = multi_line_string.to_bbox()
  inspect(bbox, content="BBox2D({min: {x: 0, y: 0}, max: {x: 10, y: 10}})")
}

///|
test "MultiLineString to_bbox - with bbox (no re-compute)" {
  let custom_bbox = BBox2D::new(
    Position2D::new((0.0, 0.0)),
    Position2D::new((0.0, 0.0)),
  ).to_bbox()
  let multi_line_string = MultiLineString::new(
    [
      LineString::new([
        Position2D::new((0.0, 0.0)).to_position(),
        Position2D::new((10.0, 10.0)).to_position(),
      ]),
    ],
    bbox=Some(custom_bbox),
  )
  let result = multi_line_string.to_bbox(re_compute=false)
  inspect(result, content="BBox2D({min: {x: 0, y: 0}, max: {x: 0, y: 0}})")
  assert_eq(result, custom_bbox)
}

///|
test "MultiLineString to_bbox - with bbox (force re-compute)" {
  let custom_bbox = BBox2D::new(
    Position2D::new((0.0, 0.0)),
    Position2D::new((0.0, 0.0)),
  ).to_bbox()
  let multi_line_string = MultiLineString::new(
    [
      LineString::new([
        Position2D::new((0.0, 0.0)).to_position(),
        Position2D::new((10.0, 10.0)).to_position(),
      ]),
    ],
    bbox=Some(custom_bbox),
  )
  let result = multi_line_string.to_bbox(re_compute=true)
  inspect(result, content="BBox2D({min: {x: 0, y: 0}, max: {x: 10, y: 10}})")
  assert_not_eq(result, custom_bbox)
}
