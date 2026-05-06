// Tests for MultiLineString.

///|
test "MultiLineString length" {
  let ls1 = @type.LineString::from_tuples([(0.0, 0.0), (1.0, 1.0)])
  let ls2 = @type.LineString::from_tuples([(2.0, 0.0), (3.0, 1.0)])
  let mls = @type.MultiLineString::MultiLineString([ls1, ls2])
  assert_eq(mls.length(), 2)
  assert_true(!mls.is_empty())
}

///|
test "MultiLineString empty is closed" {
  let mls = @type.MultiLineString::MultiLineString([])
  assert_true(mls.is_closed())
}

///|
test "MultiLineString::empty" {
  let a = @type.MultiLineString::empty()
  let b = @type.MultiLineString::MultiLineString([])
  assert_true(a == b)
  assert_true(a.is_empty())
  assert_true(a.is_closed()) // empty multi-line-string is vacuously closed
}
