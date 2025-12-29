///|
test "FeatureCollection(all non-null) to JSON" {
  let featureCollection = FeatureCollection::new(
    [Feature::new(geometry=Some(Geometry::point(Position::new2D(0, 0))))],
    bbox=Some(BBox::new2D((0, 0, 1, 1))),
  )
  @json.inspect(featureCollection, content={
    "type": "FeatureCollection",
    "features": [
      {
        "type": "Feature",
        "geometry": { "type": "Point", "coordinates": [0, 0] },
        "properties": null,
      },
    ],
    "bbox": [0, 0, 1, 1],
  })
}

///|
test "FeatureCollection(all empty) to JSON" {
  let featureCollection = FeatureCollection::new([])
  @json.inspect(featureCollection, content={
    "type": "FeatureCollection",
    "features": [],
  })
}

///|
test "FeatureCollection(all non-null) from JSON" {
  let json : Json = {
    "type": "FeatureCollection",
    "features": [
      {
        "type": "Feature",
        "geometry": { "type": "Point", "coordinates": [0, 0] },
        "properties": {},
      },
    ],
    "bbox": [0, 0, 1, 1],
  }
  let featureCollection : FeatureCollection = @json.from_json(json)
  inspect(
    featureCollection,
    content="{features: [{geometry: Some(Point(coordinates=Position2D(0, 0), bbox=None)), properties: Some({}), id: None, bbox: None}], bbox: Some(BBox2D(0, 0, 1, 1))}",
  )
}

///|
test "FeatureCollection(all empty) from JSON" {
  let json : Json = { "type": "FeatureCollection", "features": [] }
  let featureCollection : FeatureCollection = @json.from_json(json)
  inspect(featureCollection, content="{features: [], bbox: None}")
}
