///|
test "boolean_point_in_polygon - inside simple" {
  let json : Json = {
    "type": "Polygon",
    "coordinates": [
      [[0.0, 0.0], [0.0, 100.0], [100.0, 100.0], [100.0, 0.0], [0.0, 0.0]],
    ],
  }
  let poly : @geojson.Geometry = @json.from_json(json)
  let pt = @geojson.Point::new(
    @geojson.Position2D::new((50.0, 50.0)).to_position(),
  )
  inspect(@turf.boolean_point_in_polygon(pt, poly), content="true")
}

///|
test "boolean_point_in_polygon - outside simple" {
  let json : Json = {
    "type": "Polygon",
    "coordinates": [
      [[0.0, 0.0], [0.0, 100.0], [100.0, 100.0], [100.0, 0.0], [0.0, 0.0]],
    ],
  }
  let poly : @geojson.Geometry = @json.from_json(json)
  let pt = @geojson.Point::new(
    @geojson.Position2D::new((140.0, 150.0)).to_position(),
  )
  inspect(@turf.boolean_point_in_polygon(pt, poly), content="false")
}

///|
test "boolean_point_in_polygon - inside concave" {
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
  let pt = @geojson.Point::new(
    @geojson.Position2D::new((75.0, 75.0)).to_position(),
  )
  inspect(@turf.boolean_point_in_polygon(pt, poly), content="true")
}

///|
test "boolean_point_in_polygon - outside concave" {
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
  let pt = @geojson.Point::new(
    @geojson.Position2D::new((25.0, 50.0)).to_position(),
  )
  inspect(@turf.boolean_point_in_polygon(pt, poly), content="false")
}

///|
test "boolean_point_in_polygon - boundary included" {
  let json : Json = {
    "type": "Polygon",
    "coordinates": [
      [[10.0, 10.0], [30.0, 20.0], [50.0, 10.0], [30.0, 0.0], [10.0, 10.0]],
    ],
  }
  let poly : @geojson.Geometry = @json.from_json(json)
  let pt = @geojson.Point::new(
    @geojson.Position2D::new((10.0, 10.0)).to_position(),
  )
  inspect(@turf.boolean_point_in_polygon(pt, poly), content="true")
}

///|
test "boolean_point_in_polygon - boundary ignored" {
  let json : Json = {
    "type": "Polygon",
    "coordinates": [
      [[10.0, 10.0], [30.0, 20.0], [50.0, 10.0], [30.0, 0.0], [10.0, 10.0]],
    ],
  }
  let poly : @geojson.Geometry = @json.from_json(json)
  let pt = @geojson.Point::new(
    @geojson.Position2D::new((10.0, 10.0)).to_position(),
  )
  inspect(
    @turf.boolean_point_in_polygon(pt, poly, ignore_boundary=true),
    content="false",
  )
}

///|
test "boolean_point_in_polygon - inside hole (outside)" {
  let json : Json = {
    "type": "Polygon",
    "coordinates": [
      [[0.0, 0.0], [0.0, 100.0], [100.0, 100.0], [100.0, 0.0], [0.0, 0.0]],
      [[25.0, 25.0], [25.0, 75.0], [75.0, 75.0], [75.0, 25.0], [25.0, 25.0]],
    ],
  }
  let poly : @geojson.Geometry = @json.from_json(json)
  let pt = @geojson.Point::new(
    @geojson.Position2D::new((10.0, 10.0)).to_position(),
  )
  inspect(@turf.boolean_point_in_polygon(pt, poly), content="true")
}

///|
test "boolean_point_in_polygon - in hole (inside)" {
  let json : Json = {
    "type": "Polygon",
    "coordinates": [
      [[0.0, 0.0], [0.0, 100.0], [100.0, 100.0], [100.0, 0.0], [0.0, 0.0]],
      [[25.0, 25.0], [25.0, 75.0], [75.0, 75.0], [75.0, 25.0], [25.0, 25.0]],
    ],
  }
  let poly : @geojson.Geometry = @json.from_json(json)
  let pt = @geojson.Point::new(
    @geojson.Position2D::new((50.0, 50.0)).to_position(),
  )
  inspect(@turf.boolean_point_in_polygon(pt, poly), content="false")
}

///|
test "boolean_point_in_polygon - multipolygon first" {
  let json : Json = {
    "type": "MultiPolygon",
    "coordinates": [
      [[[0.0, 0.0], [0.0, 10.0], [10.0, 10.0], [10.0, 0.0], [0.0, 0.0]]],
      [[[20.0, 20.0], [20.0, 30.0], [30.0, 30.0], [30.0, 20.0], [20.0, 20.0]]],
    ],
  }
  let poly : @geojson.Geometry = @json.from_json(json)
  let pt = @geojson.Point::new(
    @geojson.Position2D::new((5.0, 5.0)).to_position(),
  )
  inspect(@turf.boolean_point_in_polygon(pt, poly), content="true")
}

///|
test "boolean_point_in_polygon - multipolygon second" {
  let json : Json = {
    "type": "MultiPolygon",
    "coordinates": [
      [[[0.0, 0.0], [0.0, 10.0], [10.0, 10.0], [10.0, 0.0], [0.0, 0.0]]],
      [[[20.0, 20.0], [20.0, 30.0], [30.0, 30.0], [30.0, 20.0], [20.0, 20.0]]],
    ],
  }
  let poly : @geojson.Geometry = @json.from_json(json)
  let pt = @geojson.Point::new(
    @geojson.Position2D::new((25.0, 25.0)).to_position(),
  )
  inspect(@turf.boolean_point_in_polygon(pt, poly), content="true")
}

///|
test "boolean_point_in_polygon - multipolygon with hole" {
  let ptInHole = @geojson.Point::new(
    @geojson.Position2D::new((-86.69208526611328, 36.20373274711739)).to_position(),
  )
  let ptInPoly = @geojson.Point::new(
    @geojson.Position2D::new((-86.72229766845702, 36.20258997094334)).to_position(),
  )
  let ptInPoly2 = @geojson.Point::new(
    @geojson.Position2D::new((-86.75079345703125, 36.18527313913089)).to_position(),
  )
  let ptOutsidePoly = @geojson.Point::new(
    @geojson.Position2D::new((-86.75302505493164, 36.23015046460186)).to_position(),
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
test "boolean_point_in_polygon - issue #15" {
  let pt1 = @geojson.Point::new(
    @geojson.Position2D::new((-9.9964077, 53.8040989)).to_position(),
  )
  let poly : @geojson.Geometry = @geojson.Polygon::new([
    [
      @geojson.Position2D::new((5.080336744095521, 67.89398938540765)).to_position(),
      @geojson.Position2D::new((0.35070899909145403, 69.32470003971179)).to_position(),
      @geojson.Position2D::new((-24.453622256504122, 41.146696777884564)).to_position(),
      @geojson.Position2D::new((-21.6445524714804, 40.43225902006474)).to_position(),
      @geojson.Position2D::new((5.080336744095521, 67.89398938540765)).to_position(),
    ],
  ]).to_geometry()
  inspect(@turf.boolean_point_in_polygon(pt1, poly), content="true")
}

///|
test "boolean_point_in_polygon - boundary test fixtures" {
  let poly1 : @geojson.Geometry = @geojson.Polygon::new([
    [
      @geojson.Position2D::new((10.0, 10.0)).to_position(),
      @geojson.Position2D::new((30.0, 20.0)).to_position(),
      @geojson.Position2D::new((50.0, 10.0)).to_position(),
      @geojson.Position2D::new((30.0, 0.0)).to_position(),
      @geojson.Position2D::new((10.0, 10.0)).to_position(),
    ],
  ]).to_geometry()
  let poly2 : @geojson.Geometry = @geojson.Polygon::new([
    [
      @geojson.Position2D::new((10.0, 0.0)).to_position(),
      @geojson.Position2D::new((30.0, 20.0)).to_position(),
      @geojson.Position2D::new((50.0, 0.0)).to_position(),
      @geojson.Position2D::new((30.0, 10.0)).to_position(),
      @geojson.Position2D::new((10.0, 0.0)).to_position(),
    ],
  ]).to_geometry()
  let poly3 : @geojson.Geometry = @geojson.Polygon::new([
    [
      @geojson.Position2D::new((10.0, 0.0)).to_position(),
      @geojson.Position2D::new((30.0, 20.0)).to_position(),
      @geojson.Position2D::new((50.0, 0.0)).to_position(),
      @geojson.Position2D::new((30.0, -20.0)).to_position(),
      @geojson.Position2D::new((10.0, 0.0)).to_position(),
    ],
  ]).to_geometry()
  let poly4 : @geojson.Geometry = @geojson.Polygon::new([
    [
      @geojson.Position2D::new((0.0, 0.0)).to_position(),
      @geojson.Position2D::new((0.0, 20.0)).to_position(),
      @geojson.Position2D::new((50.0, 20.0)).to_position(),
      @geojson.Position2D::new((50.0, 0.0)).to_position(),
      @geojson.Position2D::new((40.0, 0.0)).to_position(),
      @geojson.Position2D::new((30.0, 10.0)).to_position(),
      @geojson.Position2D::new((30.0, 0.0)).to_position(),
      @geojson.Position2D::new((20.0, 10.0)).to_position(),
      @geojson.Position2D::new((10.0, 10.0)).to_position(),
      @geojson.Position2D::new((10.0, 0.0)).to_position(),
      @geojson.Position2D::new((0.0, 0.0)).to_position(),
    ],
  ]).to_geometry()
  let poly5 : @geojson.Geometry = @geojson.Polygon::new([
    [
      @geojson.Position2D::new((0.0, 20.0)).to_position(),
      @geojson.Position2D::new((20.0, 40.0)).to_position(),
      @geojson.Position2D::new((40.0, 20.0)).to_position(),
      @geojson.Position2D::new((20.0, 0.0)).to_position(),
      @geojson.Position2D::new((0.0, 20.0)).to_position(),
    ],
    [
      @geojson.Position2D::new((10.0, 20.0)).to_position(),
      @geojson.Position2D::new((20.0, 30.0)).to_position(),
      @geojson.Position2D::new((30.0, 20.0)).to_position(),
      @geojson.Position2D::new((20.0, 10.0)).to_position(),
      @geojson.Position2D::new((10.0, 20.0)).to_position(),
    ],
  ]).to_geometry()
  let tests : Array[(@geojson.Geometry, @geojson.Point, Bool)] = [
    (
      poly1,
      @geojson.Point::new(@geojson.Position2D::new((10.0, 10.0)).to_position()),
      true,
    ),
    (
      poly1,
      @geojson.Point::new(@geojson.Position2D::new((30.0, 20.0)).to_position()),
      true,
    ),
    (
      poly1,
      @geojson.Point::new(@geojson.Position2D::new((50.0, 10.0)).to_position()),
      true,
    ),
    (
      poly1,
      @geojson.Point::new(@geojson.Position2D::new((30.0, 10.0)).to_position()),
      true,
    ),
    (
      poly1,
      @geojson.Point::new(@geojson.Position2D::new((0.0, 10.0)).to_position()),
      false,
    ),
    (
      poly1,
      @geojson.Point::new(@geojson.Position2D::new((60.0, 10.0)).to_position()),
      false,
    ),
    (
      poly1,
      @geojson.Point::new(@geojson.Position2D::new((30.0, -10.0)).to_position()),
      false,
    ),
    (
      poly1,
      @geojson.Point::new(@geojson.Position2D::new((30.0, 30.0)).to_position()),
      false,
    ),
    (
      poly2,
      @geojson.Point::new(@geojson.Position2D::new((30.0, 0.0)).to_position()),
      false,
    ),
    (
      poly2,
      @geojson.Point::new(@geojson.Position2D::new((0.0, 0.0)).to_position()),
      false,
    ),
    (
      poly2,
      @geojson.Point::new(@geojson.Position2D::new((60.0, 0.0)).to_position()),
      false,
    ), // 10
    (
      poly3,
      @geojson.Point::new(@geojson.Position2D::new((30.0, 0.0)).to_position()),
      true,
    ),
    (
      poly3,
      @geojson.Point::new(@geojson.Position2D::new((0.0, 0.0)).to_position()),
      false,
    ),
    (
      poly3,
      @geojson.Point::new(@geojson.Position2D::new((60.0, 0.0)).to_position()),
      false,
    ),
    (
      poly4,
      @geojson.Point::new(@geojson.Position2D::new((0.0, 20.0)).to_position()),
      true,
    ),
    (
      poly4,
      @geojson.Point::new(@geojson.Position2D::new((10.0, 20.0)).to_position()),
      true,
    ),
    (
      poly4,
      @geojson.Point::new(@geojson.Position2D::new((50.0, 20.0)).to_position()),
      true,
    ),
    (
      poly4,
      @geojson.Point::new(@geojson.Position2D::new((0.0, 10.0)).to_position()),
      true,
    ),
    (
      poly4,
      @geojson.Point::new(@geojson.Position2D::new((5.0, 10.0)).to_position()),
      true,
    ),
    (
      poly4,
      @geojson.Point::new(@geojson.Position2D::new((25.0, 10.0)).to_position()),
      true,
    ),
    (
      poly4,
      @geojson.Point::new(@geojson.Position2D::new((35.0, 10.0)).to_position()),
      true,
    ), // 20
    (
      poly4,
      @geojson.Point::new(@geojson.Position2D::new((0.0, 0.0)).to_position()),
      true,
    ),
    (
      poly4,
      @geojson.Point::new(@geojson.Position2D::new((10.0, 0.0)).to_position()),
      true,
    ),
    (
      poly4,
      @geojson.Point::new(@geojson.Position2D::new((20.0, 0.0)).to_position()),
      false,
    ),
    (
      poly4,
      @geojson.Point::new(@geojson.Position2D::new((30.0, 0.0)).to_position()),
      true,
    ),
    (
      poly4,
      @geojson.Point::new(@geojson.Position2D::new((40.0, 0.0)).to_position()),
      true,
    ),
    (
      poly4,
      @geojson.Point::new(@geojson.Position2D::new((20.0, 10.0)).to_position()),
      true,
    ),
    (
      poly4,
      @geojson.Point::new(@geojson.Position2D::new((15.0, 10.0)).to_position()),
      true,
    ),
    (
      poly4,
      @geojson.Point::new(@geojson.Position2D::new((20.0, 20.0)).to_position()),
      true,
    ),
    (
      poly4,
      @geojson.Point::new(@geojson.Position2D::new((20.0, 0.0)).to_position()),
      false,
    ),
    (
      poly4,
      @geojson.Point::new(@geojson.Position2D::new((35.0, 0.0)).to_position()),
      false,
    ),
    (
      poly4,
      @geojson.Point::new(@geojson.Position2D::new((50.0, 0.0)).to_position()),
      true,
    ),
    (
      poly4,
      @geojson.Point::new(@geojson.Position2D::new((50.0, 10.0)).to_position()),
      true,
    ),
    (
      poly4,
      @geojson.Point::new(@geojson.Position2D::new((5.0, 0.0)).to_position()),
      true,
    ),
    (
      poly4,
      @geojson.Point::new(@geojson.Position2D::new((10.0, 0.0)).to_position()),
      true,
    ),
    (
      poly5,
      @geojson.Point::new(@geojson.Position2D::new((20.0, 30.0)).to_position()),
      true,
    ),
    (
      poly5,
      @geojson.Point::new(@geojson.Position2D::new((25.0, 25.0)).to_position()),
      true,
    ),
    (
      poly5,
      @geojson.Point::new(@geojson.Position2D::new((30.0, 20.0)).to_position()),
      true,
    ),
    (
      poly5,
      @geojson.Point::new(@geojson.Position2D::new((25.0, 15.0)).to_position()),
      true,
    ),
    (
      poly5,
      @geojson.Point::new(@geojson.Position2D::new((20.0, 10.0)).to_position()),
      true,
    ),
    (
      poly5,
      @geojson.Point::new(@geojson.Position2D::new((15.0, 15.0)).to_position()),
      true,
    ),
    (
      poly5,
      @geojson.Point::new(@geojson.Position2D::new((10.0, 20.0)).to_position()),
      true,
    ),
    (
      poly5,
      @geojson.Point::new(@geojson.Position2D::new((15.0, 25.0)).to_position()),
      true,
    ),
    (
      poly5,
      @geojson.Point::new(@geojson.Position2D::new((20.0, 20.0)).to_position()),
      false,
    ),
  ]
  for _, test_case in tests {
    let (poly, pt, expected) = test_case
    assert_eq(
      @turf.boolean_point_in_polygon(pt, poly, ignore_boundary=false),
      expected,
    )
  }
}

///|
test "boolean_point_in_polygon - poly with hole fixture" {
  let ptInHole = @geojson.Point::new(
    @geojson.Position2D::new((-86.69208526611328, 36.20373274711739)).to_position(),
  )
  let ptInPoly = @geojson.Point::new(
    @geojson.Position2D::new((-86.72229766845702, 36.20258997094334)).to_position(),
  )
  let ptOutsidePoly = @geojson.Point::new(
    @geojson.Position2D::new((-86.75079345703125, 36.18527313913089)).to_position(),
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
