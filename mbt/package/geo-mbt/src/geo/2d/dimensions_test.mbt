// Tests for dimensions.mbt.

///|
test "dimensions of basic geometries" {
  assert_true(
    dimensions_of_geometry(@type.Geometry::Point(@type.Point::Point(0.0, 5.0))) ==
    Dimensions::ZeroDimensional,
  )
  let ls = @type.LineString::from_tuples([(0.0, 0.0), (5.0, 5.0), (0.0, 5.0)])
  assert_true(
    dimensions_of_geometry(@type.Geometry::LineString(ls)) ==
    Dimensions::OneDimensional,
  )
  let r = @type.Rect::Rect(@type.Coord(0.0, 0.0), @type.Coord(10.0, 10.0))
  assert_true(
    dimensions_of_geometry(@type.Geometry::Rect(r)) ==
    Dimensions::TwoDimensional,
  )
}

///|
test "degenerate rect dimensions" {
  // Zero height: rect collapses to a horizontal segment (1D).
  let r1 = @type.Rect::Rect(@type.Coord(0.0, 10.0), @type.Coord(10.0, 10.0))
  assert_true(dimensions_of_rect(r1) == Dimensions::OneDimensional)
  // Zero width and zero height: collapses to a single point.
  let r2 = @type.Rect::Rect(@type.Coord(10.0, 10.0), @type.Coord(10.0, 10.0))
  assert_true(dimensions_of_rect(r2) == Dimensions::ZeroDimensional)
}

///|
test "empty multi point has Empty dimensions" {
  let mp = @type.MultiPoint::MultiPoint([])
  assert_true(
    dimensions_of_geometry(@type.Geometry::MultiPoint(mp)) == Dimensions::Empty,
  )
}

///|
test "is_empty for various geometries" {
  let p = @type.Point::Point(1.0, 2.0)
  assert_true(!is_empty_of_geometry(@type.Geometry::Point(p)))
  let mp_empty = @type.MultiPoint::MultiPoint([])
  assert_true(is_empty_of_geometry(@type.Geometry::MultiPoint(mp_empty)))
  let ls_empty = @type.LineString::LineString([])
  assert_true(is_empty_of_geometry(@type.Geometry::LineString(ls_empty)))
}
