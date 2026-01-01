///|
test "Point in Polygon" {
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
test "Point on Boundary" {
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
test "Point Outside" {
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
test "Point with Integer Coords" {
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
test "Point with Integer Coords #2" {
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
test "Point with Integer Coords #3" {
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
test "Point with Integer Coords #4" {
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
test "Point with Integer Coords #5" {
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
test "Point wrapped around" {
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
