// Tests for centroid.mbt.

///|
test "centroid of unit square is (0.5, 0.5)" {
  let exterior = @type.LineString::from_tuples([
    (0.0, 0.0),
    (1.0, 0.0),
    (1.0, 1.0),
    (0.0, 1.0),
    (0.0, 0.0),
  ])
  let p = @type.Polygon::Polygon(exterior, [])
  let c = HasCentroid::centroid(p).unwrap()
  assert_true((c.x() - 0.5).abs() < 1.0e-9)
  assert_true((c.y() - 0.5).abs() < 1.0e-9)
}

///|
test "centroid of triangle is (avg, avg)" {
  let t = @type.Triangle::Triangle(
    @type.Coord(0.0, 0.0),
    @type.Coord(6.0, 0.0),
    @type.Coord(0.0, 9.0),
  )
  let c = HasCentroid::centroid(@type.Geometry::Triangle(t)).unwrap()
  assert_eq(c.x(), 2.0)
  assert_eq(c.y(), 3.0)
}

///|
test "centroid of rect is rect.center" {
  let r = @type.Rect::Rect(@type.Coord(0.0, 0.0), @type.Coord(10.0, 20.0))
  let c = HasCentroid::centroid(@type.Geometry::Rect(r)).unwrap()
  assert_eq(c.x(), 5.0)
  assert_eq(c.y(), 10.0)
}
