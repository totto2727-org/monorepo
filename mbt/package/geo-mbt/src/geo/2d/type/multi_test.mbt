// Tests for MultiPoint, MultiLineString, MultiPolygon, GeometryCollection.

///|
test "MultiPoint::from_tuples" {
  let mp = @type.MultiPoint::from_tuples([(0.0, 0.0), (1.0, 1.0)])
  assert_eq(mp.length(), 2)
  assert_true(!mp.is_empty())
}

///|
test "MultiPoint empty" {
  let mp = @type.MultiPoint::new([])
  assert_true(mp.is_empty())
  assert_eq(mp.length(), 0)
}

///|
test "MultiLineString length" {
  let ls1 = @type.LineString::from_tuples([(0.0, 0.0), (1.0, 1.0)])
  let ls2 = @type.LineString::from_tuples([(2.0, 0.0), (3.0, 1.0)])
  let mls = @type.MultiLineString::new([ls1, ls2])
  assert_eq(mls.length(), 2)
  assert_true(!mls.is_empty())
}

///|
test "MultiLineString empty is closed" {
  let mls = @type.MultiLineString::new([])
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
  let polygon = @type.Polygon::new(exterior, [])
  let mp = @type.MultiPolygon::new([polygon])
  assert_eq(mp.length(), 1)
}

///|
test "GeometryCollection holds heterogeneous geometries" {
  let gc = @type.GeometryCollection::new([
    @type.Geometry::Point(@type.Point::new(1.0, 2.0)),
    @type.Geometry::Line(@type.Line::from_tuples((0.0, 0.0), (1.0, 1.0))),
  ])
  assert_eq(gc.length(), 2)
  assert_true(!gc.is_empty())
}
