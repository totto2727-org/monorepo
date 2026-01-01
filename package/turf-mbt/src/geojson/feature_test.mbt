///|
test "Feature(all non-null) to JSON" {
  let feature = Feature::new(
    geometry=Some(
      @geometry.Point::new(@position.Position2D::new((0, 0)).to_position()).to_geometry(),
    ),
    properties=Some({ "key": "value" }),
    id=Some(FeatureID::string("f1")),
    bbox=Some(
      @bbox.BBox2D::new(
        @position.Position2D::new((0, 0)),
        @position.Position2D::new((1, 1)),
      ).to_bbox(),
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
test "Feature(all null) to JSON" {
  let feature = Feature::new()
  @json.inspect(feature, content={
    "type": "Feature",
    "geometry": null,
    "properties": null,
  })
}

///|
test "Feature(all non-null) from JSON" {
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
      #|{geometry: Some(Point({coordinates: Position2D((0, 1)), bbox: None})), properties: Some({"name": String("test")}), id: Some(StringID("f1")), bbox: Some(BBox2D((0, 0, 1, 1)))}
    ),
  )
}

///|
test "Feature(all null) from JSON" {
  let json : Json = { "type": "Feature", "geometry": null, "properties": null }
  let feature : Feature = @json.from_json(json)
  inspect(
    feature,
    content="{geometry: None, properties: None, id: None, bbox: None}",
  )
}
