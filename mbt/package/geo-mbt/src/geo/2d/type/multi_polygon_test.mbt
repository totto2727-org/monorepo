// Tests for MultiPolygon.

///|
test "MultiPolygon basic" {
  let exterior = @type.LineString::from_tuples([
    (0.0, 0.0),
    (1.0, 0.0),
    (1.0, 1.0),
    (0.0, 1.0),
  ])
  let polygon = @type.Polygon::Polygon(exterior, [])
  let mp = @type.MultiPolygon::MultiPolygon([polygon])
  assert_eq(mp.length(), 1)
}

///|
test "MultiPolygon::empty" {
  let a = @type.MultiPolygon::empty()
  let b = @type.MultiPolygon::MultiPolygon([])
  assert_true(a == b)
  assert_true(a.is_empty())
}
