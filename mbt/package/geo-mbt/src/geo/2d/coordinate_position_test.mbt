// Tests for coordinate_position.mbt.

///|
fn coord_position_test_polygon() -> @type.Polygon {
  let exterior = @type.LineString::from_tuples([
    (0.0, 0.0),
    (2.0, 0.0),
    (2.0, 2.0),
    (0.0, 2.0),
    (0.0, 0.0),
  ])
  @type.Polygon::Polygon(exterior, [])
}

///|
test "coord_position polygon: inside" {
  let p = coord_position_test_polygon()
  assert_true(
    coord_position_for_polygon(@type.Coord(1.0, 1.0), p) == CoordPos::Inside,
  )
}

///|
test "coord_position polygon: boundary" {
  let p = coord_position_test_polygon()
  assert_true(
    coord_position_for_polygon(@type.Coord(0.0, 1.0), p) == CoordPos::OnBoundary,
  )
}

///|
test "coord_position polygon: outside" {
  let p = coord_position_test_polygon()
  assert_true(
    coord_position_for_polygon(@type.Coord(5.0, 5.0), p) == CoordPos::Outside,
  )
}

///|
test "coord_position polygon with hole: inside hole" {
  let exterior = @type.LineString::from_tuples([
    (0.0, 0.0),
    (10.0, 0.0),
    (10.0, 10.0),
    (0.0, 10.0),
    (0.0, 0.0),
  ])
  let interior = @type.LineString::from_tuples([
    (3.0, 3.0),
    (7.0, 3.0),
    (7.0, 7.0),
    (3.0, 7.0),
    (3.0, 3.0),
  ])
  let p = @type.Polygon::Polygon(exterior, [interior])
  // Inside hole = Outside polygon
  assert_true(
    coord_position_for_polygon(@type.Coord(5.0, 5.0), p) == CoordPos::Outside,
  )
  // On hole boundary = OnBoundary
  assert_true(
    coord_position_for_polygon(@type.Coord(3.0, 5.0), p) == CoordPos::OnBoundary,
  )
  // Inside polygon, outside hole = Inside
  assert_true(
    coord_position_for_polygon(@type.Coord(1.0, 1.0), p) == CoordPos::Inside,
  )
}

///|
test "coord_position rect" {
  let r = @type.Rect::Rect(@type.Coord(0.0, 0.0), @type.Coord(10.0, 10.0))
  assert_true(
    coord_position_for_rect(@type.Coord(5.0, 5.0), r) == CoordPos::Inside,
  )
  assert_true(
    coord_position_for_rect(@type.Coord(0.0, 5.0), r) == CoordPos::OnBoundary,
  )
  assert_true(
    coord_position_for_rect(@type.Coord(11.0, 11.0), r) == CoordPos::Outside,
  )
}

///|
test "coord_on_line endpoints and midpoints" {
  let l = @type.Line::from_tuples((0.0, 0.0), (10.0, 0.0))
  assert_true(coord_on_line(@type.Coord(0.0, 0.0), l))
  assert_true(coord_on_line(@type.Coord(10.0, 0.0), l))
  assert_true(coord_on_line(@type.Coord(5.0, 0.0), l))
  assert_true(!coord_on_line(@type.Coord(5.0, 1.0), l))
  assert_true(!coord_on_line(@type.Coord(11.0, 0.0), l))
}
