// Tests for densify.mbt.

///|
test "densify_line_string: long segment gets split" {
  let ls = @type.LineString::from_tuples([(0.0, 0.0), (10.0, 0.0)])
  // max_segment_length = 5 → 1 segment of 10 → split into 2 of 5 each → 3 coords total
  let densified = Densify::densify(ls, 5.0)
  assert_eq(densified.coords().length(), 3)
  // Middle coord should be exactly halfway
  assert_true(densified.coords()[1] == @type.Coord(5.0, 0.0))
}

///|
test "densify_line_string: short segment unchanged" {
  let ls = @type.LineString::from_tuples([(0.0, 0.0), (3.0, 0.0)])
  let densified = Densify::densify(ls, 5.0)
  assert_eq(densified.coords().length(), 2)
}
