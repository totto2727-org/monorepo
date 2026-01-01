///|
test "Point to JSON" {
  let point = Point::new(@primary.Position::new2D((0.0, 0.0)))
  @json.inspect(point, content={ "type": "Point", "coordinates": [0, 0] })
}

///|
test "Point with BBox to JSON" {
  let point = Point::new(
    @primary.Position::new2D((10.0, 20.0)),
    bbox=Some(@primary.BBox::new2D((10.0, 20.0, 10.0, 20.0))),
  )
  @json.inspect(point, content={
    "type": "Point",
    "bbox": [10, 20, 10, 20],
    "coordinates": [10, 20],
  })
}

///|
test "Point from JSON" {
  let decoded : Point = @json.from_json({
    "type": "Point",
    "coordinates": [10, 20],
  })
  inspect(decoded, content="{coordinates: Position2D((10, 20)), bbox: None}")
}

///|
test "Point with BBox from JSON" {
  let decoded : Point = @json.from_json({
    "type": "Point",
    "coordinates": [10, 20],
    "bbox": [10, 20, 10, 20],
  })
  inspect(
    decoded,
    content="{coordinates: Position2D((10, 20)), bbox: Some(BBox2D((10, 20, 10, 20)))}",
  )
}

///|
test "panic_Point from JSON with invalid type" {
  let _ : Point = @json.from_json({
    "type": "Point",
    "geometries": [],
    "bbox": [10, 20, 30, 40],
  })

}
