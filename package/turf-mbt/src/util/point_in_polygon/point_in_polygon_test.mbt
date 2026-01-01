///|
test "point_in_polygon - inside" {
  let polygon = @geojson.Polygon::new([
    [
      @geojson.Position2D::new((1.0, 1.0)).to_position(),
      @geojson.Position2D::new((1.0, 2.0)).to_position(),
      @geojson.Position2D::new((2.0, 2.0)).to_position(),
      @geojson.Position2D::new((2.0, 1.0)).to_position(),
      @geojson.Position2D::new((1.0, 1.0)).to_position(),
    ],
  ])
  let result = @point_in_polygon.point_in_polygon(
    @geojson.Position2D::new((1.5, 1.5)),
    polygon,
  )
  inspect(result, content="Inside")
}

///|
test "point_in_polygon - boundary" {
  let polygon = @geojson.Polygon::new([
    [
      @geojson.Position2D::new((1.0, 1.0)).to_position(),
      @geojson.Position2D::new((1.0, 2.0)).to_position(),
      @geojson.Position2D::new((2.0, 2.0)).to_position(),
      @geojson.Position2D::new((2.0, 1.0)).to_position(),
      @geojson.Position2D::new((1.0, 1.0)).to_position(),
    ],
  ])
  let result = @point_in_polygon.point_in_polygon(
    @geojson.Position2D::new((1.0, 1.5)),
    polygon,
  )
  inspect(result, content="Boundary")
}

///|
test "point_in_polygon - outside" {
  let polygon = @geojson.Polygon::new([
    [
      @geojson.Position2D::new((1.0, 1.0)).to_position(),
      @geojson.Position2D::new((1.0, 2.0)).to_position(),
      @geojson.Position2D::new((2.0, 2.0)).to_position(),
      @geojson.Position2D::new((2.0, 1.0)).to_position(),
      @geojson.Position2D::new((1.0, 1.0)).to_position(),
    ],
  ])
  let result = @point_in_polygon.point_in_polygon(
    @geojson.Position2D::new((3.0, 3.0)),
    polygon,
  )
  inspect(result, content="Outside")
}

///|
test "point_in_polygon - integer coords boundary" {
  let polygon = @geojson.Polygon::new([
    [
      @geojson.Position2D::new((1.0, 1.0)).to_position(),
      @geojson.Position2D::new((1.0, 2.0)).to_position(),
      @geojson.Position2D::new((2.0, 2.0)).to_position(),
      @geojson.Position2D::new((2.0, 1.0)).to_position(),
      @geojson.Position2D::new((1.0, 1.0)).to_position(),
    ],
  ])
  let result = @point_in_polygon.point_in_polygon(
    @geojson.Position2D::new((1.0, 1.0)),
    polygon,
  )
  inspect(result, content="Boundary")
}

///|
test "point_in_polygon - integer coords outside 1" {
  let polygon = @geojson.Polygon::new([
    [
      @geojson.Position2D::new((1.0, 1.0)).to_position(),
      @geojson.Position2D::new((1.0, 2.0)).to_position(),
      @geojson.Position2D::new((2.0, 2.0)).to_position(),
      @geojson.Position2D::new((2.0, 1.0)).to_position(),
      @geojson.Position2D::new((1.0, 1.0)).to_position(),
    ],
  ])
  let result = @point_in_polygon.point_in_polygon(
    @geojson.Position2D::new((1.0, 0.0)),
    polygon,
  )
  inspect(result, content="Outside")
}

///|
test "point_in_polygon - integer coords outside 2" {
  let polygon = @geojson.Polygon::new([
    [
      @geojson.Position2D::new((1.0, 1.0)).to_position(),
      @geojson.Position2D::new((1.0, 2.0)).to_position(),
      @geojson.Position2D::new((2.0, 2.0)).to_position(),
      @geojson.Position2D::new((2.0, 1.0)).to_position(),
      @geojson.Position2D::new((1.0, 1.0)).to_position(),
    ],
  ])
  let result = @point_in_polygon.point_in_polygon(
    @geojson.Position2D::new((0.0, 1.0)),
    polygon,
  )
  inspect(result, content="Outside")
}

///|
test "point_in_polygon - integer coords outside 3" {
  let polygon = @geojson.Polygon::new([
    [
      @geojson.Position2D::new((1.0, 1.0)).to_position(),
      @geojson.Position2D::new((1.0, 2.0)).to_position(),
      @geojson.Position2D::new((2.0, 2.0)).to_position(),
      @geojson.Position2D::new((2.0, 1.0)).to_position(),
      @geojson.Position2D::new((1.0, 1.0)).to_position(),
    ],
  ])
  let result = @point_in_polygon.point_in_polygon(
    @geojson.Position2D::new((-0.5, -0.5)),
    polygon,
  )
  inspect(result, content="Outside")
}

///|
test "point_in_polygon - integer coords outside 4" {
  let polygon = @geojson.Polygon::new([
    [
      @geojson.Position2D::new((1.0, 1.0)).to_position(),
      @geojson.Position2D::new((1.0, 2.0)).to_position(),
      @geojson.Position2D::new((2.0, 2.0)).to_position(),
      @geojson.Position2D::new((2.0, 1.0)).to_position(),
      @geojson.Position2D::new((1.0, 1.0)).to_position(),
    ],
  ])
  let result = @point_in_polygon.point_in_polygon(
    @geojson.Position2D::new((0.5, -0.5)),
    polygon,
  )
  inspect(result, content="Outside")
}

///|
test "point_in_polygon - wrapped around" {
  let polygon = @geojson.Polygon::new([
    [
      @geojson.Position2D::new((-180.0, -90.0)).to_position(),
      @geojson.Position2D::new((-180.0, 90.0)).to_position(),
      @geojson.Position2D::new((180.0, 90.0)).to_position(),
      @geojson.Position2D::new((180.0, -90.0)).to_position(),
      @geojson.Position2D::new((-180.0, -90.0)).to_position(),
    ],
  ])
  let result = @point_in_polygon.point_in_polygon(
    @geojson.Position2D::new((140.43, 70.43)),
    polygon,
  )
  inspect(result, content="Inside")
}
