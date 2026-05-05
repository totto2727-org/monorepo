// Tests for validation.

///|
test "valid polygon" {
  let exterior = @type.LineString::from_tuples([
    (0.0, 0.0),
    (1.0, 0.0),
    (1.0, 1.0),
    (0.0, 1.0),
  ])
  let p = @type.Polygon::new(exterior, [])
  assert_true(is_valid(@type.Geometry::Polygon(p)))
  assert_eq(validation_problems(@type.Geometry::Polygon(p)).length(), 0)
}

///|
test "linestring with 1 coord is invalid" {
  let ls = @type.LineString::from_tuples([(0.0, 0.0)])
  assert_true(!is_valid(@type.Geometry::LineString(ls)))
}

///|
test "valid linestring" {
  let ls = @type.LineString::from_tuples([(0.0, 0.0), (1.0, 1.0)])
  assert_true(is_valid(@type.Geometry::LineString(ls)))
}

///|
test "non-finite coord is invalid" {
  let p = @type.Point::new(0.0 / 0.0, 0.0) // NaN
  assert_true(!is_valid(@type.Geometry::Point(p)))
}

///|
test "ring with too few points is invalid" {
  // A polygon with exterior containing only 2 unique coords → too few
  let exterior = @type.LineString::from_tuples([(0.0, 0.0), (1.0, 1.0)])
  let p = @type.Polygon::new(exterior, [])
  // After auto-close, exterior has 3 coords (start, mid, start). Still <4.
  assert_true(!is_valid(@type.Geometry::Polygon(p)))
}
