// Tests for centroid, extremes, winding_order, is_convex, orient.

///|
test "centroid of unit square is (0.5, 0.5)" {
  let exterior = @type.LineString::from_tuples([
    (0.0, 0.0),
    (1.0, 0.0),
    (1.0, 1.0),
    (0.0, 1.0),
    (0.0, 0.0),
  ])
  let p = @type.Polygon::new(exterior, [])
  let c = centroid_polygon(p).unwrap()
  assert_true((c.x() - 0.5).abs() < 1.0e-9)
  assert_true((c.y() - 0.5).abs() < 1.0e-9)
}

///|
test "centroid of triangle is (avg, avg)" {
  let t = @type.Triangle::new(
    @type.Coord::new(0.0, 0.0),
    @type.Coord::new(6.0, 0.0),
    @type.Coord::new(0.0, 9.0),
  )
  let c = centroid_geometry(@type.Geometry::Triangle(t)).unwrap()
  assert_eq(c.x(), 2.0)
  assert_eq(c.y(), 3.0)
}

///|
test "centroid of rect is rect.center" {
  let r = @type.Rect::new(
    @type.Coord::new(0.0, 0.0),
    @type.Coord::new(10.0, 20.0),
  )
  let c = centroid_geometry(@type.Geometry::Rect(r)).unwrap()
  assert_eq(c.x(), 5.0)
  assert_eq(c.y(), 10.0)
}

///|
test "winding_order: CCW positive area" {
  let ls = @type.LineString::from_tuples([
    (0.0, 0.0),
    (1.0, 0.0),
    (1.0, 1.0),
    (0.0, 1.0),
    (0.0, 0.0),
  ])
  assert_true(winding_order(ls).unwrap() == WindingOrder::CounterClockwise)
}

///|
test "winding_order: CW negative area" {
  let ls = @type.LineString::from_tuples([
    (0.0, 0.0),
    (0.0, 1.0),
    (1.0, 1.0),
    (1.0, 0.0),
    (0.0, 0.0),
  ])
  assert_true(winding_order(ls).unwrap() == WindingOrder::Clockwise)
}

///|
test "is_convex: square" {
  let ls = @type.LineString::from_tuples([
    (0.0, 0.0),
    (1.0, 0.0),
    (1.0, 1.0),
    (0.0, 1.0),
    (0.0, 0.0),
  ])
  assert_true(is_convex(ls))
}

///|
test "is_convex: concave shape" {
  // A concave 'L' shape
  let ls = @type.LineString::from_tuples([
    (0.0, 0.0),
    (2.0, 0.0),
    (2.0, 1.0),
    (1.0, 1.0),
    (1.0, 2.0),
    (0.0, 2.0),
    (0.0, 0.0),
  ])
  assert_true(!is_convex(ls))
}

///|
test "orient_polygon: makes exterior CCW by default" {
  // CW exterior input
  let cw_exterior = @type.LineString::from_tuples([
    (0.0, 0.0),
    (0.0, 1.0),
    (1.0, 1.0),
    (1.0, 0.0),
    (0.0, 0.0),
  ])
  let p = @type.Polygon::new(cw_exterior, [])
  let oriented = orient_polygon(p, OrientDirection::Default)
  assert_true(
    winding_order(oriented.exterior()).unwrap() ==
    WindingOrder::CounterClockwise,
  )
}

///|
test "extremes_of_geometry" {
  let ls = @type.LineString::from_tuples([
    (1.0, 5.0),
    (3.0, 2.0),
    (-1.0, 7.0),
    (4.0, 0.0),
  ])
  let outcome = extremes_of_geometry(@type.Geometry::LineString(ls)).unwrap()
  assert_eq(outcome.x_min.x(), -1.0)
  assert_eq(outcome.x_max.x(), 4.0)
  assert_eq(outcome.y_min.y(), 0.0)
  assert_eq(outcome.y_max.y(), 7.0)
}

///|
test "reverse_line_string" {
  let ls = @type.LineString::from_tuples([(0.0, 0.0), (1.0, 0.0), (1.0, 1.0)])
  let rev = reverse_line_string(ls)
  let coords = rev.coords()
  assert_true(coords[0] == @type.Coord::new(1.0, 1.0))
  assert_true(coords[2] == @type.Coord::new(0.0, 0.0))
}
