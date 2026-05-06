// Tests ported from georust/geo-types geometry/polygon.rs doctests.

///|
test "Polygon closes exterior ring" {
  let exterior = @type.LineString::from_tuples([
    (0.0, 0.0),
    (1.0, 0.0),
    (1.0, 1.0),
    (0.0, 1.0),
  ])
  let polygon = @type.Polygon::Polygon(exterior, [])
  // The exterior should now be closed
  assert_true(polygon.exterior().is_closed())
  assert_eq(polygon.exterior().length(), 5)
  assert_eq(polygon.num_interiors(), 0)
}

///|
test "Polygon closes interior rings" {
  let exterior = @type.LineString::from_tuples([
    (0.0, 0.0),
    (10.0, 0.0),
    (10.0, 10.0),
    (0.0, 10.0),
  ])
  let interior = @type.LineString::from_tuples([
    (3.0, 3.0),
    (7.0, 3.0),
    (7.0, 7.0),
    (3.0, 7.0),
  ])
  let polygon = @type.Polygon::Polygon(exterior, [interior])
  assert_eq(polygon.num_interiors(), 1)
  assert_true(polygon.interiors()[0].is_closed())
}

///|
test "Polygon already-closed exterior is preserved" {
  let exterior = @type.LineString::from_tuples([
    (0.0, 0.0),
    (1.0, 0.0),
    (1.0, 1.0),
    (0.0, 1.0),
    (0.0, 0.0),
  ])
  let polygon = @type.Polygon::Polygon(exterior, [])
  assert_eq(polygon.exterior().length(), 5)
}
