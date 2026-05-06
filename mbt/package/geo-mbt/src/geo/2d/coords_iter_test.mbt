// Tests for coords_iter.mbt.

///|
test "coords_of_point yields one coord" {
  let p = @type.Point::Point(1.0, 2.0)
  let coords = CoordsCarrier::coords(p)
  assert_eq(coords.length(), 1)
  assert_true(coords[0] == @type.Coord(1.0, 2.0))
}

///|
test "coords_of_multi_point preserves order" {
  let mp = @type.MultiPoint::from_tuples([
    (-10.0, 0.0),
    (20.0, 20.0),
    (30.0, 40.0),
  ])
  let coords = CoordsCarrier::coords(mp)
  assert_eq(coords.length(), 3)
  assert_true(coords[0] == @type.Coord(-10.0, 0.0))
  assert_true(coords[2] == @type.Coord(30.0, 40.0))
}

///|
test "coords_of_polygon walks exterior then interiors" {
  let exterior = @type.LineString::from_tuples([
    (0.0, 0.0),
    (10.0, 0.0),
    (10.0, 10.0),
    (0.0, 10.0),
  ])
  let interior = @type.LineString::from_tuples([
    (3.0, 3.0),
    (7.0, 3.0),
    (7.0, 7.0),
    (3.0, 7.0),
  ])
  let polygon = @type.Polygon::Polygon(exterior, [interior])
  let all_coords = CoordsCarrier::coords(polygon)
  let exterior_coords = ExteriorCoordsCarrier::exterior_coords(polygon)
  assert_true(all_coords.length() > exterior_coords.length())
  // Exterior alone has 5 coords (auto-closed).
  assert_eq(exterior_coords.length(), 5)
}

///|
test "coords_count via Geometry dispatch" {
  let g = @type.Geometry::Point(@type.Point::Point(1.0, 2.0))
  assert_eq(coords_count(g), 1)
  let mp = @type.MultiPoint::from_tuples([(0.0, 0.0), (1.0, 1.0), (2.0, 2.0)])
  let g2 = @type.Geometry::MultiPoint(mp)
  assert_eq(coords_count(g2), 3)
}
