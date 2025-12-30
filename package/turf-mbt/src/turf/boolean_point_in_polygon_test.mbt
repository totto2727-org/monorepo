///|
test "point inside simple polygon" {
  let json : Json = {
    "type": "Polygon",
    "coordinates": [
      [[0.0, 0.0], [0.0, 100.0], [100.0, 100.0], [100.0, 0.0], [0.0, 0.0]],
    ],
  }
  let poly : @geojson.Geometry = @json.from_json(json)
  let pt = @geojson.Position::new2D(50.0, 50.0)
  inspect(@turf.boolean_point_in_polygon(pt, poly), content="true")
}

///|
test "point outside simple polygon" {
  let json : Json = {
    "type": "Polygon",
    "coordinates": [
      [[0.0, 0.0], [0.0, 100.0], [100.0, 100.0], [100.0, 0.0], [0.0, 0.0]],
    ],
  }
  let poly : @geojson.Geometry = @json.from_json(json)
  let pt = @geojson.Position::new2D(140.0, 150.0)
  inspect(@turf.boolean_point_in_polygon(pt, poly), content="false")
}

///|
test "point inside concave polygon" {
  let json : Json = {
    "type": "Polygon",
    "coordinates": [
      [
        [0.0, 0.0],
        [50.0, 50.0],
        [0.0, 100.0],
        [100.0, 100.0],
        [100.0, 0.0],
        [0.0, 0.0],
      ],
    ],
  }
  let poly : @geojson.Geometry = @json.from_json(json)
  let pt = @geojson.Position::new2D(75.0, 75.0)
  inspect(@turf.boolean_point_in_polygon(pt, poly), content="true")
}

///|
test "point outside concave polygon" {
  let json : Json = {
    "type": "Polygon",
    "coordinates": [
      [
        [0.0, 0.0],
        [50.0, 50.0],
        [0.0, 100.0],
        [100.0, 100.0],
        [100.0, 0.0],
        [0.0, 0.0],
      ],
    ],
  }
  let poly : @geojson.Geometry = @json.from_json(json)
  let pt = @geojson.Position::new2D(25.0, 50.0)
  inspect(@turf.boolean_point_in_polygon(pt, poly), content="false")
}

///|
test "point on boundary - default (included)" {
  let json : Json = {
    "type": "Polygon",
    "coordinates": [
      [[10.0, 10.0], [30.0, 20.0], [50.0, 10.0], [30.0, 0.0], [10.0, 10.0]],
    ],
  }
  let poly : @geojson.Geometry = @json.from_json(json)
  let pt = @geojson.Position::new2D(10.0, 10.0)
  inspect(@turf.boolean_point_in_polygon(pt, poly), content="true")
}

///|
test "point on boundary - ignored" {
  let json : Json = {
    "type": "Polygon",
    "coordinates": [
      [[10.0, 10.0], [30.0, 20.0], [50.0, 10.0], [30.0, 0.0], [10.0, 10.0]],
    ],
  }
  let poly : @geojson.Geometry = @json.from_json(json)
  let pt = @geojson.Position::new2D(10.0, 10.0)
  inspect(
    @turf.boolean_point_in_polygon(pt, poly, ignore_boundary=true),
    content="false",
  )
}

///|
test "point in polygon with hole - outside hole" {
  let json : Json = {
    "type": "Polygon",
    "coordinates": [
      [[0.0, 0.0], [0.0, 100.0], [100.0, 100.0], [100.0, 0.0], [0.0, 0.0]],
      [[25.0, 25.0], [25.0, 75.0], [75.0, 75.0], [75.0, 25.0], [25.0, 25.0]],
    ],
  }
  let poly : @geojson.Geometry = @json.from_json(json)
  let pt = @geojson.Position::new2D(10.0, 10.0)
  inspect(@turf.boolean_point_in_polygon(pt, poly), content="true")
}

///|
test "point in polygon with hole - inside hole" {
  let json : Json = {
    "type": "Polygon",
    "coordinates": [
      [[0.0, 0.0], [0.0, 100.0], [100.0, 100.0], [100.0, 0.0], [0.0, 0.0]],
      [[25.0, 25.0], [25.0, 75.0], [75.0, 75.0], [75.0, 25.0], [25.0, 25.0]],
    ],
  }
  let poly : @geojson.Geometry = @json.from_json(json)
  let pt = @geojson.Position::new2D(50.0, 50.0)
  inspect(@turf.boolean_point_in_polygon(pt, poly), content="false")
}

///|
test "point in multipolygon - first polygon" {
  let json : Json = {
    "type": "MultiPolygon",
    "coordinates": [
      [[[0.0, 0.0], [0.0, 10.0], [10.0, 10.0], [10.0, 0.0], [0.0, 0.0]]],
      [[[20.0, 20.0], [20.0, 30.0], [30.0, 30.0], [30.0, 20.0], [20.0, 20.0]]],
    ],
  }
  let poly : @geojson.Geometry = @json.from_json(json)
  let pt = @geojson.Position::new2D(5.0, 5.0)
  inspect(@turf.boolean_point_in_polygon(pt, poly), content="true")
}

///|
test "point in multipolygon - second polygon" {
  let json : Json = {
    "type": "MultiPolygon",
    "coordinates": [
      [[[0.0, 0.0], [0.0, 10.0], [10.0, 10.0], [10.0, 0.0], [0.0, 0.0]]],
      [[[20.0, 20.0], [20.0, 30.0], [30.0, 30.0], [30.0, 20.0], [20.0, 20.0]]],
    ],
  }
  let poly : @geojson.Geometry = @json.from_json(json)
  let pt = @geojson.Position::new2D(25.0, 25.0)
  inspect(@turf.boolean_point_in_polygon(pt, poly), content="true")
}

///|
test "point in multipolygon with hole" {
  let ptInHole = @geojson.Position::new2D(-86.69208526611328, 36.20373274711739)
  let ptInPoly = @geojson.Position::new2D(-86.72229766845702, 36.20258997094334)
  let ptInPoly2 = @geojson.Position::new2D(
    -86.75079345703125, 36.18527313913089,
  )
  let ptOutsidePoly = @geojson.Position::new2D(
    -86.75302505493164, 36.23015046460186,
  )
  let json_string = @fs.read_file_to_string(
    "src/turf/test/fixtures/multipoly-with-hole.geojson",
  )
  let json = @json.parse(json_string)
  let feature : @geojson.Feature = @json.from_json(json)
  let multiPolyHole = feature.geometry.unwrap()
  inspect(
    @turf.boolean_point_in_polygon(ptInHole, multiPolyHole),
    content="false",
  )
  inspect(
    @turf.boolean_point_in_polygon(ptInPoly, multiPolyHole),
    content="true",
  )
  inspect(
    @turf.boolean_point_in_polygon(ptInPoly2, multiPolyHole),
    content="true",
  )
  inspect(
    @turf.boolean_point_in_polygon(ptOutsidePoly, multiPolyHole),
    content="false",
  )
}

///|
test "boolean-point-in-polygon -- issue #15" {
  let pt1 = @geojson.Position::new2D(-9.9964077, 53.8040989)
  let poly : @geojson.Geometry = @geojson.Geometry::polygon([
    [
      @geojson.Position::new2D(5.080336744095521, 67.89398938540765),
      @geojson.Position::new2D(0.35070899909145403, 69.32470003971179),
      @geojson.Position::new2D(-24.453622256504122, 41.146696777884564),
      @geojson.Position::new2D(-21.6445524714804, 40.43225902006474),
      @geojson.Position::new2D(5.080336744095521, 67.89398938540765),
    ],
  ])
  inspect(@turf.boolean_point_in_polygon(pt1, poly), content="true")
}

///|
test "boolean-point-in-polygon -- Boundary test" {
  let poly1 : @geojson.Geometry = @geojson.Geometry::polygon([
    [
      @geojson.Position::new2D(10.0, 10.0),
      @geojson.Position::new2D(30.0, 20.0),
      @geojson.Position::new2D(50.0, 10.0),
      @geojson.Position::new2D(30.0, 0.0),
      @geojson.Position::new2D(10.0, 10.0),
    ],
  ])
  let poly2 : @geojson.Geometry = @geojson.Geometry::polygon([
    [
      @geojson.Position::new2D(10.0, 0.0),
      @geojson.Position::new2D(30.0, 20.0),
      @geojson.Position::new2D(50.0, 0.0),
      @geojson.Position::new2D(30.0, 10.0),
      @geojson.Position::new2D(10.0, 0.0),
    ],
  ])
  let poly3 : @geojson.Geometry = @geojson.Geometry::polygon([
    [
      @geojson.Position::new2D(10.0, 0.0),
      @geojson.Position::new2D(30.0, 20.0),
      @geojson.Position::new2D(50.0, 0.0),
      @geojson.Position::new2D(30.0, -20.0),
      @geojson.Position::new2D(10.0, 0.0),
    ],
  ])
  let poly4 : @geojson.Geometry = @geojson.Geometry::polygon([
    [
      @geojson.Position::new2D(0.0, 0.0),
      @geojson.Position::new2D(0.0, 20.0),
      @geojson.Position::new2D(50.0, 20.0),
      @geojson.Position::new2D(50.0, 0.0),
      @geojson.Position::new2D(40.0, 0.0),
      @geojson.Position::new2D(30.0, 10.0),
      @geojson.Position::new2D(30.0, 0.0),
      @geojson.Position::new2D(20.0, 10.0),
      @geojson.Position::new2D(10.0, 10.0),
      @geojson.Position::new2D(10.0, 0.0),
      @geojson.Position::new2D(0.0, 0.0),
    ],
  ])
  let poly5 : @geojson.Geometry = @geojson.Geometry::polygon([
    [
      @geojson.Position::new2D(0.0, 20.0),
      @geojson.Position::new2D(20.0, 40.0),
      @geojson.Position::new2D(40.0, 20.0),
      @geojson.Position::new2D(20.0, 0.0),
      @geojson.Position::new2D(0.0, 20.0),
    ],
    [
      @geojson.Position::new2D(10.0, 20.0),
      @geojson.Position::new2D(20.0, 30.0),
      @geojson.Position::new2D(30.0, 20.0),
      @geojson.Position::new2D(20.0, 10.0),
      @geojson.Position::new2D(10.0, 20.0),
    ],
  ])
  let tests = [
    (poly1, @geojson.Position::new2D(10.0, 10.0), true), // 0
    (poly1, @geojson.Position::new2D(30.0, 20.0), true),
    (poly1, @geojson.Position::new2D(50.0, 10.0), true),
    (poly1, @geojson.Position::new2D(30.0, 10.0), true),
    (poly1, @geojson.Position::new2D(0.0, 10.0), false),
    (poly1, @geojson.Position::new2D(60.0, 10.0), false),
    (poly1, @geojson.Position::new2D(30.0, -10.0), false),
    (poly1, @geojson.Position::new2D(30.0, 30.0), false),
    (poly2, @geojson.Position::new2D(30.0, 0.0), false),
    (poly2, @geojson.Position::new2D(0.0, 0.0), false),
    (poly2, @geojson.Position::new2D(60.0, 0.0), false), // 10
    (poly3, @geojson.Position::new2D(30.0, 0.0), true),
    (poly3, @geojson.Position::new2D(0.0, 0.0), false),
    (poly3, @geojson.Position::new2D(60.0, 0.0), false),
    (poly4, @geojson.Position::new2D(0.0, 20.0), true),
    (poly4, @geojson.Position::new2D(10.0, 20.0), true),
    (poly4, @geojson.Position::new2D(50.0, 20.0), true),
    (poly4, @geojson.Position::new2D(0.0, 10.0), true),
    (poly4, @geojson.Position::new2D(5.0, 10.0), true),
    (poly4, @geojson.Position::new2D(25.0, 10.0), true),
    (poly4, @geojson.Position::new2D(35.0, 10.0), true), // 20
    (poly4, @geojson.Position::new2D(0.0, 0.0), true),
    (poly4, @geojson.Position::new2D(10.0, 0.0), true),
    (poly4, @geojson.Position::new2D(20.0, 0.0), false),
    (poly4, @geojson.Position::new2D(30.0, 0.0), true),
    (poly4, @geojson.Position::new2D(40.0, 0.0), true),
    (poly4, @geojson.Position::new2D(20.0, 10.0), true), // 26
    (poly4, @geojson.Position::new2D(15.0, 10.0), true),
    (poly4, @geojson.Position::new2D(20.0, 20.0), true),
    (poly4, @geojson.Position::new2D(20.0, 0.0), false),
    (poly4, @geojson.Position::new2D(35.0, 0.0), false),
    (poly4, @geojson.Position::new2D(50.0, 0.0), true),
    (poly4, @geojson.Position::new2D(50.0, 10.0), true),
    (poly4, @geojson.Position::new2D(5.0, 0.0), true),
    (poly4, @geojson.Position::new2D(10.0, 0.0), true),
    (poly5, @geojson.Position::new2D(20.0, 30.0), true), // 35
    (poly5, @geojson.Position::new2D(25.0, 25.0), true),
    (poly5, @geojson.Position::new2D(30.0, 20.0), true),
    (poly5, @geojson.Position::new2D(25.0, 15.0), true),
    (poly5, @geojson.Position::new2D(20.0, 10.0), true),
    (poly5, @geojson.Position::new2D(15.0, 15.0), true),
    (poly5, @geojson.Position::new2D(10.0, 20.0), true),
    (poly5, @geojson.Position::new2D(15.0, 25.0), true),
    (poly5, @geojson.Position::new2D(20.0, 20.0), false), // 43
  ]
  for _, test_case in tests {
    let (poly, pt, is_boundary_or_inside) = test_case
    let expected = if is_boundary_or_inside { "true" } else { "false" }
    inspect(
      @turf.boolean_point_in_polygon(pt, poly, ignore_boundary=false),
      content=expected,
    )
  }
}

///|
test "boolean-point-in-polygon -- poly with hole (fixture)" {
  let ptInHole = @geojson.Position::new2D(-86.69208526611328, 36.20373274711739)
  let ptInPoly = @geojson.Position::new2D(-86.72229766845702, 36.20258997094334)
  let ptOutsidePoly = @geojson.Position::new2D(
    -86.75079345703125, 36.18527313913089,
  )
  let json_string = @fs.read_file_to_string(
    "src/turf/test/fixtures/poly-with-hole.geojson",
  )
  let json = @json.parse(json_string)
  let feature : @geojson.Feature = @json.from_json(json)
  let polyHole = feature.geometry.unwrap()
  inspect(@turf.boolean_point_in_polygon(ptInHole, polyHole), content="false")
  inspect(@turf.boolean_point_in_polygon(ptInPoly, polyHole), content="true")
  inspect(
    @turf.boolean_point_in_polygon(ptOutsidePoly, polyHole),
    content="false",
  )
}
