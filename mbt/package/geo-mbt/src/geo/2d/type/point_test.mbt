// Tests ported from georust/geo-types geometry/point.rs doctests.

///|
test "Point and accessors" {
  let p = @type.Point::Point(1.234, 2.345)
  assert_eq(p.x(), 1.234)
  assert_eq(p.y(), 2.345)
  assert_eq(p.x_y(), (1.234, 2.345))
}

///|
test "Point::from_coord round-trip" {
  let c = @type.Coord(10.0, 20.0)
  let p = @type.Point::from_coord(c)
  assert_eq(p.x(), 10.0)
  assert_eq(p.y(), 20.0)
  assert_true(p.coord() == c)
}

///|
test "Point::with_x / with_y" {
  let p = @type.Point::Point(1.234, 2.345).with_x(9.876)
  assert_eq(p.x(), 9.876)
  let q = @type.Point::Point(1.234, 2.345).with_y(9.876)
  assert_eq(q.y(), 9.876)
}

///|
test "Point dot product" {
  let p = @type.Point::Point(1.5, 0.5)
  let q = @type.Point::Point(2.0, 4.5)
  assert_eq(p.dot(q), 5.25)
}

///|
test "Point cross_prod" {
  let a = @type.Point::Point(1.0, 2.0)
  let b = @type.Point::Point(3.0, 5.0)
  let c = @type.Point::Point(7.0, 12.0)
  assert_eq(a.cross_prod(b, c), 2.0)
}

///|
test "Point neg" {
  let p = -@type.Point::Point(-1.25, 2.5)
  assert_eq(p.x(), 1.25)
  assert_eq(p.y(), -2.5)
}

///|
test "Point add" {
  let p = @type.Point::Point(1.25, 2.5) + @type.Point::Point(1.5, 2.5)
  assert_eq(p.x(), 2.75)
  assert_eq(p.y(), 5.0)
}

///|
test "Point sub" {
  let p = @type.Point::Point(1.25, 3.0) - @type.Point::Point(1.5, 2.5)
  assert_eq(p.x(), -0.25)
  assert_eq(p.y(), 0.5)
}

///|
test "Point mul scalar" {
  let p = @type.Point::Point(2.0, 3.0).mul(2.0)
  assert_eq(p.x(), 4.0)
  assert_eq(p.y(), 6.0)
}

///|
test "Point div scalar" {
  let p = @type.Point::Point(4.0, 6.0).div(2.0)
  assert_eq(p.x(), 2.0)
  assert_eq(p.y(), 3.0)
}
