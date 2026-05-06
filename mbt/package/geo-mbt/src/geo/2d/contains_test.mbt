// Tests for contains.mbt.

///|
fn contains_test_polygon() -> @type.Polygon {
  let exterior = @type.LineString::from_tuples([
    (0.0, 0.0),
    (10.0, 0.0),
    (10.0, 10.0),
    (0.0, 10.0),
    (0.0, 0.0),
  ])
  @type.Polygon::Polygon(exterior, [])
}

///|
test "contains_polygon_point: inside" {
  let p = contains_test_polygon()
  assert_true(contains_polygon_point(p, @type.Point::Point(5.0, 5.0)))
}

///|
test "contains_polygon_point: boundary excluded" {
  let p = contains_test_polygon()
  // Contains is strict — boundary is NOT contained
  assert_true(!contains_polygon_point(p, @type.Point::Point(0.0, 5.0)))
}

///|
test "contains_polygon_point: outside" {
  let p = contains_test_polygon()
  assert_true(!contains_polygon_point(p, @type.Point::Point(20.0, 20.0)))
}

///|
test "contains_polygon_polygon: nested" {
  let outer = contains_test_polygon()
  let inner_ext = @type.LineString::from_tuples([
    (2.0, 2.0),
    (4.0, 2.0),
    (4.0, 4.0),
    (2.0, 4.0),
    (2.0, 2.0),
  ])
  let inner = @type.Polygon::Polygon(inner_ext, [])
  assert_true(contains_polygon_polygon(outer, inner))
}

///|
test "contains_polygon_polygon: not contained" {
  let outer = contains_test_polygon()
  let inner_ext = @type.LineString::from_tuples([
    (5.0, 5.0),
    (15.0, 5.0),
    (15.0, 15.0),
    (5.0, 15.0),
    (5.0, 5.0),
  ])
  let inner = @type.Polygon::Polygon(inner_ext, [])
  assert_true(!contains_polygon_polygon(outer, inner))
}

///|
test "contains_rect_rect" {
  let outer = @type.Rect::Rect(@type.Coord(0.0, 0.0), @type.Coord(10.0, 10.0))
  let inner = @type.Rect::Rect(@type.Coord(2.0, 2.0), @type.Coord(8.0, 8.0))
  assert_true(contains_rect_rect(outer, inner))
  let outside = @type.Rect::Rect(@type.Coord(5.0, 5.0), @type.Coord(15.0, 15.0))
  assert_true(!contains_rect_rect(outer, outside))
}

///|
test "within is the inverse of contains" {
  let p = contains_test_polygon()
  let pt = @type.Point::Point(5.0, 5.0)
  assert_true(
    within_geometry(@type.Geometry::Point(pt), @type.Geometry::Polygon(p)),
  )
  assert_true(
    !within_geometry(@type.Geometry::Polygon(p), @type.Geometry::Point(pt)),
  )
}
