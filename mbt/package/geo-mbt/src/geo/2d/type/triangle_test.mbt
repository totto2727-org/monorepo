// Tests ported from georust/geo-types geometry/triangle.rs doctests.

///|
test "Triangle::new and accessors" {
  let t = @type.Triangle::new(
    @type.Coord::new(0.0, 0.0),
    @type.Coord::new(10.0, 0.0),
    @type.Coord::new(0.0, 10.0),
  )
  assert_true(t.v0() == @type.Coord::new(0.0, 0.0))
  assert_true(t.v1() == @type.Coord::new(10.0, 0.0))
  assert_true(t.v2() == @type.Coord::new(0.0, 10.0))
}

///|
test "Triangle to_array" {
  let t = @type.Triangle::new(
    @type.Coord::new(0.0, 0.0),
    @type.Coord::new(10.0, 0.0),
    @type.Coord::new(0.0, 10.0),
  )
  let arr = t.to_array()
  assert_eq(arr.length(), 3)
}

///|
test "Triangle to_lines yields 3 segments" {
  let t = @type.Triangle::new(
    @type.Coord::new(0.0, 0.0),
    @type.Coord::new(10.0, 0.0),
    @type.Coord::new(0.0, 10.0),
  )
  let lines = t.to_lines()
  assert_eq(lines.length(), 3)
  assert_true(lines[0].start() == t.v0())
  assert_true(lines[0].end() == t.v1())
  assert_true(lines[2].end() == t.v0())
}

///|
test "Triangle to_polygon has 4 coords closed" {
  let t = @type.Triangle::new(
    @type.Coord::new(0.0, 0.0),
    @type.Coord::new(10.0, 0.0),
    @type.Coord::new(0.0, 10.0),
  )
  let p = t.to_polygon()
  assert_eq(p.exterior().length(), 4)
  assert_true(p.exterior().is_closed())
}
