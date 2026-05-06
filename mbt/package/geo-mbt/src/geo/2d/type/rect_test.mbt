// Tests ported from georust/geo-types geometry/rect.rs doctests.

///|
test "Rect normalises min/max" {
  let r = @type.Rect::Rect(@type.Coord(2.0, 3.0), @type.Coord(0.0, 1.0))
  assert_true(r.min() == @type.Coord(0.0, 1.0))
  assert_true(r.max() == @type.Coord(2.0, 3.0))
}

///|
test "Rect width / height" {
  let r = @type.Rect::Rect(@type.Coord(0.0, 0.0), @type.Coord(10.0, 20.0))
  assert_eq(r.width(), 10.0)
  assert_eq(r.height(), 20.0)
}

///|
test "Rect center" {
  let r = @type.Rect::Rect(@type.Coord(0.0, 0.0), @type.Coord(10.0, 20.0))
  assert_true(r.center() == @type.Coord(5.0, 10.0))
}

///|
test "Rect area" {
  let r = @type.Rect::Rect(@type.Coord(0.0, 0.0), @type.Coord(10.0, 20.0))
  assert_eq(r.area(), 200.0)
}

///|
test "Rect to_polygon has closed five-coord ring" {
  let r = @type.Rect::Rect(@type.Coord(0.0, 0.0), @type.Coord(1.0, 1.0))
  let p = r.to_polygon()
  assert_eq(p.exterior().length(), 5)
  assert_true(p.exterior().is_closed())
}

///|
test "Rect to_lines: 4 edges in CCW order from min corner" {
  let r = @type.Rect::Rect(@type.Coord(0.0, 0.0), @type.Coord(10.0, 5.0))
  let lines = r.to_lines()
  assert_eq(lines.length(), 4)
  let bl = @type.Coord(0.0, 0.0)
  let br = @type.Coord(10.0, 0.0)
  let tr = @type.Coord(10.0, 5.0)
  let tl = @type.Coord(0.0, 5.0)
  assert_true(lines[0] == @type.Line::Line(bl, br))
  assert_true(lines[1] == @type.Line::Line(br, tr))
  assert_true(lines[2] == @type.Line::Line(tr, tl))
  assert_true(lines[3] == @type.Line::Line(tl, bl))
}

///|
test "Rect to_polygon corners agree with to_lines starts" {
  let r = @type.Rect::Rect(@type.Coord(0.0, 0.0), @type.Coord(10.0, 5.0))
  let lines = r.to_lines()
  let polygon_coords = r.to_polygon().exterior().coords()
  // First 4 polygon coords are exactly the to_lines starts; coord 5 closes
  // the ring (= coord 0).
  for i = 0; i < 4; i = i + 1 {
    assert_true(polygon_coords[i] == lines[i].start())
  }
  assert_true(polygon_coords[4] == polygon_coords[0])
}
