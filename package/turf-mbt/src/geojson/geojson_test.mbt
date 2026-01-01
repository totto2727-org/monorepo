///|
test "GeoJSON to_bbox - Geometry without bbox" {
  let point = Point::new(@position.Position2D::new((0.0, 0.0)).to_position())
  let geojson = GeoJSON::from_geometry(point.to_geometry())
  let bbox = geojson.to_bbox()
  inspect(bbox, content="BBox2D({min: {x: 0, y: 0}, max: {x: 0, y: 0}})")
}

///|
test "GeoJSON to_bbox - Feature with bbox (no re-compute)" {
  let custom_bbox = @bbox.BBox2D::new(
    @position.Position2D::new((0.0, 0.0)),
    @position.Position2D::new((0.0, 0.0)),
  ).to_bbox()
  let feature = Feature::new(
    geometry=Some(
      Point::new(@position.Position2D::new((0.0, 0.0)).to_position()).to_geometry(),
    ),
    bbox=Some(custom_bbox),
  )
  let geojson = feature.to_geojson()
  let result = geojson.to_bbox(re_compute=false)
  inspect(result, content="BBox2D({min: {x: 0, y: 0}, max: {x: 0, y: 0}})")
  assert_eq(result, custom_bbox)
}

///|
test "GeoJSON to_bbox - Feature with bbox (force re-compute)" {
  let custom_bbox = @bbox.BBox2D::new(
    @position.Position2D::new((0.0, 0.0)),
    @position.Position2D::new((0.0, 0.0)),
  ).to_bbox()
  let feature = Feature::new(
    geometry=Some(
      Point::new(@position.Position2D::new((10.0, 10.0)).to_position()).to_geometry(),
    ),
    bbox=Some(custom_bbox),
  )
  let geojson = feature.to_geojson()
  let result = geojson.to_bbox(re_compute=true)
  inspect(result, content="BBox2D({min: {x: 10, y: 10}, max: {x: 10, y: 10}})")
  assert_not_eq(result, custom_bbox)
}

///|
test "GeoJSON from_json - Feature" {
  let json : Json = {
    "type": "Feature",
    "geometry": { "type": "Point", "coordinates": [0, 0] },
    "properties": null,
  }
  let geojson : GeoJSON = @json.from_json(json)
  inspect(
    geojson,
    content="Feature({geometry: Some(Point({coordinates: Position2D({x: 0, y: 0}), bbox: None})), properties: None, id: None, bbox: None})",
  )
}

///|
test "GeoJSON from_json - FeatureCollection" {
  let json : Json = {
    "type": "FeatureCollection",
    "features": [
      {
        "type": "Feature",
        "geometry": { "type": "Point", "coordinates": [0, 0] },
        "properties": null,
      },
    ],
  }
  let geojson : GeoJSON = @json.from_json(json)
  inspect(
    geojson,
    content="FeatureCollection({features: [{geometry: Some(Point({coordinates: Position2D({x: 0, y: 0}), bbox: None})), properties: None, id: None, bbox: None}], bbox: None})",
  )
}

///|
test "GeoJSON from_json - Point" {
  let json : Json = { "type": "Point", "coordinates": [0, 0] }
  let geojson : GeoJSON = @json.from_json(json)
  inspect(
    geojson,
    content="Geometry(Point({coordinates: Position2D({x: 0, y: 0}), bbox: None}))",
  )
}

///|
test "GeoJSON from_json - MultiPoint" {
  let json : Json = { "type": "MultiPoint", "coordinates": [[0, 0], [1, 1]] }
  let geojson : GeoJSON = @json.from_json(json)
  inspect(
    geojson,
    content="Geometry(MultiPoint({points: [{coordinates: Position2D({x: 0, y: 0}), bbox: None}, {coordinates: Position2D({x: 1, y: 1}), bbox: None}], bbox: None}))",
  )
}

///|
test "GeoJSON from_json - LineString" {
  let json : Json = { "type": "LineString", "coordinates": [[0, 0], [1, 1]] }
  let geojson : GeoJSON = @json.from_json(json)
  inspect(
    geojson,
    content="Geometry(LineString({coordinates: [Position2D({x: 0, y: 0}), Position2D({x: 1, y: 1})], bbox: None}))",
  )
}

///|
test "GeoJSON from_json - MultiLineString" {
  let json : Json = {
    "type": "MultiLineString",
    "coordinates": [[[0, 0], [1, 1]], [[2, 2], [3, 3]]],
  }
  let geojson : GeoJSON = @json.from_json(json)
  inspect(
    geojson,
    content="Geometry(MultiLineString({lines: [{coordinates: [Position2D({x: 0, y: 0}), Position2D({x: 1, y: 1})], bbox: None}, {coordinates: [Position2D({x: 2, y: 2}), Position2D({x: 3, y: 3})], bbox: None}], bbox: None}))",
  )
}

///|
test "GeoJSON from_json - Polygon" {
  let json : Json = {
    "type": "Polygon",
    "coordinates": [[[0, 0], [0, 1], [1, 1], [1, 0], [0, 0]]],
  }
  let geojson : GeoJSON = @json.from_json(json)
  inspect(
    geojson,
    content="Geometry(Polygon({coordinates: [[Position2D({x: 0, y: 0}), Position2D({x: 0, y: 1}), Position2D({x: 1, y: 1}), Position2D({x: 1, y: 0}), Position2D({x: 0, y: 0})]], bbox: None}))",
  )
}

///|
test "GeoJSON from_json - MultiPolygon" {
  let json : Json = {
    "type": "MultiPolygon",
    "coordinates": [
      [[[0, 0], [0, 1], [1, 1], [1, 0], [0, 0]]],
      [[[2, 2], [2, 3], [3, 3], [3, 2], [2, 2]]],
    ],
  }
  let geojson : GeoJSON = @json.from_json(json)
  inspect(
    geojson,
    content="Geometry(MultiPolygon({polygons: [{coordinates: [[Position2D({x: 0, y: 0}), Position2D({x: 0, y: 1}), Position2D({x: 1, y: 1}), Position2D({x: 1, y: 0}), Position2D({x: 0, y: 0})]], bbox: None}, {coordinates: [[Position2D({x: 2, y: 2}), Position2D({x: 2, y: 3}), Position2D({x: 3, y: 3}), Position2D({x: 3, y: 2}), Position2D({x: 2, y: 2})]], bbox: None}], bbox: None}))",
  )
}

///|
test "GeoJSON from_json - GeometryCollection" {
  let json : Json = {
    "type": "GeometryCollection",
    "geometries": [
      { "type": "Point", "coordinates": [0, 0] },
      { "type": "LineString", "coordinates": [[0, 0], [1, 1]] },
    ],
  }
  let geojson : GeoJSON = @json.from_json(json)
  inspect(
    geojson,
    content="Geometry(GeometryCollection({geometries: [Point({coordinates: Position2D({x: 0, y: 0}), bbox: None}), LineString({coordinates: [Position2D({x: 0, y: 0}), Position2D({x: 1, y: 1})], bbox: None})], bbox: None}))",
  )
}
