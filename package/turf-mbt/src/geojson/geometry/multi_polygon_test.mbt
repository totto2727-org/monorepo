///|
test "MultiPolygon to JSON" {
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
test "MultiPolygon with BBox to JSON" {
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
test "MultiPolygon from JSON" {
  let decoded : MultiPolygon = @json.from_json({
    "type": "MultiPolygon",
    "coordinates": [
      [[[10, 20], [30, 40], [50, 60], [10, 20]]],
      [[[70, 80], [90, 100], [110, 120], [70, 80]]],
    ],
  })
  inspect(
    decoded,
    content="{polygons: [{coordinates: [[Position2D((10, 20)), Position2D((30, 40)), Position2D((50, 60)), Position2D((10, 20))]], bbox: None}, {coordinates: [[Position2D((70, 80)), Position2D((90, 100)), Position2D((110, 120)), Position2D((70, 80))]], bbox: None}], bbox: None}",
  )
}

///|
test "MultiPolygon with BBox from JSON" {
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
    content="{polygons: [{coordinates: [[Position2D((10, 20)), Position2D((30, 40)), Position2D((50, 60)), Position2D((10, 20))]], bbox: None}, {coordinates: [[Position2D((70, 80)), Position2D((90, 100)), Position2D((110, 120)), Position2D((70, 80))]], bbox: None}], bbox: Some(BBox2D((10, 20, 110, 120)))}",
  )
}

///|
test "panic_MultiPolygon from JSON with invalid type" {
  let _ : MultiPolygon = @json.from_json({
    "type": "MultiPolygon",
    "geometries": [],
    "bbox": [10, 20, 30, 40],
  })

}
