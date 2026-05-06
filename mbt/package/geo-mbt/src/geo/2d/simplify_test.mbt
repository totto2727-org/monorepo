// Tests for simplify.mbt (Ramer-Douglas-Peucker).

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
