// Tests for the `MapCoords` trait (defined in traits.mbt; this file covers
// per-type behaviour of `map_coords`).

///|
test "MapCoords on Point shifts the coord" {
  let p = @type.Point::Point(1.0, 2.0)
  let q = MapCoords::map_coords(p, fn(c) {
    @type.Coord(c.x() + 10.0, c.y() + 20.0)
  })
  assert_true(q == @type.Point::Point(11.0, 22.0))
}

///|
test "MapCoords on Polygon transforms all rings" {
  let exterior = @type.LineString::from_tuples([
    (0.0, 0.0),
    (1.0, 0.0),
    (1.0, 1.0),
    (0.0, 1.0),
  ])
  let polygon = @type.Polygon::Polygon(exterior, [])
  let scaled = MapCoords::map_coords(polygon, fn(c) { c.mul(2.0) })
  let scaled_coords = scaled.exterior().coords()
  assert_true(scaled_coords[1] == @type.Coord(2.0, 0.0))
  assert_true(scaled_coords[2] == @type.Coord(2.0, 2.0))
}

///|
test "MapCoords on Geometry roundtrip with identity" {
  let p = @type.Point::Point(3.5, 7.0)
  let g = @type.Geometry::Point(p)
  let g2 = MapCoords::map_coords(g, fn(c) { c })
  match g2 {
    @type.Geometry::Point(p2) => assert_true(p2 == p)
    _ => abort("expected Point variant")
  }
}
