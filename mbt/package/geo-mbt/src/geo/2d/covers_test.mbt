// Tests for covers.mbt.

///|
fn covers_test_polygon() -> @type.Polygon {
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
test "covers_polygon_point: boundary INCLUDED" {
  let p = covers_test_polygon()
  assert_true(covers_polygon_point(p, @type.Point::Point(0.0, 5.0)))
  assert_true(covers_polygon_point(p, @type.Point::Point(5.0, 5.0)))
  assert_true(!covers_polygon_point(p, @type.Point::Point(20.0, 20.0)))
}

///|
test "covers_geometry boundary point" {
  let p = covers_test_polygon()
  let boundary_pt = @type.Point::Point(0.0, 5.0)
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
