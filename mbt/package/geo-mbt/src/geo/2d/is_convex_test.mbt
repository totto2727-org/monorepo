// Tests for is_convex.mbt.

///|
test "is_convex: square" {
  let ls = @type.LineString::from_tuples([
    (0.0, 0.0),
    (1.0, 0.0),
    (1.0, 1.0),
    (0.0, 1.0),
    (0.0, 0.0),
  ])
  assert_true(is_convex(ls))
}

///|
test "is_convex: concave shape" {
  // A concave 'L' shape
  let ls = @type.LineString::from_tuples([
    (0.0, 0.0),
    (2.0, 0.0),
    (2.0, 1.0),
    (1.0, 1.0),
    (1.0, 2.0),
    (0.0, 2.0),
    (0.0, 0.0),
  ])
  assert_true(!is_convex(ls))
}
