// Tests for coordinate_position and intersects.

///|
fn make_unit_square_polygon() -> @type.Polygon {
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
  let p = make_unit_square_polygon()
  assert_true(
    coord_position_for_polygon(@type.Coord(1.0, 1.0), p) == CoordPos::Inside,
  )
}

///|
test "coord_position polygon: boundary" {
  let p = make_unit_square_polygon()
  assert_true(
    coord_position_for_polygon(@type.Coord(0.0, 1.0), p) == CoordPos::OnBoundary,
  )
}

///|
test "coord_position polygon: outside" {
  let p = make_unit_square_polygon()
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

///|
test "intersects_line_line — touching endpoints" {
  let a = @type.Line::from_tuples((0.0, 0.0), (1.0, 0.0))
  let b = @type.Line::from_tuples((1.0, 0.0), (1.0, 1.0))
  assert_true(intersects_line_line(a, b))
}

///|
test "intersects_line_line — crossing" {
  let a = @type.Line::from_tuples((0.0, 0.0), (10.0, 10.0))
  let b = @type.Line::from_tuples((0.0, 10.0), (10.0, 0.0))
  assert_true(intersects_line_line(a, b))
}

///|
test "intersects_line_line — parallel non-overlapping" {
  let a = @type.Line::from_tuples((0.0, 0.0), (10.0, 0.0))
  let b = @type.Line::from_tuples((0.0, 1.0), (10.0, 1.0))
  assert_true(!intersects_line_line(a, b))
}

///|
test "intersects_line_line — collinear overlapping" {
  let a = @type.Line::from_tuples((0.0, 0.0), (10.0, 0.0))
  let b = @type.Line::from_tuples((5.0, 0.0), (15.0, 0.0))
  assert_true(intersects_line_line(a, b))
}

///|
test "intersects_polygon_polygon — overlap" {
  let a = make_unit_square_polygon()
  let exterior_b = @type.LineString::from_tuples([
    (1.0, 1.0),
    (3.0, 1.0),
    (3.0, 3.0),
    (1.0, 3.0),
  ])
  let b = @type.Polygon::Polygon(exterior_b, [])
  assert_true(intersects_polygon_polygon(a, b))
}

///|
test "intersects_polygon_polygon — disjoint" {
  let a = make_unit_square_polygon()
  let exterior_b = @type.LineString::from_tuples([
    (10.0, 10.0),
    (12.0, 10.0),
    (12.0, 12.0),
    (10.0, 12.0),
  ])
  let b = @type.Polygon::Polygon(exterior_b, [])
  assert_true(!intersects_polygon_polygon(a, b))
}

///|
test "intersects_geometry dispatch" {
  let p = @type.Geometry::Point(@type.Point::Point(1.0, 1.0))
  let poly = @type.Geometry::Polygon(make_unit_square_polygon())
  assert_true(intersects_geometry(p, poly))
}
