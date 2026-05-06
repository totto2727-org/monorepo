// Tests for bounding_rect.mbt.

///|
test "bounding_rect_of_line_string" {
  let ls = @type.LineString::from_tuples([
    (40.02, 116.34),
    (42.02, 116.34),
    (42.02, 118.34),
  ])
  let rect = Bounded::bbox(ls).unwrap()
  assert_eq(rect.min().x(), 40.02)
  assert_eq(rect.max().x(), 42.02)
  assert_eq(rect.min().y(), 116.34)
  assert_eq(rect.max().y(), 118.34)
}

///|
test "bounding_rect_of_point is degenerate" {
  let p = @type.Point::Point(1.0, 2.0)
  let r = Bounded::bbox(p).unwrap()
  assert_eq(r.width(), 0.0)
  assert_eq(r.height(), 0.0)
}

///|
test "bounding_rect_of_line_string empty" {
  let ls = @type.LineString::LineString([])
  assert_true(Bounded::bbox(ls) == None)
}
