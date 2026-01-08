///|
test "GeometryCollection to_json - simple" {
  let geometry_collection = GeometryCollection::new([
    Point::new(Position2D::new((0.0, 0.0)).to_position()).to_geometry(),
    LineString::new([
      Position2D::new((0.0, 0.0)).to_position(),
      Position2D::new((1.0, 1.0)).to_position(),
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
test "GeometryCollection to_json - with bbox" {
  let geometry_collection = GeometryCollection::new(
    [
      Point::new(Position2D::new((0.0, 0.0)).to_position()).to_geometry(),
      LineString::new([
        Position2D::new((0.0, 0.0)).to_position(),
        Position2D::new((1.0, 1.0)).to_position(),
      ]).to_geometry(),
    ],
    bbox=Some(
      BBox2D::new(Position2D::new((0.0, 0.0)), Position2D::new((1.0, 1.0))).to_bbox(),
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
test "GeometryCollection from_json - simple" {
  let decoded : GeometryCollection = @json.from_json({
    "type": "GeometryCollection",
    "geometries": [
      { "type": "Point", "coordinates": [10, 20] },
      { "type": "LineString", "coordinates": [[10, 20], [30, 40]] },
    ],
  })
  inspect(
    decoded,
    content="{geometries: [Point({coordinates: Position2D({x: 10, y: 20}), bbox: None}), LineString({coordinates: [Position2D({x: 10, y: 20}), Position2D({x: 30, y: 40})], bbox: None})], bbox: None}",
  )
}

///|
test "GeometryCollection from_json - with bbox" {
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
    content="{geometries: [Point({coordinates: Position2D({x: 10, y: 20}), bbox: None}), LineString({coordinates: [Position2D({x: 10, y: 20}), Position2D({x: 30, y: 40})], bbox: None})], bbox: Some(BBox2D({min: {x: 10, y: 20}, max: {x: 30, y: 40}}))}",
  )
}

///|
test "panic_GeometryCollection from_json - invalid type" {
  let _ : GeometryCollection = @json.from_json({
    "type": "GeometryCollection",
    "coordinates": [],
    "bbox": [10, 20, 30, 40],
  })

}

///|
test "GeometryCollection to_bbox - without bbox" {
  let geometry_collection = GeometryCollection::new([
    Point::new(Position2D::new((0.0, 0.0)).to_position()).to_geometry(),
    Point::new(Position2D::new((10.0, 10.0)).to_position()).to_geometry(),
  ])
  let bbox = geometry_collection.to_bbox()
  inspect(bbox, content="BBox2D({min: {x: 0, y: 0}, max: {x: 10, y: 10}})")
}

///|
test "GeometryCollection to_bbox - with bbox (no re-compute)" {
  let custom_bbox = BBox2D::new(
    Position2D::new((0.0, 0.0)),
    Position2D::new((0.0, 0.0)),
  ).to_bbox()
  let geometry_collection = GeometryCollection::new(
    [
      Point::new(Position2D::new((0.0, 0.0)).to_position()).to_geometry(),
      Point::new(Position2D::new((10.0, 10.0)).to_position()).to_geometry(),
    ],
    bbox=Some(custom_bbox),
  )
  let result = geometry_collection.to_bbox(re_compute=false)
  inspect(result, content="BBox2D({min: {x: 0, y: 0}, max: {x: 0, y: 0}})")
  assert_eq(result, custom_bbox)
}

///|
test "GeometryCollection to_bbox - with bbox (force re-compute)" {
  let custom_bbox = BBox2D::new(
    Position2D::new((0.0, 0.0)),
    Position2D::new((0.0, 0.0)),
  ).to_bbox()
  let geometry_collection = GeometryCollection::new(
    [
      Point::new(Position2D::new((0.0, 0.0)).to_position()).to_geometry(),
      Point::new(Position2D::new((10.0, 10.0)).to_position()).to_geometry(),
    ],
    bbox=Some(custom_bbox),
  )
  let result = geometry_collection.to_bbox(re_compute=true)
  inspect(result, content="BBox2D({min: {x: 0, y: 0}, max: {x: 10, y: 10}})")
  assert_not_eq(result, custom_bbox)
}
