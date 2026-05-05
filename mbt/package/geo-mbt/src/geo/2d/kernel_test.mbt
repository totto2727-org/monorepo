// Tests for the Kernel orientation predicate.

///|
test "orient: counter-clockwise triangle" {
  let p = @type.Coord::new(0.0, 0.0)
  let q = @type.Coord::new(1.0, 0.0)
  let r = @type.Coord::new(0.0, 1.0)
  assert_true(orient(p, q, r) == Orientation::CounterClockwise)
}

///|
test "orient: clockwise triangle" {
  let p = @type.Coord::new(0.0, 0.0)
  let q = @type.Coord::new(0.0, 1.0)
  let r = @type.Coord::new(1.0, 0.0)
  assert_true(orient(p, q, r) == Orientation::Clockwise)
}

///|
test "orient: collinear" {
  let p = @type.Coord::new(0.0, 0.0)
  let q = @type.Coord::new(1.0, 1.0)
  let r = @type.Coord::new(2.0, 2.0)
  assert_true(orient(p, q, r) == Orientation::Collinear)
}

///|
test "signed_area_of_triangle_robust" {
  // CCW unit right triangle has signed area 0.5 (cross product = 1).
  let p = @type.Coord::new(0.0, 0.0)
  let q = @type.Coord::new(1.0, 0.0)
  let r = @type.Coord::new(0.0, 1.0)
  assert_eq(signed_area_of_triangle_robust(p, q, r), 1.0)
}
