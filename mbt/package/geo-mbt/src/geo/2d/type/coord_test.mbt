// Tests ported from georust/geo-types geometry/coord.rs doctests.

///|
test "Coord and accessors" {
  let c = @type.Coord(1.0, 2.0)
  assert_eq(c.x(), 1.0)
  assert_eq(c.y(), 2.0)
  assert_eq(c.x_y(), (1.0, 2.0))
}

///|
test "Coord::zero" {
  let c = @type.Coord::zero()
  assert_eq(c.x(), 0.0)
  assert_eq(c.y(), 0.0)
  assert_true(c.is_zero())
}

///|
test "Coord::from_tuple round-trip" {
  let c = @type.Coord::from_tuple((40.02, 116.34))
  assert_eq(c.x_y(), (40.02, 116.34))
}

///|
test "Coord::from_array round-trip" {
  let c = @type.Coord::from_array([1.0, 2.0])
  assert_eq(c.to_array(), [1.0, 2.0])
}

///|
test "Coord neg" {
  let p = @type.Coord(1.25, 2.5)
  let q = -p
  assert_eq(q.x(), -p.x())
  assert_eq(q.y(), -p.y())
}

///|
test "Coord add" {
  let p = @type.Coord(1.25, 2.5)
  let q = @type.Coord(1.5, 2.5)
  let sum = p + q
  assert_eq(sum.x(), 2.75)
  assert_eq(sum.y(), 5.0)
}

///|
test "Coord sub" {
  let p = @type.Coord(1.5, 2.5)
  let q = @type.Coord(1.25, 2.5)
  let diff = p - q
  assert_eq(diff.x(), 0.25)
  assert_eq(diff.y(), 0.0)
}

///|
test "Coord mul scalar" {
  let p = @type.Coord(1.25, 2.5)
  let q = p.mul(4.0)
  assert_eq(q.x(), 5.0)
  assert_eq(q.y(), 10.0)
}

///|
test "Coord div scalar" {
  let p = @type.Coord(5.0, 10.0)
  let q = p.div(4.0)
  assert_eq(q.x(), 1.25)
  assert_eq(q.y(), 2.5)
}

///|
test "Coord dot" {
  let p = @type.Coord(1.0, 2.0)
  let q = @type.Coord(3.0, 4.0)
  assert_eq(p.dot(q), 11.0)
}

///|
test "Coord cross / wedge product" {
  let p = @type.Coord(1.0, 0.0)
  let q = @type.Coord(0.0, 1.0)
  assert_eq(p.cross(q), 1.0)
  assert_eq(q.cross(p), -1.0)
}

///|
test "Coord equality" {
  let a = @type.Coord(1.0, 2.0)
  let b = @type.Coord(1.0, 2.0)
  let c = @type.Coord(1.0, 3.0)
  assert_true(a == b)
  assert_true(a != c)
}

///|
test "Coord default is zero" {
  let d : @type.Coord = @type.Coord::default()
  let z = @type.Coord::zero()
  assert_true(d == z)
}
