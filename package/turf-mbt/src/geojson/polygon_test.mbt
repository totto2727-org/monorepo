///|
test "Polygon to_json - simple" {
  let polygon = Polygon::new([
    [
      Position2D::new((0.0, 0.0)).to_position(),
      Position2D::new((0.0, 1.0)).to_position(),
      Position2D::new((1.0, 0.0)).to_position(),
      Position2D::new((0.0, 0.0)).to_position(),
    ],
  ])
  @json.inspect(polygon, content={
    "type": "Polygon",
    "coordinates": [[[0, 0], [0, 1], [1, 0], [0, 0]]],
  })
}

///|
test "Polygon to_json - with bbox" {
  let polygon = Polygon::new(
    [
      [
        Position2D::new((0.0, 0.0)).to_position(),
        Position2D::new((0.0, 1.0)).to_position(),
        Position2D::new((1.0, 0.0)).to_position(),
        Position2D::new((0.0, 0.0)).to_position(),
      ],
    ],
    bbox=Some(
      BBox2D::new(Position2D::new((0.0, 0.0)), Position2D::new((1.0, 1.0))).to_bbox(),
    ),
  )
  @json.inspect(polygon, content={
    "type": "Polygon",
    "bbox": [0, 0, 1, 1],
    "coordinates": [[[0, 0], [0, 1], [1, 0], [0, 0]]],
  })
}

///|
test "Polygon from_json - simple" {
  let decoded : Polygon = @json.from_json({
    "type": "Polygon",
    "coordinates": [[[10, 20], [30, 40], [50, 60], [10, 20]]],
  })
  inspect(
    decoded,
    content="{coordinates: [[Position2D({x: 10, y: 20}), Position2D({x: 30, y: 40}), Position2D({x: 50, y: 60}), Position2D({x: 10, y: 20})]], bbox: None}",
  )
}

///|
test "Polygon from_json - with bbox" {
  let decoded : Polygon = @json.from_json({
    "type": "Polygon",
    "coordinates": [[[10, 20], [30, 40], [50, 60], [10, 20]]],
    "bbox": [10, 20, 50, 60],
  })
  inspect(
    decoded,
    content="{coordinates: [[Position2D({x: 10, y: 20}), Position2D({x: 30, y: 40}), Position2D({x: 50, y: 60}), Position2D({x: 10, y: 20})]], bbox: Some(BBox2D({min: {x: 10, y: 20}, max: {x: 50, y: 60}}))}",
  )
}

///|
test "panic_Polygon from_json - too few positions" {
  let _ : Polygon = @json.from_json({
    "type": "Polygon",
    "coordinates": [[[0, 0], [1, 1], [0, 0]]],
  })

}

///|
test "panic_Polygon from_json - non-equivalent first/last" {
  let _ : Polygon = @json.from_json({
    "type": "Polygon",
    "coordinates": [[[0, 0], [1, 1], [2, 2], [3, 3]]],
  })

}

///|
test "panic_Polygon from_json - invalid type" {
  let _ : Polygon = @json.from_json({
    "type": "Polygon",
    "geometries": [],
    "bbox": [10, 20, 30, 40],
  })

}

///|
test "Polygon to_bbox - without bbox" {
  let polygon = Polygon::new([
    [
      Position2D::new((0.0, 0.0)).to_position(),
      Position2D::new((0.0, 10.0)).to_position(),
      Position2D::new((10.0, 0.0)).to_position(),
      Position2D::new((0.0, 0.0)).to_position(),
    ],
  ])
  let bbox = polygon.to_bbox()
  inspect(bbox, content="BBox2D({min: {x: 0, y: 0}, max: {x: 10, y: 10}})")
}

///|
test "Polygon to_bbox - with bbox (no re-compute)" {
  let custom_bbox = BBox2D::new(
    Position2D::new((0.0, 0.0)),
    Position2D::new((0.0, 0.0)),
  ).to_bbox()
  let polygon = Polygon::new(
    [
      [
        Position2D::new((0.0, 0.0)).to_position(),
        Position2D::new((0.0, 10.0)).to_position(),
        Position2D::new((10.0, 0.0)).to_position(),
        Position2D::new((0.0, 0.0)).to_position(),
      ],
    ],
    bbox=Some(custom_bbox),
  )
  let result = polygon.to_bbox(re_compute=false)
  inspect(result, content="BBox2D({min: {x: 0, y: 0}, max: {x: 0, y: 0}})")
  assert_eq(result, custom_bbox)
}

///|
test "Polygon to_bbox - with bbox (force re-compute)" {
  let custom_bbox = BBox2D::new(
    Position2D::new((0.0, 0.0)),
    Position2D::new((0.0, 0.0)),
  ).to_bbox()
  let polygon = Polygon::new(
    [
      [
        Position2D::new((0.0, 0.0)).to_position(),
        Position2D::new((0.0, 10.0)).to_position(),
        Position2D::new((10.0, 0.0)).to_position(),
        Position2D::new((0.0, 0.0)).to_position(),
      ],
    ],
    bbox=Some(custom_bbox),
  )
  let result = polygon.to_bbox(re_compute=true)
  inspect(result, content="BBox2D({min: {x: 0, y: 0}, max: {x: 10, y: 10}})")
  assert_not_eq(result, custom_bbox)
}
