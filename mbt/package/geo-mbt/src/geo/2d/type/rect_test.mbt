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

///|
test "Rect split_x: equal-width left / right halves at the midpoint" {
  let r = @type.Rect::Rect(@type.Coord(0.0, 0.0), @type.Coord(4.0, 4.0))
  let (left, right) = r.split_x()
  assert_true(
    left == @type.Rect::Rect(@type.Coord(0.0, 0.0), @type.Coord(2.0, 4.0)),
  )
  assert_true(
    right == @type.Rect::Rect(@type.Coord(2.0, 0.0), @type.Coord(4.0, 4.0)),
  )
}

///|
test "Rect split_x: shared mid-X is bit-identical on the seam" {
  let r = @type.Rect::Rect(@type.Coord(0.0, 0.0), @type.Coord(4.0, 4.0))
  let (left, right) = r.split_x()
  assert_eq(left.max().x(), right.min().x())
}

///|
test "Rect split_x: total width and full height preserved" {
  let r = @type.Rect::Rect(@type.Coord(1.0, 2.0), @type.Coord(7.0, 5.0))
  let (left, right) = r.split_x()
  assert_eq(left.width() + right.width(), r.width())
  assert_eq(left.height(), r.height())
  assert_eq(right.height(), r.height())
}

///|
test "Rect split_y: equal-height bottom / top halves at the midpoint" {
  let r = @type.Rect::Rect(@type.Coord(0.0, 0.0), @type.Coord(4.0, 4.0))
  let (bottom, top) = r.split_y()
  assert_true(
    bottom == @type.Rect::Rect(@type.Coord(0.0, 0.0), @type.Coord(4.0, 2.0)),
  )
  assert_true(
    top == @type.Rect::Rect(@type.Coord(0.0, 2.0), @type.Coord(4.0, 4.0)),
  )
}

///|
test "Rect split_y: shared mid-Y is bit-identical on the seam" {
  let r = @type.Rect::Rect(@type.Coord(0.0, 0.0), @type.Coord(4.0, 4.0))
  let (bottom, top) = r.split_y()
  assert_eq(bottom.max().y(), top.min().y())
}

///|
test "Rect split_y: total height and full width preserved" {
  let r = @type.Rect::Rect(@type.Coord(1.0, 2.0), @type.Coord(7.0, 5.0))
  let (bottom, top) = r.split_y()
  assert_eq(bottom.height() + top.height(), r.height())
  assert_eq(bottom.width(), r.width())
  assert_eq(top.width(), r.width())
}

///|
test "Rect split_x then split_y produces 4 quadrants of equal area" {
  let r = @type.Rect::Rect(@type.Coord(0.0, 0.0), @type.Coord(4.0, 4.0))
  let (left, right) = r.split_x()
  let (bottom_left, top_left) = left.split_y()
  let (bottom_right, top_right) = right.split_y()
  let total = r.area()
  assert_eq(
    bottom_left.area() +
    top_left.area() +
    bottom_right.area() +
    top_right.area(),
    total,
  )
  assert_eq(bottom_left.area(), total / 4.0)
}
