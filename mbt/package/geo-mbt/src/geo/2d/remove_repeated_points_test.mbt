// Tests for remove_repeated_points.mbt.

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
