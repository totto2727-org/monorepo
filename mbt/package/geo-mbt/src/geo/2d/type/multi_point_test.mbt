// Tests for MultiPoint.

///|
test "MultiPoint::from_tuples" {
  let mp = @type.MultiPoint::from_tuples([(0.0, 0.0), (1.0, 1.0)])
  assert_eq(mp.length(), 2)
  assert_true(!mp.is_empty())
}

///|
test "MultiPoint empty" {
  let mp = @type.MultiPoint::MultiPoint([])
  assert_true(mp.is_empty())
  assert_eq(mp.length(), 0)
}

///|
test "MultiPoint::empty" {
  let a = @type.MultiPoint::empty()
  let b = @type.MultiPoint::MultiPoint([])
  assert_true(a == b)
  assert_true(a.is_empty())
}
