// Tests for line_interpolate_point.mbt.

///|
test "line_interpolate_point: f=0 is start" {
  let l = @type.Line::from_tuples((1.0, 2.0), (5.0, 10.0))
  let p = line_interpolate_point(l, 0.0)
  assert_true(p == @type.Point::Point(1.0, 2.0))
}

///|
test "line_interpolate_point: f=1 is end" {
  let l = @type.Line::from_tuples((1.0, 2.0), (5.0, 10.0))
  let p = line_interpolate_point(l, 1.0)
  assert_true(p == @type.Point::Point(5.0, 10.0))
}

///|
test "line_interpolate_point: f=0.5 is midpoint" {
  let l = @type.Line::from_tuples((0.0, 0.0), (10.0, 20.0))
  let p = line_interpolate_point(l, 0.5)
  assert_true(p == @type.Point::Point(5.0, 10.0))
}

///|
test "line_string_interpolate_point: half-way along" {
  let ls = @type.LineString::from_tuples([(0.0, 0.0), (10.0, 0.0), (10.0, 10.0)])
  // Total length = 20; half = 10 → at (10, 0)
  let p = line_string_interpolate_point(ls, 0.5).unwrap()
  assert_true((p.x() - 10.0).abs() < 1.0e-9)
  assert_true(p.y().abs() < 1.0e-9)
}
