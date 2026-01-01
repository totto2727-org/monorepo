///|
test "Geometry from_json - Point" {
  let geometry : Geometry = @json.from_json({
    "type": "Point",
    "coordinates": [10, 20],
  })
  inspect(geometry.to_geojson_object()._type, content="Geometry(Point)")
}

///|
test "Geometry from_json - MultiPoint" {
  let geometry : Geometry = @json.from_json({
    "type": "MultiPoint",
    "coordinates": [[10, 20], [30, 40]],
  })
  inspect(geometry.to_geojson_object()._type, content="Geometry(MultiPoint)")
}

///|
test "Geometry from_json - LineString" {
  let geometry : Geometry = @json.from_json({
    "type": "LineString",
    "coordinates": [[10, 20], [30, 40]],
  })
  inspect(geometry.to_geojson_object()._type, content="Geometry(LineString)")
}

///|
test "Geometry from_json - MultiLineString" {
  let geometry : Geometry = @json.from_json({
    "type": "MultiLineString",
    "coordinates": [[[10, 20], [30, 40]], [[50, 60], [70, 80]]],
  })
  inspect(
    geometry.to_geojson_object()._type,
    content="Geometry(MultiLineString)",
  )
}

///|
test "Geometry from_json - Polygon" {
  let geometry : Geometry = @json.from_json({
    "type": "Polygon",
    "coordinates": [[[10, 20], [30, 40], [50, 60], [10, 20]]],
  })
  inspect(geometry.to_geojson_object()._type, content="Geometry(Polygon)")
}

///|
test "Geometry from_json - MultiPolygon" {
  let geometry : Geometry = @json.from_json({
    "type": "MultiPolygon",
    "coordinates": [
      [[[10, 20], [30, 40], [50, 60], [10, 20]]],
      [[[70, 80], [90, 100], [110, 120], [70, 80]]],
    ],
  })
  inspect(geometry.to_geojson_object()._type, content="Geometry(MultiPolygon)")
}

///|
test "Geometry from_json - GeometryCollection" {
  let geometry : Geometry = @json.from_json({
    "type": "GeometryCollection",
    "geometries": [
      { "type": "Point", "coordinates": [10, 20] },
      { "type": "LineString", "coordinates": [[10, 20], [30, 40]] },
    ],
  })
  inspect(
    geometry.to_geojson_object()._type,
    content="Geometry(GeometryCollection)",
  )
}
