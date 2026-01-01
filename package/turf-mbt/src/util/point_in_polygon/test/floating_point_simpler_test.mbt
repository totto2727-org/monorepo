///|
test "is on bottom edge poly" {
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
test "is on top edge poly" {
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
test "is on left edge poly" {
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
test "is on right edge poly" {
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
test "is just inside left edge" {
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
test "is just outside left edge" {
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
