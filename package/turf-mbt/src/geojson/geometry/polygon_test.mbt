///|
test "Polygon to JSON" {
  let polygon = Polygon::new([
    [
      @primary.Position::new2D((0.0, 0.0)),
      @primary.Position::new2D((0.0, 1.0)),
      @primary.Position::new2D((1.0, 0.0)),
      @primary.Position::new2D((0.0, 0.0)),
    ],
  ])
  @json.inspect(polygon, content={
    "type": "Polygon",
    "coordinates": [[[0, 0], [0, 1], [1, 0], [0, 0]]],
  })
}

///|
test "Polygon with BBox to JSON" {
  let polygon = Polygon::new(
    [
      [
        @primary.Position::new2D((0.0, 0.0)),
        @primary.Position::new2D((0.0, 1.0)),
        @primary.Position::new2D((1.0, 0.0)),
        @primary.Position::new2D((0.0, 0.0)),
      ],
    ],
    bbox=Some(@primary.BBox::new2D((0.0, 0.0, 1.0, 1.0))),
  )
  @json.inspect(polygon, content={
    "type": "Polygon",
    "bbox": [0, 0, 1, 1],
    "coordinates": [[[0, 0], [0, 1], [1, 0], [0, 0]]],
  })
}

///|
test "Polygon from JSON" {
  let decoded : Polygon = @json.from_json({
    "type": "Polygon",
    "coordinates": [[[10, 20], [30, 40], [50, 60], [10, 20]]],
  })
  inspect(
    decoded,
    content="{coordinates: [[Position2D((10, 20)), Position2D((30, 40)), Position2D((50, 60)), Position2D((10, 20))]], bbox: None}",
  )
}

///|
test "Polygon with BBox from JSON" {
  let decoded : Polygon = @json.from_json({
    "type": "Polygon",
    "coordinates": [[[10, 20], [30, 40], [50, 60], [10, 20]]],
    "bbox": [10, 20, 50, 60],
  })
  inspect(
    decoded,
    content="{coordinates: [[Position2D((10, 20)), Position2D((30, 40)), Position2D((50, 60)), Position2D((10, 20))]], bbox: Some(BBox2D((10, 20, 50, 60)))}",
  )
}

///|
test "panic_Polygon from Json with too few positions" {
  let _ : Polygon = @json.from_json({
    "type": "Polygon",
    "coordinates": [[[0, 0], [1, 1], [0, 0]]],
  })

}

///|
test "panic_Polygon from Json with non-equivalent first/last" {
  let _ : Polygon = @json.from_json({
    "type": "Polygon",
    "coordinates": [[[0, 0], [1, 1], [2, 2], [3, 3]]],
  })

}

///|
test "panic_Polygon from JSON with invalid type" {
  let _ : Polygon = @json.from_json({
    "type": "Polygon",
    "geometries": [],
    "bbox": [10, 20, 30, 40],
  })

}
