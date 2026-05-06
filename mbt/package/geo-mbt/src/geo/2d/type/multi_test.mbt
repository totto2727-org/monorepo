// Tests for MultiPoint, MultiLineString, MultiPolygon, GeometryCollection.

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
test "GeometryCollection holds heterogeneous geometries" {
  let gc = @type.GeometryCollection::GeometryCollection([
    @type.Geometry::Point(@type.Point::Point(1.0, 2.0)),
    @type.Geometry::Line(@type.Line::from_tuples((0.0, 0.0), (1.0, 1.0))),
  ])
  assert_eq(gc.length(), 2)
  assert_true(!gc.is_empty())
}

///|
test "MultiPoint::empty" {
  let a = @type.MultiPoint::empty()
  let b = @type.MultiPoint::MultiPoint([])
  assert_true(a == b)
  assert_true(a.is_empty())
}

///|
test "MultiLineString::empty" {
  let a = @type.MultiLineString::empty()
  let b = @type.MultiLineString::MultiLineString([])
  assert_true(a == b)
  assert_true(a.is_empty())
  assert_true(a.is_closed()) // empty multi-line-string is vacuously closed
}

///|
test "MultiPolygon::empty" {
  let a = @type.MultiPolygon::empty()
  let b = @type.MultiPolygon::MultiPolygon([])
  assert_true(a == b)
  assert_true(a.is_empty())
}

///|
test "GeometryCollection::empty" {
  let a = @type.GeometryCollection::empty()
  let b = @type.GeometryCollection::GeometryCollection([])
  assert_true(a == b)
  assert_true(a.is_empty())
}
