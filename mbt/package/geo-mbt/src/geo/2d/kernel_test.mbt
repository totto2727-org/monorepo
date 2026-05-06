// Tests for the Kernel orientation predicate.

///|
test "orient: counter-clockwise triangle" {
  let p = @type.Coord(0.0, 0.0)
  let q = @type.Coord(1.0, 0.0)
  let r = @type.Coord(0.0, 1.0)
  assert_true(orient(p, q, r) == Orientation::CounterClockwise)
}

///|
test "orient: clockwise triangle" {
  let p = @type.Coord(0.0, 0.0)
  let q = @type.Coord(0.0, 1.0)
  let r = @type.Coord(1.0, 0.0)
  assert_true(orient(p, q, r) == Orientation::Clockwise)
}

///|
test "orient: collinear" {
  let p = @type.Coord(0.0, 0.0)
  let q = @type.Coord(1.0, 1.0)
  let r = @type.Coord(2.0, 2.0)
  assert_true(orient(p, q, r) == Orientation::Collinear)
}
