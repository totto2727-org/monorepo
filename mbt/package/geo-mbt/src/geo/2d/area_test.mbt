// Tests for area.mbt.

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
  let polygon = @type.Polygon::Polygon(exterior, [])
  assert_eq(HasArea::signed_area(polygon), 30.0)
  assert_eq(HasArea::unsigned_area(polygon), 30.0)
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
  let polygon = @type.Polygon::Polygon(exterior, [])
  assert_eq(HasArea::signed_area(polygon), -30.0)
  assert_eq(HasArea::unsigned_area(polygon), 30.0)
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
  let polygon = @type.Polygon::Polygon(exterior, [interior])
  assert_eq(HasArea::signed_area(polygon), 100.0 - 16.0)
}

///|
test "signed_area_of_rect is width * height" {
  let r = @type.Rect::Rect(@type.Coord(0.0, 0.0), @type.Coord(3.0, 4.0))
  assert_eq(HasArea::signed_area(r), 12.0)
}

///|
test "signed_area_of_triangle" {
  // Right triangle with legs 4 and 6 has area 12.
  let t = @type.Triangle::Triangle(
    @type.Coord(0.0, 0.0),
    @type.Coord(4.0, 0.0),
    @type.Coord(0.0, 6.0),
  )
  assert_eq(HasArea::unsigned_area(t), 12.0)
}

///|
test "Point/Line/LineString have zero area" {
  let p = @type.Point::Point(1.0, 2.0)
  assert_eq(HasArea::signed_area(@type.Geometry::Point(p)), 0.0)
  let l = @type.Line::from_tuples((0.0, 0.0), (1.0, 1.0))
  assert_eq(HasArea::signed_area(@type.Geometry::Line(l)), 0.0)
  let ls = @type.LineString::from_tuples([(0.0, 0.0), (1.0, 1.0)])
  assert_eq(HasArea::signed_area(@type.Geometry::LineString(ls)), 0.0)
}
