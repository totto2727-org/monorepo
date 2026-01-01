///|
test "Point to JSON" {
  let point = Point::new(@position.Position2D::new((0.0, 0.0)).to_position())
  @json.inspect(point, content={ "type": "Point", "coordinates": [0, 0] })
}

///|
test "Point with BBox to JSON" {
  let point = Point::new(
    @position.Position2D::new((10.0, 20.0)).to_position(),
    bbox=Some(
      @bbox.BBox2D::new(
        @position.Position2D::new((10.0, 20.0)),
        @position.Position2D::new((10.0, 20.0)),
      ).to_bbox(),
    ),
  )
  @json.inspect(point, content={
    "type": "Point",
    "bbox": [10, 20, 10, 20],
    "coordinates": [10, 20],
  })
}

///|
test "Point to_bbox without bbox" {
  let point = Point::new(@position.Position2D::new((10.0, 20.0)).to_position())
  let bbox = point.to_bbox()
  inspect(bbox, content="BBox2D({min: {x: 10, y: 20}, max: {x: 10, y: 20}})")
}

///|
test "Point to_bbox with bbox (no re-compute)" {
  let custom_bbox = @bbox.BBox2D::new(
    @position.Position2D::new((0.0, 0.0)),
    @position.Position2D::new((0.0, 0.0)),
  ).to_bbox()
  let point = Point::new(
    @position.Position2D::new((10.0, 20.0)).to_position(),
    bbox=Some(custom_bbox),
  )
  let result = point.to_bbox(re_compute=false)
  inspect(result, content="BBox2D({min: {x: 0, y: 0}, max: {x: 0, y: 0}})")
  assert_eq(result, custom_bbox)
}

///|
test "Point to_bbox with bbox (force re-compute)" {
  let custom_bbox = @bbox.BBox2D::new(
    @position.Position2D::new((0.0, 0.0)),
    @position.Position2D::new((0.0, 0.0)),
  ).to_bbox()
  let point = Point::new(
    @position.Position2D::new((10.0, 20.0)).to_position(),
    bbox=Some(custom_bbox),
  )
  let result = point.to_bbox(re_compute=true)
  inspect(result, content="BBox2D({min: {x: 10, y: 20}, max: {x: 10, y: 20}})")
  assert_not_eq(result, custom_bbox)
}

///|
test "Point from JSON" {
  let decoded : Point = @json.from_json({
    "type": "Point",
    "coordinates": [10, 20],
  })
  inspect(
    decoded,
    content="{coordinates: Position2D({x: 10, y: 20}), bbox: None}",
  )
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
    content="{coordinates: Position2D({x: 10, y: 20}), bbox: Some(BBox2D({min: {x: 10, y: 20}, max: {x: 10, y: 20}}))}",
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
