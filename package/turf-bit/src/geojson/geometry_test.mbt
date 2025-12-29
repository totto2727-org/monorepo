// to_json

///|
test "Geometry Point to JSON" {
  let p1 = Position::new2D(0.0, 0.0)
  let point = Geometry::point(p1)
  @json.inspect(point, content={ "type": "Point", "coordinates": [0, 0] })
}

///|
test "Geometry MultiPoint to JSON" {
  let p1 = Position::new2D(0.0, 0.0)
  let p2 = Position::new2D(1.0, 1.0)
  let multi_point = Geometry::multi_point([p1, p2])
  @json.inspect(multi_point, content={
    "type": "MultiPoint",
    "coordinates": [[0, 0], [1, 1]],
  })
}

///|
test "Geometry LineString to JSON" {
  let p1 = Position::new2D(0.0, 0.0)
  let p2 = Position::new2D(1.0, 1.0)
  let line_string = Geometry::line_string([p1, p2])
  @json.inspect(line_string, content={
    "type": "LineString",
    "coordinates": [[0, 0], [1, 1]],
  })
}

///|
test "Geometry MultiLineString to JSON" {
  let p1 = Position::new2D(0.0, 0.0)
  let p2 = Position::new2D(1.0, 1.0)
  let multi_line_string = Geometry::multi_line_string([[p1, p2], [p2, p1]])
  @json.inspect(multi_line_string, content={
    "type": "MultiLineString",
    "coordinates": [[[0, 0], [1, 1]], [[1, 1], [0, 0]]],
  })
}

///|
test "Geometry Polygon to JSON" {
  let p1 = Position::new2D(0.0, 0.0)
  let p2 = Position::new2D(1.0, 1.0)
  let polygon = Geometry::polygon([[p1, p2, p2, p1]])
  @json.inspect(polygon, content={
    "type": "Polygon",
    "coordinates": [[[0, 0], [1, 1], [1, 1], [0, 0]]],
  })
}

///|
test "Geometry MultiPolygon to JSON" {
  let p1 = Position::new2D(0.0, 0.0)
  let p2 = Position::new2D(1.0, 1.0)
  let multi_polygon = Geometry::multi_polygon([[[p1, p2, p2, p1]]])
  @json.inspect(multi_polygon, content={
    "type": "MultiPolygon",
    "coordinates": [[[[0, 0], [1, 1], [1, 1], [0, 0]]]],
  })
}

///|
test "Geometry GeometryCollection to JSON" {
  let p1 = Position::new2D(0.0, 0.0)
  let p2 = Position::new2D(1.0, 1.0)
  let point = Geometry::point(p1)
  let line_string = Geometry::line_string([p1, p2])
  let geometry_collection = Geometry::geometry_collection([point, line_string])
  @json.inspect(geometry_collection, content={
    "type": "GeometryCollection",
    "geometries": [
      { "type": "Point", "coordinates": [0, 0] },
      { "type": "LineString", "coordinates": [[0, 0], [1, 1]] },
    ],
  })
}

///|
test "Geometry Point with BBox to JSON" {
  let p = Position::new2D(10.0, 20.0)
  let bbox = BBox::new2D((10.0, 20.0, 10.0, 20.0))
  let point = Geometry::point(p, bbox=Some(bbox))
  @json.inspect(point, content={
    "type": "Point",
    "bbox": [10, 20, 10, 20],
    "coordinates": [10, 20],
  })
}

// from_json

///|
test "Point from Json" {
  let decoded : Geometry = @json.from_json({
    "type": "Point",
    "coordinates": [10, 20],
    "bbox": [10, 20, 10, 20],
  })
  inspect(
    decoded,
    content="Point(coordinates=Position2D(10, 20), bbox=Some(BBox2D(10, 20, 10, 20)))",
  )
}

///|
test "MultiPoint from Json" {
  let decoded : Geometry = @json.from_json({
    "type": "MultiPoint",
    "coordinates": [[10, 20], [30, 40]],
    "bbox": [10, 20, 30, 40],
  })
  inspect(
    decoded,
    content="MultiPoint(coordinates=[Position2D(10, 20), Position2D(30, 40)], bbox=Some(BBox2D(10, 20, 30, 40)))",
  )
}

///|
test "LineString from Json" {
  let decoded : Geometry = @json.from_json({
    "type": "LineString",
    "coordinates": [[10, 20], [30, 40]],
    "bbox": [10, 20, 30, 40],
  })
  inspect(
    decoded,
    content="LineString(coordinates=[Position2D(10, 20), Position2D(30, 40)], bbox=Some(BBox2D(10, 20, 30, 40)))",
  )
}

///|
test "MultiLineString from Json" {
  let decoded : Geometry = @json.from_json({
    "type": "MultiLineString",
    "coordinates": [[[10, 20], [30, 40]], [[50, 60], [70, 80]]],
    "bbox": [10, 20, 70, 80],
  })
  inspect(
    decoded,
    content="MultiLineString(coordinates=[[Position2D(10, 20), Position2D(30, 40)], [Position2D(50, 60), Position2D(70, 80)]], bbox=Some(BBox2D(10, 20, 70, 80)))",
  )
}

///|
test "Polygon from Json" {
  let decoded : Geometry = @json.from_json({
    "type": "Polygon",
    "coordinates": [[[10, 20], [30, 40], [50, 60], [10, 20]]],
    "bbox": [10, 20, 50, 60],
  })
  inspect(
    decoded,
    content="Polygon(coordinates=[[Position2D(10, 20), Position2D(30, 40), Position2D(50, 60), Position2D(10, 20)]], bbox=Some(BBox2D(10, 20, 50, 60)))",
  )
}

///|
test "MultiPolygon from Json" {
  let decoded : Geometry = @json.from_json({
    "type": "MultiPolygon",
    "coordinates": [
      [[[10, 20], [30, 40], [50, 60], [10, 20]]],
      [[[70, 80], [90, 100], [110, 120], [70, 80]]],
    ],
    "bbox": [10, 20, 110, 120],
  })
  inspect(
    decoded,
    content="MultiPolygon(coordinates=[[[Position2D(10, 20), Position2D(30, 40), Position2D(50, 60), Position2D(10, 20)]], [[Position2D(70, 80), Position2D(90, 100), Position2D(110, 120), Position2D(70, 80)]]], bbox=Some(BBox2D(10, 20, 110, 120)))",
  )
}

///|
test "GeometryCollection from Json" {
  let decoded : Geometry = @json.from_json({
    "type": "GeometryCollection",
    "geometries": [
      { "type": "Point", "coordinates": [10, 20] },
      { "type": "LineString", "coordinates": [[10, 20], [30, 40]] },
    ],
    "bbox": [10, 20, 30, 40],
  })
  inspect(
    decoded,
    content="GeometryCollection(geometries=[Point(coordinates=Position2D(10, 20), bbox=None), LineString(coordinates=[Position2D(10, 20), Position2D(30, 40)], bbox=None)], bbox=Some(BBox2D(10, 20, 30, 40)))",
  )
}

///|
test "Geometry(without BBox) from Json" {
  let decoded : Geometry = @json.from_json({
    "type": "Point",
    "coordinates": [10, 20],
  })
  inspect(decoded, content="Point(coordinates=Position2D(10, 20), bbox=None)")
}

///|
test "panic_GeometryCollection from Json with invalid type" {
  let _ : Geometry = @json.from_json({
    "type": "Point",
    "geometries": [
      { "type": "Point", "coordinates": [10, 20] },
      { "type": "LineString", "coordinates": [[10, 20], [30, 40]] },
    ],
    "bbox": [10, 20, 30, 40],
  })

}

// to_geojson_geometry_types

///|
test "Geometry Point to Geometry Types" {
  let p1 = Position::new2D(0.0, 0.0)
  let point = Geometry::point(p1)
  inspect(point.to_geojson_geometry_types(), content="Point")
}

///|
test "Geometry MultiPoint to Geometry Types" {
  let p1 = Position::new2D(0.0, 0.0)
  let p2 = Position::new2D(1.0, 1.0)
  let multi_point = Geometry::multi_point([p1, p2])
  inspect(multi_point.to_geojson_geometry_types(), content="MultiPoint")
}

///|
test "Geometry LineString to Geometry Types" {
  let p1 = Position::new2D(0.0, 0.0)
  let p2 = Position::new2D(1.0, 1.0)
  let line_string = Geometry::line_string([p1, p2])
  inspect(line_string.to_geojson_geometry_types(), content="LineString")
}

///|
test "Geometry MultiLineString to Geometry Types" {
  let p1 = Position::new2D(0.0, 0.0)
  let p2 = Position::new2D(1.0, 1.0)
  let multi_line_string = Geometry::multi_line_string([[p1, p2], [p2, p1]])
  inspect(
    multi_line_string.to_geojson_geometry_types(),
    content="MultiLineString",
  )
}

///|
test "Geometry Polygon to Geometry Types" {
  let p1 = Position::new2D(0.0, 0.0)
  let p2 = Position::new2D(1.0, 1.0)
  let polygon = Geometry::polygon([[p1, p2, p2, p1]])
  inspect(polygon.to_geojson_geometry_types(), content="Polygon")
}

///|
test "Geometry MultiPolygon to Geometry Types" {
  let p1 = Position::new2D(0.0, 0.0)
  let p2 = Position::new2D(1.0, 1.0)
  let multi_polygon = Geometry::multi_polygon([[[p1, p2, p2, p1]]])
  inspect(multi_polygon.to_geojson_geometry_types(), content="MultiPolygon")
}

///|
test "Geometry GeometryCollection to Geometry Types" {
  let p1 = Position::new2D(0.0, 0.0)
  let p2 = Position::new2D(1.0, 1.0)
  let point = Geometry::point(p1)
  let line_string = Geometry::line_string([p1, p2])
  let geometry_collection = Geometry::geometry_collection([point, line_string])
  inspect(
    geometry_collection.to_geojson_geometry_types(),
    content="GeometryCollection",
  )
}

// to_geojson_types

///|
test "Geometry to GeoJsonTypes" {
  let p = Position::new2D(0.0, 0.0)
  let point = Geometry::point(p)
  inspect(point.to_geojson_types(), content="Geometry(Point)")
}

// get_bbox

///|
test "Geometry to BBox(Some)" {
  let p = Position::new2D(0.0, 0.0)
  let bbox = BBox::new2D((0.0, 0.0, 1.0, 1.0))
  let point_with_bbox = Geometry::point(p, bbox=Some(bbox))
  inspect(point_with_bbox.get_bbox(), content="Some(BBox2D(0, 0, 1, 1))")
}

///|
test "Geometry to BBox(None)" {
  let p = Position::new2D(0.0, 0.0)
  let point = Geometry::point(p)
  inspect(point.get_bbox(), content="None")
}

// to_geojson_object

///|
test "Geometry to GeoJsonObject" {
  let p = Position::new2D(0.0, 0.0)
  let point = Geometry::point(p)
  let obj = point.to_geojson_object()
  inspect(obj, content="{_type: Geometry(Point), bbox: None}")
}

///|
test "panic_Polygon from Json with too few positions" {
  let _ : Geometry = @json.from_json({
    "type": "Polygon",
    "coordinates": [[[0, 0], [1, 1], [0, 0]]],
  })

}

///|
test "panic_Polygon from Json with non-equivalent first/last" {
  let _ : Geometry = @json.from_json({
    "type": "Polygon",
    "coordinates": [[[0, 0], [1, 1], [2, 2], [3, 3]]],
  })

}

///|
test "Geometry::polygon with too few positions fails" {
  let p1 = Position::new2D(0.0, 0.0)
  try {
    let _ = Geometry::polygon([[p1, p1, p1]])
    fail("Should have failed")
  } catch {
    _ as e =>
      inspect(
        e,
        content="GeoJsonError(\"Each LinearRing of a Polygon must have 4 or more Positions.\")",
      )
  }
}
