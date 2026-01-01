///|
test "MultiPoint to JSON" {
  let multi_point = MultiPoint::new([
    Point::new(@primary.Position::new2D((0.0, 0.0))),
    Point::new(@primary.Position::new2D((1.0, 1.0))),
  ])
  @json.inspect(multi_point, content={
    "type": "MultiPoint",
    "coordinates": [
      { "type": "Point", "coordinates": [0, 0] },
      { "type": "Point", "coordinates": [1, 1] },
    ],
  })
}

///|
test "MultiPoint with BBox to JSON" {
  let multi_point = MultiPoint::new(
    [
      Point::new(@primary.Position::new2D((0.0, 0.0))),
      Point::new(@primary.Position::new2D((1.0, 1.0))),
    ],
    bbox=Some(@primary.BBox::new2D((0.0, 0.0, 1.0, 1.0))),
  )
  @json.inspect(multi_point, content={
    "type": "MultiPoint",
    "bbox": [0, 0, 1, 1],
    "coordinates": [
      { "type": "Point", "coordinates": [0, 0] },
      { "type": "Point", "coordinates": [1, 1] },
    ],
  })
}

///|
test "MultiPoint from JSON" {
  let decoded : MultiPoint = @json.from_json({
    "type": "MultiPoint",
    "coordinates": [[10, 20], [30, 40]],
  })
  inspect(
    decoded,
    content="{points: [{coordinates: Position2D((10, 20)), bbox: None}, {coordinates: Position2D((30, 40)), bbox: None}], bbox: None}",
  )
}

///|
test "MultiPoint with BBox from JSON" {
  let decoded : MultiPoint = @json.from_json({
    "type": "MultiPoint",
    "coordinates": [[10, 20], [30, 40]],
    "bbox": [10, 20, 30, 40],
  })
  inspect(
    decoded,
    content="{points: [{coordinates: Position2D((10, 20)), bbox: None}, {coordinates: Position2D((30, 40)), bbox: None}], bbox: Some(BBox2D((10, 20, 30, 40)))}",
  )
}

///|
test "panic_MultiPoint from JSON with invalid type" {
  let _ : MultiPoint = @json.from_json({
    "type": "MultiPoint",
    "geometries": [],
    "bbox": [10, 20, 30, 40],
  })

}
