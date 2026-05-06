// Tests for chaikin_smoothing.mbt.

///|
test "chaikin_smoothing 0 iterations is identity" {
  let ls = @type.LineString::from_tuples([(0.0, 0.0), (10.0, 0.0)])
  let smoothed = chaikin_smoothing(ls, 0)
  assert_eq(smoothed.coords().length(), 2)
}

///|
test "chaikin_smoothing 1 iteration: open line gets 2*(n-1) + 2 = 2n coords" {
  let ls = @type.LineString::from_tuples([(0.0, 0.0), (10.0, 0.0)])
  let smoothed = chaikin_smoothing(ls, 1)
  // 2 input → 1 segment → 2 cut points + 2 endpoints = 4 coords
  assert_eq(smoothed.coords().length(), 4)
}
