// Tests for coords_iter / lines_iter / map_coords.

///|
test "coords_of_point yields one coord" {
  let p = @type.Point::new(1.0, 2.0)
  let coords = coords_of_point(p)
  assert_eq(coords.length(), 1)
  assert_true(coords[0] == @type.Coord::new(1.0, 2.0))
}

///|
test "coords_of_multi_point preserves order" {
  let mp = @type.MultiPoint::from_tuples([
    (-10.0, 0.0),
    (20.0, 20.0),
    (30.0, 40.0),
  ])
  let coords = coords_of_multi_point(mp)
  assert_eq(coords.length(), 3)
  assert_true(coords[0] == @type.Coord::new(-10.0, 0.0))
  assert_true(coords[2] == @type.Coord::new(30.0, 40.0))
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
  let polygon = @type.Polygon::new(exterior, [interior])
  let all_coords = coords_of_polygon(polygon)
  let exterior_coords = exterior_coords_of_polygon(polygon)
  assert_true(all_coords.length() > exterior_coords.length())
  // Exterior alone has 5 coords (auto-closed).
  assert_eq(exterior_coords.length(), 5)
}

///|
test "coords_count via Geometry dispatch" {
  let g = @type.Geometry::Point(@type.Point::new(1.0, 2.0))
  assert_eq(coords_count(g), 1)
  let mp = @type.MultiPoint::from_tuples([(0.0, 0.0), (1.0, 1.0), (2.0, 2.0)])
  let g2 = @type.Geometry::MultiPoint(mp)
  assert_eq(coords_count(g2), 3)
}

///|
test "lines_of_line_string yields n-1 segments" {
  let ls = @type.LineString::from_tuples([(0.0, 0.0), (1.0, 1.0), (2.0, 2.0)])
  let lines = lines_of_line_string(ls)
  assert_eq(lines.length(), 2)
}

///|
test "lines_of_rect yields 4 edges" {
  let r = @type.Rect::new(@type.Coord::new(0.0, 0.0), @type.Coord::new(1.0, 1.0))
  let lines = lines_of_rect(r)
  assert_eq(lines.length(), 4)
}

///|
test "lines_of_geometry returns empty for Point" {
  let g = @type.Geometry::Point(@type.Point::new(1.0, 2.0))
  assert_eq(lines_of_geometry(g).length(), 0)
}

///|
test "map_coords_in_point shifts the coord" {
  let p = @type.Point::new(1.0, 2.0)
  let q = map_coords_in_point(p, fn(c) {
    @type.Coord::new(c.x() + 10.0, c.y() + 20.0)
  })
  assert_true(q == @type.Point::new(11.0, 22.0))
}

///|
test "map_coords_in_polygon transforms all rings" {
  let exterior = @type.LineString::from_tuples([
    (0.0, 0.0),
    (1.0, 0.0),
    (1.0, 1.0),
    (0.0, 1.0),
  ])
  let polygon = @type.Polygon::new(exterior, [])
  let scaled = map_coords_in_polygon(polygon, fn(c) { c.mul(2.0) })
  let scaled_coords = scaled.exterior().coords()
  assert_true(scaled_coords[1] == @type.Coord::new(2.0, 0.0))
  assert_true(scaled_coords[2] == @type.Coord::new(2.0, 2.0))
}

///|
test "map_coords_in_geometry roundtrip with identity" {
  let p = @type.Point::new(3.5, 7.0)
  let g = @type.Geometry::Point(p)
  let g2 = map_coords_in_geometry(g, fn(c) { c })
  match g2 {
    @type.Geometry::Point(p2) => assert_true(p2 == p)
    _ => abort("expected Point variant")
  }
}
