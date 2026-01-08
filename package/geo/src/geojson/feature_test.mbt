///|
test "Feature to_json - all non-null" {
  let feature = Feature::new(
    geometry=Some(
      Point::new(Position2D::new((0, 0)).to_position()).to_geometry(),
    ),
    properties=Some({ "key": "value" }),
    id=Some(FeatureID::string("f1")),
    bbox=Some(
      BBox2D::new(Position2D::new((0, 0)), Position2D::new((1, 1))).to_bbox(),
    ),
  )
  @json.inspect(feature, content={
    "type": "Feature",
    "bbox": [0, 0, 1, 1],
    "geometry": { "type": "Point", "coordinates": [0, 0] },
    "properties": { "key": "value" },
    "id": "f1",
  })
}

///|
test "Feature to_json - all null" {
  let feature = Feature::new()
  @json.inspect(feature, content={
    "type": "Feature",
    "geometry": null,
    "properties": null,
  })
}

///|
test "Feature from_json - all non-null" {
  let json : Json = {
    "type": "Feature",
    "geometry": { "type": "Point", "coordinates": [0, 1] },
    "properties": { "name": "test" },
    "id": "f1",
    "bbox": [0, 0, 1, 1],
  }
  let feature : Feature = @json.from_json(json)
  inspect(
    feature,
    content=(
      #|{geometry: Some(Point({coordinates: Position2D({x: 0, y: 1}), bbox: None})), properties: Some({"name": String("test")}), id: Some(StringID("f1")), bbox: Some(BBox2D({min: {x: 0, y: 0}, max: {x: 1, y: 1}}))}
    ),
  )
}

///|
test "Feature from_json - all null" {
  let json : Json = { "type": "Feature", "geometry": null, "properties": null }
  let feature : Feature = @json.from_json(json)
  inspect(
    feature,
    content="{geometry: None, properties: None, id: None, bbox: None}",
  )
}

///|
test "Feature to_bbox - without bbox" {
  let feature = Feature::new(
    geometry=Some(
      Point::new(Position2D::new((0, 0)).to_position()).to_geometry(),
    ),
  )
  let bbox = feature.to_bbox()
  inspect(bbox, content="BBox2D({min: {x: 0, y: 0}, max: {x: 0, y: 0}})")
}

///|
test "Feature to_bbox - with bbox (no re-compute)" {
  let custom_bbox = BBox2D::new(
    Position2D::new((0.0, 0.0)),
    Position2D::new((0.0, 0.0)),
  ).to_bbox()
  let feature = Feature::new(
    geometry=Some(
      Point::new(Position2D::new((0, 0)).to_position()).to_geometry(),
    ),
    bbox=Some(custom_bbox),
  )
  let result = feature.to_bbox(re_compute=false)
  inspect(result, content="BBox2D({min: {x: 0, y: 0}, max: {x: 0, y: 0}})")
  assert_eq(result, custom_bbox)
}

///|
test "Feature to_bbox - with bbox (force re-compute)" {
  let custom_bbox = BBox2D::new(
    Position2D::new((0.0, 0.0)),
    Position2D::new((0.0, 0.0)),
  ).to_bbox()
  let feature = Feature::new(
    geometry=Some(
      Point::new(Position2D::new((10.0, 10.0)).to_position()).to_geometry(),
    ),
    bbox=Some(custom_bbox),
  )
  let result = feature.to_bbox(re_compute=true)
  inspect(result, content="BBox2D({min: {x: 10, y: 10}, max: {x: 10, y: 10}})")
  assert_not_eq(result, custom_bbox)
}
