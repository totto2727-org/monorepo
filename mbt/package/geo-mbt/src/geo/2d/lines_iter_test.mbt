// Tests for lines_iter.mbt.

///|
test "lines_of_line_string yields n-1 segments" {
  let ls = @type.LineString::from_tuples([(0.0, 0.0), (1.0, 1.0), (2.0, 2.0)])
  let lines = lines_of_line_string(ls)
  assert_eq(lines.length(), 2)
}

///|
test "lines_of_rect yields 4 edges" {
  let r = @type.Rect::Rect(@type.Coord(0.0, 0.0), @type.Coord(1.0, 1.0))
  let lines = lines_of_rect(r)
  assert_eq(lines.length(), 4)
}

///|
test "lines_of_geometry returns empty for Point" {
  let g = @type.Geometry::Point(@type.Point::Point(1.0, 2.0))
  assert_eq(lines_of_geometry(g).length(), 0)
}
