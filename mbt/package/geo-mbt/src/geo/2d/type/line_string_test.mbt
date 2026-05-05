// Tests ported from georust/geo-types geometry/line_string.rs doctests.

///|
test "LineString::from_tuples and length" {
  let ls = @type.LineString::from_tuples([(0.0, 0.0), (1.0, 1.0), (2.0, 2.0)])
  assert_eq(ls.length(), 3)
  assert_true(!ls.is_empty())
}

///|
test "LineString empty" {
  let ls = @type.LineString::new([])
  assert_true(ls.is_empty())
  assert_true(!ls.is_closed())
  assert_eq(ls.lines().length(), 0)
}

///|
test "LineString is_closed" {
  let open = @type.LineString::from_tuples([(0.0, 0.0), (1.0, 1.0), (2.0, 2.0)])
  assert_true(!open.is_closed())
  let closed = @type.LineString::from_tuples([
    (0.0, 0.0),
    (1.0, 1.0),
    (2.0, 0.0),
    (0.0, 0.0),
  ])
  assert_true(closed.is_closed())
}

///|
test "LineString lines (segments)" {
  let ls = @type.LineString::from_tuples([(0.0, 0.0), (1.0, 1.0), (2.0, 0.0)])
  let segments = ls.lines()
  assert_eq(segments.length(), 2)
  assert_true(segments[0] == @type.Line::from_tuples((0.0, 0.0), (1.0, 1.0)))
  assert_true(segments[1] == @type.Line::from_tuples((1.0, 1.0), (2.0, 0.0)))
}

///|
test "LineString close in place" {
  let ls = @type.LineString::from_tuples([(0.0, 0.0), (1.0, 1.0), (2.0, 0.0)])
  ls.close()
  assert_true(ls.is_closed())
  assert_eq(ls.length(), 4)
  // Idempotent: closing again is a no-op
  ls.close()
  assert_eq(ls.length(), 4)
}
