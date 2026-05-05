// Tests for bounding_rect, area, and dimensions.

///|
test "bounding_rect_of_line_string" {
  let ls = @type.LineString::from_tuples([
    (40.02, 116.34),
    (42.02, 116.34),
    (42.02, 118.34),
  ])
  let rect = bounding_rect_of_line_string(ls).unwrap()
  assert_eq(rect.min().x(), 40.02)
  assert_eq(rect.max().x(), 42.02)
  assert_eq(rect.min().y(), 116.34)
  assert_eq(rect.max().y(), 118.34)
}

///|
test "bounding_rect_of_point is degenerate" {
  let p = @type.Point::new(1.0, 2.0)
  let r = bounding_rect_of_point(p)
  assert_eq(r.width(), 0.0)
  assert_eq(r.height(), 0.0)
}

///|
test "bounding_rect_of_line_string empty" {
  let ls = @type.LineString::new([])
  assert_true(bounding_rect_of_line_string(ls) == None)
}

///|
test "signed_area_of_polygon CCW positive" {
  // Square with vertices in counter-clockwise order: positive area.
  let exterior = @type.LineString::from_tuples([
    (0.0, 0.0),
    (5.0, 0.0),
    (5.0, 6.0),
    (0.0, 6.0),
    (0.0, 0.0),
  ])
  let polygon = @type.Polygon::new(exterior, [])
  assert_eq(signed_area_of_polygon(polygon), 30.0)
  assert_eq(unsigned_area_of_polygon(polygon), 30.0)
}

///|
test "signed_area_of_polygon CW negative" {
  // Square with vertices in clockwise order: negative signed area.
  let exterior = @type.LineString::from_tuples([
    (0.0, 0.0),
    (0.0, 6.0),
    (5.0, 6.0),
    (5.0, 0.0),
    (0.0, 0.0),
  ])
  let polygon = @type.Polygon::new(exterior, [])
  assert_eq(signed_area_of_polygon(polygon), -30.0)
  assert_eq(unsigned_area_of_polygon(polygon), 30.0)
}

///|
test "signed_area_of_polygon with hole" {
  // 10x10 square with a 4x4 hole.
  let exterior = @type.LineString::from_tuples([
    (0.0, 0.0),
    (10.0, 0.0),
    (10.0, 10.0),
    (0.0, 10.0),
    (0.0, 0.0),
  ])
  let interior = @type.LineString::from_tuples([
    (3.0, 3.0),
    (7.0, 3.0),
    (7.0, 7.0),
    (3.0, 7.0),
    (3.0, 3.0),
  ])
  let polygon = @type.Polygon::new(exterior, [interior])
  assert_eq(signed_area_of_polygon(polygon), 100.0 - 16.0)
}

///|
test "signed_area_of_rect is width * height" {
  let r = @type.Rect::new(
    @type.Coord::new(0.0, 0.0),
    @type.Coord::new(3.0, 4.0),
  )
  assert_eq(signed_area_of_rect(r), 12.0)
}

///|
test "signed_area_of_triangle" {
  // Right triangle with legs 4 and 6 has area 12.
  let t = @type.Triangle::new(
    @type.Coord::new(0.0, 0.0),
    @type.Coord::new(4.0, 0.0),
    @type.Coord::new(0.0, 6.0),
  )
  assert_eq(unsigned_area_of_triangle(t), 12.0)
}

///|
test "Point/Line/LineString have zero area" {
  let p = @type.Point::new(1.0, 2.0)
  assert_eq(signed_area_of_geometry(@type.Geometry::Point(p)), 0.0)
  let l = @type.Line::from_tuples((0.0, 0.0), (1.0, 1.0))
  assert_eq(signed_area_of_geometry(@type.Geometry::Line(l)), 0.0)
  let ls = @type.LineString::from_tuples([(0.0, 0.0), (1.0, 1.0)])
  assert_eq(signed_area_of_geometry(@type.Geometry::LineString(ls)), 0.0)
}

///|
test "dimensions of basic geometries" {
  assert_true(
    dimensions_of_geometry(@type.Geometry::Point(@type.Point::new(0.0, 5.0))) ==
    Dimensions::ZeroDimensional,
  )
  let ls = @type.LineString::from_tuples([(0.0, 0.0), (5.0, 5.0), (0.0, 5.0)])
  assert_true(
    dimensions_of_geometry(@type.Geometry::LineString(ls)) ==
    Dimensions::OneDimensional,
  )
  let r = @type.Rect::new(
    @type.Coord::new(0.0, 0.0),
    @type.Coord::new(10.0, 10.0),
  )
  assert_true(
    dimensions_of_geometry(@type.Geometry::Rect(r)) ==
    Dimensions::TwoDimensional,
  )
}

///|
test "degenerate rect dimensions" {
  // Zero height: rect collapses to a horizontal segment (1D).
  let r1 = @type.Rect::new(
    @type.Coord::new(0.0, 10.0),
    @type.Coord::new(10.0, 10.0),
  )
  assert_true(dimensions_of_rect(r1) == Dimensions::OneDimensional)
  // Zero width and zero height: collapses to a single point.
  let r2 = @type.Rect::new(
    @type.Coord::new(10.0, 10.0),
    @type.Coord::new(10.0, 10.0),
  )
  assert_true(dimensions_of_rect(r2) == Dimensions::ZeroDimensional)
}

///|
test "empty multi point has Empty dimensions" {
  let mp = @type.MultiPoint::new([])
  assert_true(
    dimensions_of_geometry(@type.Geometry::MultiPoint(mp)) == Dimensions::Empty,
  )
}

///|
test "is_empty for various geometries" {
  let p = @type.Point::new(1.0, 2.0)
  assert_true(!is_empty_of_geometry(@type.Geometry::Point(p)))
  let mp_empty = @type.MultiPoint::new([])
  assert_true(is_empty_of_geometry(@type.Geometry::MultiPoint(mp_empty)))
  let ls_empty = @type.LineString::new([])
  assert_true(is_empty_of_geometry(@type.Geometry::LineString(ls_empty)))
}
