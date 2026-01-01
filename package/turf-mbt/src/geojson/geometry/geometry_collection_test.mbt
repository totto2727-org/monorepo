///|
test "GeometryCollection to JSON" {
  let geometry_collection = GeometryCollection::new([
    Point::new(@position.Position2D::new((0.0, 0.0)).to_position()).to_geometry(),
    LineString::new([
      @position.Position2D::new((0.0, 0.0)).to_position(),
      @position.Position2D::new((1.0, 1.0)).to_position(),
    ]).to_geometry(),
  ])
  @json.inspect(geometry_collection, content={
    "type": "GeometryCollection",
    "geometries": [
      { "type": "Point", "coordinates": [0, 0] },
      { "type": "LineString", "coordinates": [[0, 0], [1, 1]] },
    ],
  })
}

///|
test "GeometryCollection with BBox to JSON" {
  let geometry_collection = GeometryCollection::new(
    [
      Point::new(@position.Position2D::new((0.0, 0.0)).to_position()).to_geometry(),
      LineString::new([
        @position.Position2D::new((0.0, 0.0)).to_position(),
        @position.Position2D::new((1.0, 1.0)).to_position(),
      ]).to_geometry(),
    ],
    bbox=Some(
      @bbox.BBox2D::new(
        @position.Position2D::new((0.0, 0.0)),
        @position.Position2D::new((1.0, 1.0)),
      ).to_bbox(),
    ),
  )
  @json.inspect(geometry_collection, content={
    "type": "GeometryCollection",
    "bbox": [0, 0, 1, 1],
    "geometries": [
      { "type": "Point", "coordinates": [0, 0] },
      { "type": "LineString", "coordinates": [[0, 0], [1, 1]] },
    ],
  })
}

///|
test "GeometryCollection from JSON" {
  let decoded : GeometryCollection = @json.from_json({
    "type": "GeometryCollection",
    "geometries": [
      { "type": "Point", "coordinates": [10, 20] },
      { "type": "LineString", "coordinates": [[10, 20], [30, 40]] },
    ],
  })
  inspect(
    decoded,
    content="{geometries: [Point({coordinates: Position2D((10, 20)), bbox: None}), LineString({coordinates: [Position2D((10, 20)), Position2D((30, 40))], bbox: None})], bbox: None}",
  )
}

///|
test "GeometryCollection with BBox from JSON" {
  let decoded : GeometryCollection = @json.from_json({
    "type": "GeometryCollection",
    "geometries": [
      { "type": "Point", "coordinates": [10, 20] },
      { "type": "LineString", "coordinates": [[10, 20], [30, 40]] },
    ],
    "bbox": [10, 20, 30, 40],
  })
  inspect(
    decoded,
    content="{geometries: [Point({coordinates: Position2D((10, 20)), bbox: None}), LineString({coordinates: [Position2D((10, 20)), Position2D((30, 40))], bbox: None})], bbox: Some(BBox2D((10, 20, 30, 40)))}",
  )
}

///|
test "panic_GeometryCollection from JSON with invalid type" {
  let _ : GeometryCollection = @json.from_json({
    "type": "GeometryCollection",
    "coordinates": [],
    "bbox": [10, 20, 30, 40],
  })

}
