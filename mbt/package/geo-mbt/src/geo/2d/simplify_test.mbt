// Tests for simplify / simplify_vw / chaikin_smoothing / remove_repeated_points.

///|
test "simplify line with eps=0 keeps all" {
  let ls = @type.LineString::from_tuples([(0.0, 0.0), (5.0, 0.001), (10.0, 0.0)])
  let simplified = simplify_line_string(ls, 0.0)
  // With eps=0, only colinear points within tolerance are removed.
  // Here the middle point is 0.001 above the line — kept.
  assert_eq(simplified.coords().length(), 3)
}

///|
test "simplify removes nearly colinear points" {
  let ls = @type.LineString::from_tuples([(0.0, 0.0), (5.0, 0.001), (10.0, 0.0)])
  let simplified = simplify_line_string(ls, 0.01)
  // Middle point (5, 0.001) is within eps=0.01 of the line — removed.
  assert_eq(simplified.coords().length(), 2)
}

///|
test "simplify line < 3 coords is unchanged" {
  let ls = @type.LineString::from_tuples([(0.0, 0.0), (10.0, 10.0)])
  let simplified = simplify_line_string(ls, 1.0)
  assert_eq(simplified.coords().length(), 2)
}

///|
test "simplify_vw removes the lowest-area triangle" {
  let ls = @type.LineString::from_tuples([(0.0, 0.0), (5.0, 0.5), (10.0, 0.0)])
  // Triangle area = 0.5 * 5 * 0.5 / 2 = ?
  // Triangle 2*area = |10*0.5 - 0*5| = 5; eps=10 → threshold=20; 5 < 20: removed
  let simplified = simplify_vw_line_string(ls, 10.0)
  assert_eq(simplified.coords().length(), 2)
}

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

///|
test "remove_repeated_points removes consecutive duplicates" {
  let ls = @type.LineString::from_tuples([
    (0.0, 0.0),
    (0.0, 0.0),
    (5.0, 0.0),
    (5.0, 0.0),
    (10.0, 0.0),
  ])
  let cleaned = remove_repeated_points_line_string(ls)
  assert_eq(cleaned.coords().length(), 3)
}
