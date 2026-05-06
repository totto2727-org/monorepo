// Tests for simplify_vw.mbt (Visvalingam-Whyatt).

///|
test "simplify_vw removes the lowest-area triangle" {
  let ls = @type.LineString::from_tuples([(0.0, 0.0), (5.0, 0.5), (10.0, 0.0)])
  // Triangle area = 0.5 * 5 * 0.5 / 2 = ?
  // Triangle 2*area = |10*0.5 - 0*5| = 5; eps=10 → threshold=20; 5 < 20: removed
  let simplified = simplify_vw_line_string(ls, 10.0)
  assert_eq(simplified.coords().length(), 2)
}
