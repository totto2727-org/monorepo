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
test "MultiLineString::is_closed: empty is vacuously closed" {
  let mls = @type.MultiLineString::MultiLineString([])
  assert_true(mls.is_closed())
}

///|
test "MultiLineString::is_closed: all components closed -> true" {
  let closed1 = @type.LineString::from_tuples([
    (0.0, 0.0),
    (1.0, 0.0),
    (1.0, 1.0),
    (0.0, 0.0),
  ])
  let closed2 = @type.LineString::from_tuples([
    (10.0, 10.0),
    (12.0, 10.0),
    (10.0, 10.0),
  ])
  let mls = @type.MultiLineString::MultiLineString([closed1, closed2])
  assert_true(mls.is_closed())
}

///|
test "MultiLineString::is_closed: any open component -> false" {
  let closed = @type.LineString::from_tuples([
    (0.0, 0.0),
    (1.0, 0.0),
    (1.0, 1.0),
    (0.0, 0.0),
  ])
  let open_ls = @type.LineString::from_tuples([(0.0, 0.0), (1.0, 1.0)])
  // closed + open -> not all closed
  let mls1 = @type.MultiLineString::MultiLineString([closed, open_ls])
  assert_true(!mls1.is_closed())
  // open + closed -> order doesn't matter
  let mls2 = @type.MultiLineString::MultiLineString([open_ls, closed])
  assert_true(!mls2.is_closed())
}

///|
test "MultiLineString::is_closed: single closed / single open" {
  let closed = @type.LineString::from_tuples([
    (0.0, 0.0),
    (1.0, 0.0),
    (0.0, 0.0),
  ])
  assert_true(@type.MultiLineString::MultiLineString([closed]).is_closed())
  let open_ls = @type.LineString::from_tuples([(0.0, 0.0), (1.0, 1.0)])
  assert_true(!@type.MultiLineString::MultiLineString([open_ls]).is_closed())
}

///|
test "MultiLineString::empty" {
  let a = @type.MultiLineString::empty()
  let b = @type.MultiLineString::MultiLineString([])
  assert_true(a == b)
  assert_true(a.is_empty())
  assert_true(a.is_closed()) // empty multi-line-string is vacuously closed
}
