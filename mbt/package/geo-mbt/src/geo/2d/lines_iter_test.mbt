// Tests for the `LinesCarrier` trait (defined in traits.mbt).

///|
test "LinesCarrier on LineString yields n-1 segments" {
  let ls = @type.LineString::from_tuples([(0.0, 0.0), (1.0, 1.0), (2.0, 2.0)])
  let lines = LinesCarrier::lines(ls)
  assert_eq(lines.length(), 2)
}

///|
test "LinesCarrier on Rect yields 4 edges" {
  let r = @type.Rect::Rect(@type.Coord(0.0, 0.0), @type.Coord(1.0, 1.0))
  let lines = LinesCarrier::lines(r)
  assert_eq(lines.length(), 4)
}

///|
test "LinesCarrier on Geometry returns empty for Point" {
  let g = @type.Geometry::Point(@type.Point::Point(1.0, 2.0))
  assert_eq(LinesCarrier::lines(g).length(), 0)
}
