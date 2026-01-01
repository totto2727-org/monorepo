///|
test "MultiPolygon to_json - simple" {
  let multi_polygon = MultiPolygon::new([
    Polygon::new([
      [
        @position.Position2D::new((0.0, 0.0)).to_position(),
        @position.Position2D::new((0.0, 1.0)).to_position(),
        @position.Position2D::new((1.0, 0.0)).to_position(),
        @position.Position2D::new((0.0, 0.0)).to_position(),
      ],
    ]),
    Polygon::new([
      [
        @position.Position2D::new((0.0, 0.0)).to_position(),
        @position.Position2D::new((0.0, 1.0)).to_position(),
        @position.Position2D::new((1.0, 0.0)).to_position(),
        @position.Position2D::new((0.0, 0.0)).to_position(),
      ],
    ]),
  ])
  @json.inspect(multi_polygon, content={
    "type": "MultiPolygon",
    "coordinates": [
      [[[0, 0], [0, 1], [1, 0], [0, 0]]],
      [[[0, 0], [0, 1], [1, 0], [0, 0]]],
    ],
  })
}

///|
test "MultiPolygon to_json - with bbox" {
  let multi_polygon = MultiPolygon::new(
    [
      Polygon::new([
        [
          @position.Position2D::new((0.0, 0.0)).to_position(),
          @position.Position2D::new((0.0, 1.0)).to_position(),
          @position.Position2D::new((1.0, 0.0)).to_position(),
          @position.Position2D::new((0.0, 0.0)).to_position(),
        ],
      ]),
      Polygon::new([
        [
          @position.Position2D::new((0.0, 0.0)).to_position(),
          @position.Position2D::new((0.0, 1.0)).to_position(),
          @position.Position2D::new((1.0, 0.0)).to_position(),
          @position.Position2D::new((0.0, 0.0)).to_position(),
        ],
      ]),
    ],
    bbox=Some(
      @bbox.BBox2D::new(
        @position.Position2D::new((0.0, 0.0)),
        @position.Position2D::new((1.0, 1.0)),
      ).to_bbox(),
    ),
  )
  @json.inspect(multi_polygon, content={
    "type": "MultiPolygon",
    "bbox": [0, 0, 1, 1],
    "coordinates": [
      [[[0, 0], [0, 1], [1, 0], [0, 0]]],
      [[[0, 0], [0, 1], [1, 0], [0, 0]]],
    ],
  })
}

///|
test "MultiPolygon from_json - simple" {
  let decoded : MultiPolygon = @json.from_json({
    "type": "MultiPolygon",
    "coordinates": [
      [[[10, 20], [30, 40], [50, 60], [10, 20]]],
      [[[70, 80], [90, 100], [110, 120], [70, 80]]],
    ],
  })
  inspect(
    decoded,
    content="{polygons: [{coordinates: [[Position2D({x: 10, y: 20}), Position2D({x: 30, y: 40}), Position2D({x: 50, y: 60}), Position2D({x: 10, y: 20})]], bbox: None}, {coordinates: [[Position2D({x: 70, y: 80}), Position2D({x: 90, y: 100}), Position2D({x: 110, y: 120}), Position2D({x: 70, y: 80})]], bbox: None}], bbox: None}",
  )
}

///|
test "MultiPolygon from_json - with bbox" {
  let decoded : MultiPolygon = @json.from_json({
    "type": "MultiPolygon",
    "coordinates": [
      [[[10, 20], [30, 40], [50, 60], [10, 20]]],
      [[[70, 80], [90, 100], [110, 120], [70, 80]]],
    ],
    "bbox": [10, 20, 110, 120],
  })
  inspect(
    decoded,
    content="{polygons: [{coordinates: [[Position2D({x: 10, y: 20}), Position2D({x: 30, y: 40}), Position2D({x: 50, y: 60}), Position2D({x: 10, y: 20})]], bbox: None}, {coordinates: [[Position2D({x: 70, y: 80}), Position2D({x: 90, y: 100}), Position2D({x: 110, y: 120}), Position2D({x: 70, y: 80})]], bbox: None}], bbox: Some(BBox2D({min: {x: 10, y: 20}, max: {x: 110, y: 120}}))}",
  )
}

///|
test "panic_MultiPolygon from_json - invalid type" {
  let _ : MultiPolygon = @json.from_json({
    "type": "MultiPolygon",
    "geometries": [],
    "bbox": [10, 20, 30, 40],
  })

}

///|
test "MultiPolygon to_bbox - without bbox" {
  let multi_polygon = MultiPolygon::new([
    Polygon::new([
      [
        @position.Position2D::new((0.0, 0.0)).to_position(),
        @position.Position2D::new((0.0, 10.0)).to_position(),
        @position.Position2D::new((10.0, 0.0)).to_position(),
        @position.Position2D::new((0.0, 0.0)).to_position(),
      ],
    ]),
  ])
  let bbox = multi_polygon.to_bbox()
  inspect(bbox, content="BBox2D({min: {x: 0, y: 0}, max: {x: 10, y: 10}})")
}

///|
test "MultiPolygon to_bbox - with bbox (no re-compute)" {
  let custom_bbox = @bbox.BBox2D::new(
    @position.Position2D::new((0.0, 0.0)),
    @position.Position2D::new((0.0, 0.0)),
  ).to_bbox()
  let multi_polygon = MultiPolygon::new(
    [
      Polygon::new([
        [
          @position.Position2D::new((0.0, 0.0)).to_position(),
          @position.Position2D::new((0.0, 10.0)).to_position(),
          @position.Position2D::new((10.0, 0.0)).to_position(),
          @position.Position2D::new((0.0, 0.0)).to_position(),
        ],
      ]),
    ],
    bbox=Some(custom_bbox),
  )
  let result = multi_polygon.to_bbox(re_compute=false)
  inspect(result, content="BBox2D({min: {x: 0, y: 0}, max: {x: 0, y: 0}})")
  assert_eq(result, custom_bbox)
}

///|
test "MultiPolygon to_bbox - with bbox (force re-compute)" {
  let custom_bbox = @bbox.BBox2D::new(
    @position.Position2D::new((0.0, 0.0)),
    @position.Position2D::new((0.0, 0.0)),
  ).to_bbox()
  let multi_polygon = MultiPolygon::new(
    [
      Polygon::new([
        [
          @position.Position2D::new((0.0, 0.0)).to_position(),
          @position.Position2D::new((0.0, 10.0)).to_position(),
          @position.Position2D::new((10.0, 0.0)).to_position(),
          @position.Position2D::new((0.0, 0.0)).to_position(),
        ],
      ]),
    ],
    bbox=Some(custom_bbox),
  )
  let result = multi_polygon.to_bbox(re_compute=true)
  inspect(result, content="BBox2D({min: {x: 0, y: 0}, max: {x: 10, y: 10}})")
  assert_not_eq(result, custom_bbox)
}
