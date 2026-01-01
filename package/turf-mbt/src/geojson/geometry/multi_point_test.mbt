///|
test "MultiPoint to JSON" {
  let multi_point = MultiPoint::new([
    Point::new(@position.Position2D::new((0.0, 0.0)).to_position()),
    Point::new(@position.Position2D::new((1.0, 1.0)).to_position()),
  ])
  @json.inspect(multi_point, content={
    "type": "MultiPoint",
    "coordinates": [[0, 0], [1, 1]],
  })
}

///|
test "MultiPoint with BBox to JSON" {
  let multi_point = MultiPoint::new(
    [
      Point::new(@position.Position2D::new((0.0, 0.0)).to_position()),
      Point::new(@position.Position2D::new((1.0, 1.0)).to_position()),
    ],
    bbox=Some(
      @bbox.BBox2D::new(
        @position.Position2D::new((0.0, 0.0)),
        @position.Position2D::new((1.0, 1.0)),
      ).to_bbox(),
    ),
  )
  @json.inspect(multi_point, content={
    "type": "MultiPoint",
    "bbox": [0, 0, 1, 1],
    "coordinates": [[0, 0], [1, 1]],
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
    content="{points: [{coordinates: Position2D({x: 10, y: 20}), bbox: None}, {coordinates: Position2D({x: 30, y: 40}), bbox: None}], bbox: None}",
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
    content="{points: [{coordinates: Position2D({x: 10, y: 20}), bbox: None}, {coordinates: Position2D({x: 30, y: 40}), bbox: None}], bbox: Some(BBox2D({min: {x: 10, y: 20}, max: {x: 30, y: 40}}))}",
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

///|
test "MultiPoint to_bbox without bbox" {
  let multi_point = MultiPoint::new([
    Point::new(@position.Position2D::new((0.0, 0.0)).to_position()),
    Point::new(@position.Position2D::new((10.0, 10.0)).to_position()),
  ])
  let bbox = multi_point.to_bbox()
  inspect(bbox, content="BBox2D({min: {x: 0, y: 0}, max: {x: 10, y: 10}})")
}

///|
test "MultiPoint to_bbox with bbox (no re-compute)" {
  let custom_bbox = @bbox.BBox2D::new(
    @position.Position2D::new((0.0, 0.0)),
    @position.Position2D::new((0.0, 0.0)),
  ).to_bbox()
  let multi_point = MultiPoint::new(
    [
      Point::new(@position.Position2D::new((0.0, 0.0)).to_position()),
      Point::new(@position.Position2D::new((10.0, 10.0)).to_position()),
    ],
    bbox=Some(custom_bbox),
  )
  let result = multi_point.to_bbox(re_compute=false)
  inspect(result, content="BBox2D({min: {x: 0, y: 0}, max: {x: 0, y: 0}})")
  assert_eq(result, custom_bbox)
}

///|
test "MultiPoint to_bbox with bbox (force re-compute)" {
  let custom_bbox = @bbox.BBox2D::new(
    @position.Position2D::new((0.0, 0.0)),
    @position.Position2D::new((0.0, 0.0)),
  ).to_bbox()
  let multi_point = MultiPoint::new(
    [
      Point::new(@position.Position2D::new((0.0, 0.0)).to_position()),
      Point::new(@position.Position2D::new((10.0, 10.0)).to_position()),
    ],
    bbox=Some(custom_bbox),
  )
  let result = multi_point.to_bbox(re_compute=true)
  inspect(result, content="BBox2D({min: {x: 0, y: 0}, max: {x: 10, y: 10}})")
  assert_not_eq(result, custom_bbox)
}
