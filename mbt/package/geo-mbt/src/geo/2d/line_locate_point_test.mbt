// Tests for line_locate_point.mbt.

///|
test "line_locate_point: midpoint of segment is 0.5" {
  let l = @type.Line::from_tuples((0.0, 0.0), (10.0, 0.0))
  let f = line_locate_point(l, @type.Coord(5.0, 5.0)).unwrap()
  assert_eq(f, 0.5)
}

///|
test "line_locate_point: beyond end is clamped to 1.0" {
  let l = @type.Line::from_tuples((0.0, 0.0), (10.0, 0.0))
  let f = line_locate_point(l, @type.Coord(20.0, 0.0)).unwrap()
  assert_eq(f, 1.0)
}
