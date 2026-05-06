// Tests for GeometryCollection.

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
test "GeometryCollection::empty" {
  let a = @type.GeometryCollection::empty()
  let b = @type.GeometryCollection::GeometryCollection([])
  assert_true(a == b)
  assert_true(a.is_empty())
}
