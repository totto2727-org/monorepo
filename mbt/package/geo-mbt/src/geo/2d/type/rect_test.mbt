// Tests ported from georust/geo-types geometry/rect.rs doctests.

///|
test "Rect::new normalises min/max" {
  let r = @type.Rect::new(
    @type.Coord::new(2.0, 3.0),
    @type.Coord::new(0.0, 1.0),
  )
  assert_true(r.min() == @type.Coord::new(0.0, 1.0))
  assert_true(r.max() == @type.Coord::new(2.0, 3.0))
}

///|
test "Rect width / height" {
  let r = @type.Rect::new(
    @type.Coord::new(0.0, 0.0),
    @type.Coord::new(10.0, 20.0),
  )
  assert_eq(r.width(), 10.0)
  assert_eq(r.height(), 20.0)
}

///|
test "Rect center" {
  let r = @type.Rect::new(
    @type.Coord::new(0.0, 0.0),
    @type.Coord::new(10.0, 20.0),
  )
  assert_true(r.center() == @type.Coord::new(5.0, 10.0))
}

///|
test "Rect area" {
  let r = @type.Rect::new(
    @type.Coord::new(0.0, 0.0),
    @type.Coord::new(10.0, 20.0),
  )
  assert_eq(r.area(), 200.0)
}

///|
test "Rect to_polygon has closed five-coord ring" {
  let r = @type.Rect::new(
    @type.Coord::new(0.0, 0.0),
    @type.Coord::new(1.0, 1.0),
  )
  let p = r.to_polygon()
  assert_eq(p.exterior().length(), 5)
  assert_true(p.exterior().is_closed())
}
