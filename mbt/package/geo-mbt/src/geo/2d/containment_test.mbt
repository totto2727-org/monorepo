// Tests for contains / within / covers.

///|
fn make_test_polygon() -> @type.Polygon {
  let exterior = @type.LineString::from_tuples([
    (0.0, 0.0),
    (10.0, 0.0),
    (10.0, 10.0),
    (0.0, 10.0),
    (0.0, 0.0),
  ])
  @type.Polygon::new(exterior, [])
}

///|
test "contains_polygon_point: inside" {
  let p = make_test_polygon()
  assert_true(contains_polygon_point(p, @type.Point::new(5.0, 5.0)))
}

///|
test "contains_polygon_point: boundary excluded" {
  let p = make_test_polygon()
  // Contains is strict — boundary is NOT contained
  assert_true(!contains_polygon_point(p, @type.Point::new(0.0, 5.0)))
}

///|
test "contains_polygon_point: outside" {
  let p = make_test_polygon()
  assert_true(!contains_polygon_point(p, @type.Point::new(20.0, 20.0)))
}

///|
test "covers_polygon_point: boundary INCLUDED" {
  let p = make_test_polygon()
  assert_true(covers_polygon_point(p, @type.Point::new(0.0, 5.0)))
  assert_true(covers_polygon_point(p, @type.Point::new(5.0, 5.0)))
  assert_true(!covers_polygon_point(p, @type.Point::new(20.0, 20.0)))
}

///|
test "contains_polygon_polygon: nested" {
  let outer = make_test_polygon()
  let inner_ext = @type.LineString::from_tuples([
    (2.0, 2.0),
    (4.0, 2.0),
    (4.0, 4.0),
    (2.0, 4.0),
    (2.0, 2.0),
  ])
  let inner = @type.Polygon::new(inner_ext, [])
  assert_true(contains_polygon_polygon(outer, inner))
}

///|
test "contains_polygon_polygon: not contained" {
  let outer = make_test_polygon()
  let inner_ext = @type.LineString::from_tuples([
    (5.0, 5.0),
    (15.0, 5.0),
    (15.0, 15.0),
    (5.0, 15.0),
    (5.0, 5.0),
  ])
  let inner = @type.Polygon::new(inner_ext, [])
  assert_true(!contains_polygon_polygon(outer, inner))
}

///|
test "contains_rect_rect" {
  let outer = @type.Rect::new(
    @type.Coord::new(0.0, 0.0),
    @type.Coord::new(10.0, 10.0),
  )
  let inner = @type.Rect::new(
    @type.Coord::new(2.0, 2.0),
    @type.Coord::new(8.0, 8.0),
  )
  assert_true(contains_rect_rect(outer, inner))
  let outside = @type.Rect::new(
    @type.Coord::new(5.0, 5.0),
    @type.Coord::new(15.0, 15.0),
  )
  assert_true(!contains_rect_rect(outer, outside))
}

///|
test "within is the inverse of contains" {
  let p = make_test_polygon()
  let pt = @type.Point::new(5.0, 5.0)
  assert_true(
    within_geometry(@type.Geometry::Point(pt), @type.Geometry::Polygon(p)),
  )
  assert_true(
    !within_geometry(@type.Geometry::Polygon(p), @type.Geometry::Point(pt)),
  )
}

///|
test "covers_geometry boundary point" {
  let p = make_test_polygon()
  let boundary_pt = @type.Point::new(0.0, 5.0)
  // contains: false (strict), covers: true (inclusive)
  assert_true(
    !contains_geometry(
      @type.Geometry::Polygon(p),
      @type.Geometry::Point(boundary_pt),
    ),
  )
  assert_true(
    covers_geometry(
      @type.Geometry::Polygon(p),
      @type.Geometry::Point(boundary_pt),
    ),
  )
}
