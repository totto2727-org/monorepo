///|
test "FeatureCollection to_json - all non-null" {
  let featureCollection = FeatureCollection::new(
    [
      Feature::new(
        geometry=Some(
          @geometry.Point::new(@position.Position2D::new((0, 0)).to_position()).to_geometry(),
        ),
      ),
    ],
    bbox=Some(
      @bbox.BBox2D::new(
        @position.Position2D::new((0, 0)),
        @position.Position2D::new((1, 1)),
      ).to_bbox(),
    ),
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
test "FeatureCollection to_json - all empty" {
  let featureCollection = FeatureCollection::new([])
  @json.inspect(featureCollection, content={
    "type": "FeatureCollection",
    "features": [],
  })
}

///|
test "FeatureCollection from_json - all non-null" {
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
    content="{features: [{geometry: Some(Point({coordinates: Position2D({x: 0, y: 0}), bbox: None})), properties: Some({}), id: None, bbox: None}], bbox: Some(BBox2D({min: {x: 0, y: 0}, max: {x: 1, y: 1}}))}",
  )
}

///|
test "FeatureCollection from_json - all empty" {
  let json : Json = { "type": "FeatureCollection", "features": [] }
  let featureCollection : FeatureCollection = @json.from_json(json)
  inspect(featureCollection, content="{features: [], bbox: None}")
}

///|
test "FeatureCollection to_bbox - without bbox" {
  let featureCollection = FeatureCollection::new([
    Feature::new(
      geometry=Some(
        @geometry.Point::new(@position.Position2D::new((0, 0)).to_position()).to_geometry(),
      ),
    ),
    Feature::new(
      geometry=Some(
        @geometry.Point::new(@position.Position2D::new((10, 10)).to_position()).to_geometry(),
      ),
    ),
  ])
  let bbox = featureCollection.to_bbox()
  inspect(bbox, content="BBox2D({min: {x: 0, y: 0}, max: {x: 10, y: 10}})")
}

///|
test "FeatureCollection to_bbox - with bbox (no re-compute)" {
  let custom_bbox = @bbox.BBox2D::new(
    @position.Position2D::new((0.0, 0.0)),
    @position.Position2D::new((0.0, 0.0)),
  ).to_bbox()
  let featureCollection = FeatureCollection::new(
    [
      Feature::new(
        geometry=Some(
          @geometry.Point::new(@position.Position2D::new((0, 0)).to_position()).to_geometry(),
        ),
      ),
      Feature::new(
        geometry=Some(
          @geometry.Point::new(
            @position.Position2D::new((10, 10)).to_position(),
          ).to_geometry(),
        ),
      ),
    ],
    bbox=Some(custom_bbox),
  )
  let result = featureCollection.to_bbox(re_compute=false)
  inspect(result, content="BBox2D({min: {x: 0, y: 0}, max: {x: 0, y: 0}})")
  assert_eq(result, custom_bbox)
}

///|
test "FeatureCollection to_bbox - with bbox (force re-compute)" {
  let custom_bbox = @bbox.BBox2D::new(
    @position.Position2D::new((0.0, 0.0)),
    @position.Position2D::new((0.0, 0.0)),
  ).to_bbox()
  let featureCollection = FeatureCollection::new(
    [
      Feature::new(
        geometry=Some(
          @geometry.Point::new(@position.Position2D::new((0, 0)).to_position()).to_geometry(),
        ),
      ),
      Feature::new(
        geometry=Some(
          @geometry.Point::new(
            @position.Position2D::new((10, 10)).to_position(),
          ).to_geometry(),
        ),
      ),
    ],
    bbox=Some(custom_bbox),
  )
  let result = featureCollection.to_bbox(re_compute=true)
  inspect(result, content="BBox2D({min: {x: 0, y: 0}, max: {x: 10, y: 10}})")
  assert_not_eq(result, custom_bbox)
}
