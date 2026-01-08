///|
test "point_in_polygon - floating simple bottom edge" {
  let polygon = @geojson.Polygon::new([
    [
      @geojson.Position2D::new((1.111111111111, 1.111111111111)).to_position(),
      @geojson.Position2D::new((1.111111111111, 2.111111111111)).to_position(),
      @geojson.Position2D::new((2.111111111111, 2.111111111111)).to_position(),
      @geojson.Position2D::new((2.111111111111, 1.111111111111)).to_position(),
      @geojson.Position2D::new((1.111111111111, 1.111111111111)).to_position(),
    ],
  ])
  let result = @point_in_polygon.point_in_polygon(
    @geojson.Position2D::new((1.511111111111, 1.111111111111)),
    polygon,
  )
  inspect(result, content="Boundary")
}

///|
test "point_in_polygon - floating simple top edge" {
  let polygon = @geojson.Polygon::new([
    [
      @geojson.Position2D::new((1.111111111111, 1.111111111111)).to_position(),
      @geojson.Position2D::new((1.111111111111, 2.111111111111)).to_position(),
      @geojson.Position2D::new((2.111111111111, 2.111111111111)).to_position(),
      @geojson.Position2D::new((2.111111111111, 1.111111111111)).to_position(),
      @geojson.Position2D::new((1.111111111111, 1.111111111111)).to_position(),
    ],
  ])
  let result = @point_in_polygon.point_in_polygon(
    @geojson.Position2D::new((1.511111111111, 2.111111111111)),
    polygon,
  )
  inspect(result, content="Boundary")
}

///|
test "point_in_polygon - floating simple left edge" {
  let polygon = @geojson.Polygon::new([
    [
      @geojson.Position2D::new((1.111111111111, 1.111111111111)).to_position(),
      @geojson.Position2D::new((1.111111111111, 2.111111111111)).to_position(),
      @geojson.Position2D::new((2.111111111111, 2.111111111111)).to_position(),
      @geojson.Position2D::new((2.111111111111, 1.111111111111)).to_position(),
      @geojson.Position2D::new((1.111111111111, 1.111111111111)).to_position(),
    ],
  ])
  let result = @point_in_polygon.point_in_polygon(
    @geojson.Position2D::new((1.111111111111, 1.511111111111)),
    polygon,
  )
  inspect(result, content="Boundary")
}

///|
test "point_in_polygon - floating simple right edge" {
  let polygon = @geojson.Polygon::new([
    [
      @geojson.Position2D::new((1.111111111111, 1.111111111111)).to_position(),
      @geojson.Position2D::new((1.111111111111, 2.111111111111)).to_position(),
      @geojson.Position2D::new((2.111111111111, 2.111111111111)).to_position(),
      @geojson.Position2D::new((2.111111111111, 1.111111111111)).to_position(),
      @geojson.Position2D::new((1.111111111111, 1.111111111111)).to_position(),
    ],
  ])
  let result = @point_in_polygon.point_in_polygon(
    @geojson.Position2D::new((2.111111111111, 1.511111111111)),
    polygon,
  )
  inspect(result, content="Boundary")
}

///|
test "point_in_polygon - floating simple just inside left" {
  let polygon = @geojson.Polygon::new([
    [
      @geojson.Position2D::new((1.111111111111, 1.111111111111)).to_position(),
      @geojson.Position2D::new((1.111111111111, 2.111111111111)).to_position(),
      @geojson.Position2D::new((2.111111111111, 2.111111111111)).to_position(),
      @geojson.Position2D::new((2.111111111111, 1.111111111111)).to_position(),
      @geojson.Position2D::new((1.111111111111, 1.111111111111)).to_position(),
    ],
  ])
  let result = @point_in_polygon.point_in_polygon(
    @geojson.Position2D::new((1.1111111111111, 1.511111111111)),
    polygon,
  )
  inspect(result, content="Inside")
}

///|
test "point_in_polygon - floating simple just outside left" {
  let polygon = @geojson.Polygon::new([
    [
      @geojson.Position2D::new((1.111111111111, 1.111111111111)).to_position(),
      @geojson.Position2D::new((1.111111111111, 2.111111111111)).to_position(),
      @geojson.Position2D::new((2.111111111111, 2.111111111111)).to_position(),
      @geojson.Position2D::new((2.111111111111, 1.111111111111)).to_position(),
      @geojson.Position2D::new((1.111111111111, 1.111111111111)).to_position(),
    ],
  ])
  let result = @point_in_polygon.point_in_polygon(
    @geojson.Position2D::new((1.111111111110, 1.511111111111)),
    polygon,
  )
  inspect(result, content="Outside")
}
