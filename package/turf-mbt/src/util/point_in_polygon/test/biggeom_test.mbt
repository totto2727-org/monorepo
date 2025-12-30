///|
test "is inside Switzerland" {
  let json_string = @fs.read_file_to_string(
    "src/util/point_in_polygon/test/fixtures/switzerland.geojson",
  )
  let json = @json.parse(json_string)
  let feature : @geojson.Feature = @json.from_json(json)
  let coordinates = match feature.geometry {
    Some(@geojson.Geometry::Polygon(coordinates~, ..)) => coordinates
    _ => abort("Expected Polygon Feature")
  }
  let result = @point_in_polygon.point_in_polygon(
    8.0,
    46.5,
    coordinates
    |> Array::map(x => x.map(y => match y {
      Position2D(x, y) => (x, y)
      Position3D(x, y, _) => (x, y)
    })),
  )
  inspect(result, content="Inside")
}

///|
test "is outside Switzerland" {
  let json_string = @fs.read_file_to_string(
    "src/util/point_in_polygon/test/fixtures/switzerland.geojson",
  )
  let json = @json.parse(json_string)
  let feature : @geojson.Feature = @json.from_json(json)
  let coordinates = match feature.geometry {
    Some(@geojson.Geometry::Polygon(coordinates~, ..)) => coordinates
    _ => abort("Expected Polygon Feature")
  }
  let result = @point_in_polygon.point_in_polygon(
    8.0,
    44.0,
    coordinates
    |> Array::map(x => x.map(y => match y {
      Position2D(x, y) => (x, y)
      Position3D(x, y, _) => (x, y)
    })),
  )
  inspect(result, content="Outside")
}

///|
test "is inside kinked Switzerland" {
  let json_string = @fs.read_file_to_string(
    "src/util/point_in_polygon/test/fixtures/switzerlandKinked.geojson",
  )
  let json = @json.parse(json_string)
  let feature : @geojson.Feature = @json.from_json(json)
  let coordinates = match feature.geometry {
    Some(@geojson.Geometry::Polygon(coordinates~, ..)) => coordinates
    _ => abort("Expected Polygon Feature")
  }
  let result = @point_in_polygon.point_in_polygon(
    8.0,
    46.5,
    coordinates
    |> Array::map(x => x.map(y => match y {
      Position2D(x, y) => (x, y)
      Position3D(x, y, _) => (x, y)
    })),
  )
  inspect(result, content="Inside")
}

///|
test "is outside kinked Switzerland" {
  let json_string = @fs.read_file_to_string(
    "src/util/point_in_polygon/test/fixtures/switzerlandKinked.geojson",
  )
  let json = @json.parse(json_string)
  let feature : @geojson.Feature = @json.from_json(json)
  let coordinates = match feature.geometry {
    Some(@geojson.Geometry::Polygon(coordinates~, ..)) => coordinates
    _ => abort("Expected Polygon Feature")
  }
  let result = @point_in_polygon.point_in_polygon(
    8.0,
    44.0,
    coordinates
    |> Array::map(x => x.map(y => match y {
      Position2D(x, y) => (x, y)
      Position3D(x, y, _) => (x, y)
    })),
  )
  inspect(result, content="Outside")
}
