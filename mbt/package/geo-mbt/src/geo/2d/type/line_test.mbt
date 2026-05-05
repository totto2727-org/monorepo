// Tests ported from georust/geo-types geometry/line.rs doctests.

///|
test "Line::new and accessors" {
  let line = @type.Line::new(@type.Coord::new(0.0, 0.0), @type.Coord::new(1.0, 2.0))
  assert_true(line.start() == @type.Coord::new(0.0, 0.0))
  assert_true(line.end() == @type.Coord::new(1.0, 2.0))
}

///|
test "Line dx / dy / delta" {
  let line = @type.Line::new(@type.Coord::new(4.0, -12.0), @type.Coord::new(0.0, 9.0))
  assert_eq(line.dx(), -4.0)
  assert_eq(line.dy(), 21.0)
  assert_true(line.delta() == @type.Coord::new(-4.0, 21.0))
}

///|
test "Line slope" {
  let line = @type.Line::new(@type.Coord::new(4.0, -12.0), @type.Coord::new(0.0, 9.0))
  assert_eq(line.slope(), 21.0 / -4.0)
}

///|
test "Line slope is direction-independent" {
  let a = @type.Coord::new(4.0, -12.0)
  let b = @type.Coord::new(0.0, 9.0)
  assert_eq(@type.Line::new(a, b).slope(), @type.Line::new(b, a).slope())
}

///|
test "Line determinant" {
  let line = @type.Line::new(@type.Coord::new(4.0, -12.0), @type.Coord::new(0.0, 9.0))
  assert_eq(line.determinant(), 4.0 * 9.0 - -12.0 * 0.0)
}

///|
test "Line determinant flips sign on reversal" {
  let a = @type.Coord::new(4.0, -12.0)
  let b = @type.Coord::new(0.0, 9.0)
  assert_eq(
    @type.Line::new(a, b).determinant(),
    -@type.Line::new(b, a).determinant(),
  )
}

///|
test "Line points / start_point / end_point" {
  let line = @type.Line::new(@type.Coord::new(0.0, 0.0), @type.Coord::new(3.0, 4.0))
  assert_true(line.start_point() == @type.Point::new(0.0, 0.0))
  assert_true(line.end_point() == @type.Point::new(3.0, 4.0))
  let (s, e) = line.points()
  assert_true(s == @type.Point::new(0.0, 0.0))
  assert_true(e == @type.Point::new(3.0, 4.0))
}
