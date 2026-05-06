// Tests ported from georust/geo-types geometry/line.rs doctests.

///|
test "Line and accessors" {
  let line = @type.Line::Line(@type.Coord(0.0, 0.0), @type.Coord(1.0, 2.0))
  assert_true(line.start() == @type.Coord(0.0, 0.0))
  assert_true(line.end() == @type.Coord(1.0, 2.0))
}

///|
test "Line dx / dy / delta" {
  let line = @type.Line::Line(@type.Coord(4.0, -12.0), @type.Coord(0.0, 9.0))
  assert_eq(line.dx(), -4.0)
  assert_eq(line.dy(), 21.0)
  assert_true(line.delta() == @type.Coord(-4.0, 21.0))
}

///|
test "Line slope" {
  let line = @type.Line::Line(@type.Coord(4.0, -12.0), @type.Coord(0.0, 9.0))
  assert_eq(line.slope(), 21.0 / -4.0)
}

///|
test "Line slope is direction-independent" {
  let a = @type.Coord(4.0, -12.0)
  let b = @type.Coord(0.0, 9.0)
  assert_eq(@type.Line::Line(a, b).slope(), @type.Line::Line(b, a).slope())
}

///|
test "Line determinant" {
  let line = @type.Line::Line(@type.Coord(4.0, -12.0), @type.Coord(0.0, 9.0))
  assert_eq(line.determinant(), 4.0 * 9.0 - -12.0 * 0.0)
}

///|
test "Line determinant flips sign on reversal" {
  let a = @type.Coord(4.0, -12.0)
  let b = @type.Coord(0.0, 9.0)
  assert_eq(
    @type.Line::Line(a, b).determinant(),
    -@type.Line::Line(b, a).determinant(),
  )
}

///|
test "Line points / start_point / end_point" {
  let line = @type.Line::Line(@type.Coord(0.0, 0.0), @type.Coord(3.0, 4.0))
  assert_true(line.start_point() == @type.Point::Point(0.0, 0.0))
  assert_true(line.end_point() == @type.Point::Point(3.0, 4.0))
  let (s, e) = line.points()
  assert_true(s == @type.Point::Point(0.0, 0.0))
  assert_true(e == @type.Point::Point(3.0, 4.0))
}
