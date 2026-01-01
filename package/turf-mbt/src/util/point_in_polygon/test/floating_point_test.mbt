///|
test "point_in_polygon - floating point on edge" {
  let polygon = @geojson.Polygon::new([
    [
      @geojson.Position2D::new((-115.1752628, 36.0873974)).to_position(),
      @geojson.Position2D::new((-115.1752969, 36.0873974)).to_position(),
      @geojson.Position2D::new((-115.1752969, 36.0874526)).to_position(),
      @geojson.Position2D::new((-115.1752628, 36.0874526)).to_position(),
      @geojson.Position2D::new((-115.1752628, 36.0873974)).to_position(),
    ],
  ])
  let result = @point_in_polygon.point_in_polygon(
    @geojson.Position2D::new((-115.1752799, 36.0874526)),
    polygon,
  )
  inspect(result, content="Boundary")
}

///|
test "point_in_polygon - floating point on other edge" {
  let polygon = @geojson.Polygon::new([
    [
      @geojson.Position2D::new((-115.1752628, 36.0873974)).to_position(),
      @geojson.Position2D::new((-115.1752969, 36.0873974)).to_position(),
      @geojson.Position2D::new((-115.1752969, 36.0874526)).to_position(),
      @geojson.Position2D::new((-115.1752628, 36.0874526)).to_position(),
      @geojson.Position2D::new((-115.1752628, 36.0873974)).to_position(),
    ],
  ])
  let result = @point_in_polygon.point_in_polygon(
    @geojson.Position2D::new((-115.1752799, 36.0873974)),
    polygon,
  )
  inspect(result, content="Boundary")
}

///|
test "point_in_polygon - floating point on tweaked edge" {
  let shiftedPoly = @geojson.Polygon::new([
    [
      @geojson.Position2D::new((-115.1752628, 36.0873974)).to_position(),
      @geojson.Position2D::new((-115.1752969, 36.0873974)).to_position(),
      @geojson.Position2D::new((-115.1752969, 36.0874528)).to_position(),
      @geojson.Position2D::new((-115.1752628, 36.0874528)).to_position(),
      @geojson.Position2D::new((-115.1752628, 36.0873974)).to_position(),
    ],
  ])
  let result = @point_in_polygon.point_in_polygon(
    @geojson.Position2D::new((-115.1752799, 36.0874528)),
    shiftedPoly,
  )
  inspect(result, content="Boundary")
}

///|
test "point_in_polygon - floating point on other tweaked edge" {
  let shiftedPoly = @geojson.Polygon::new([
    [
      @geojson.Position2D::new((-115.1752628, 36.0873974)).to_position(),
      @geojson.Position2D::new((-115.1752969, 36.0873974)).to_position(),
      @geojson.Position2D::new((-115.1752969, 36.0874528)).to_position(),
      @geojson.Position2D::new((-115.1752628, 36.0874528)).to_position(),
      @geojson.Position2D::new((-115.1752628, 36.0873974)).to_position(),
    ],
  ])
  let result = @point_in_polygon.point_in_polygon(
    @geojson.Position2D::new((-115.1752799, 36.0873974)),
    shiftedPoly,
  )
  inspect(result, content="Boundary")
}

///|
test "point_in_polygon - complex case 1" {
  let polygon = @geojson.Polygon::new([
    [
      @geojson.Position2D::new((0.9500000000001119, 0.9500000000001101)).to_position(),
      @geojson.Position2D::new((18.0, 18.0)).to_position(),
      @geojson.Position2D::new((18.0, 0.95)).to_position(),
      @geojson.Position2D::new((0.9500000000001119, 0.9500000000001101)).to_position(),
    ],
  ])
  let result = @point_in_polygon.point_in_polygon(
    @geojson.Position2D::new((16.8, 16.8)),
    polygon,
  )
  inspect(result, content="Outside")
}

///|
test "point_in_polygon - complex case 2" {
  let polygon = @geojson.Polygon::new([
    [
      @geojson.Position2D::new((51.65906944711844, 32.644344469605144)).to_position(),
      @geojson.Position2D::new((51.643474062027934, 32.64597280574026)).to_position(),
      @geojson.Position2D::new((51.6602114368668, 32.658994206590506)).to_position(),
      @geojson.Position2D::new((51.64382208072604, 32.65965256535195)).to_position(),
      @geojson.Position2D::new((51.65906944711844, 32.644344469605144)).to_position(),
    ],
  ])
  let point = (51.6476999685446, 32.65383784687809)
  let result = @point_in_polygon.point_in_polygon(
    @geojson.Position2D::new((point.0, point.1)),
    polygon,
  )
  inspect(result, content="Outside")
}
