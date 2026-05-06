// Tests for intersects.mbt.

///|
fn intersects_test_polygon() -> @type.Polygon {
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
  let a = intersects_test_polygon()
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
  let a = intersects_test_polygon()
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
  let poly = @type.Geometry::Polygon(intersects_test_polygon())
  assert_true(intersects_geometry(p, poly))
}
