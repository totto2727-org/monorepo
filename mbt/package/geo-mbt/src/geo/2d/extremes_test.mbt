// Tests for extremes.mbt.

///|
test "extremes_of_geometry" {
  let ls = @type.LineString::from_tuples([
    (1.0, 5.0),
    (3.0, 2.0),
    (-1.0, 7.0),
    (4.0, 0.0),
  ])
  let outcome = HasExtremes::extremes(@type.Geometry::LineString(ls)).unwrap()
  assert_eq(outcome.x_min.x(), -1.0)
  assert_eq(outcome.x_max.x(), 4.0)
  assert_eq(outcome.y_min.y(), 0.0)
  assert_eq(outcome.y_max.y(), 7.0)
}
