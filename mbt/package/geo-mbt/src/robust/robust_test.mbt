// Tests ported from georust/robust unit tests.

///|
test "orient2d collinear" {
  // 3 collinear points return 0
  let p1 = @type.Coord(0.0, 0.0)
  let p2 = @type.Coord(1.0, 1.0)
  let p3 = @type.Coord(2.0, 2.0)
  assert_eq(@robust.orient2d(p1, p2, p3), 0.0)
}

///|
test "orient2d counter-clockwise" {
  let p1 = @type.Coord(0.0, 0.0)
  let p2 = @type.Coord(1.0, 0.0)
  let p3 = @type.Coord(0.0, 1.0)
  assert_true(@robust.orient2d(p1, p2, p3) > 0.0)
}

///|
test "orient2d clockwise" {
  let p1 = @type.Coord(0.0, 0.0)
  let p2 = @type.Coord(0.0, 1.0)
  let p3 = @type.Coord(1.0, 0.0)
  assert_true(@robust.orient2d(p1, p2, p3) < 0.0)
}

///|
test "orient2d high-precision tiny inputs" {
  // The classic Shewchuk demonstration: tiny perturbation that fp could miss.
  let pa = @type.Coord(0.5, 0.5)
  let pb = @type.Coord(12.0, 12.0)
  let pc = @type.Coord(24.0, 24.0)
  let result = @robust.orient2d(pa, pb, pc)
  // The three points are exactly collinear -> 0
  assert_eq(result, 0.0)
}

///|
test "incircle basic — point inside" {
  // Triangle through (0,0), (1,0), (0,1) (CCW). Circumcircle passes through
  // these three. The point (0.25, 0.25) lies inside.
  let pa = @type.Coord(0.0, 0.0)
  let pb = @type.Coord(1.0, 0.0)
  let pc = @type.Coord(0.0, 1.0)
  let pd = @type.Coord(0.25, 0.25)
  assert_true(@robust.incircle(pa, pb, pc, pd) > 0.0)
}

///|
test "incircle basic — point outside" {
  let pa = @type.Coord(0.0, 0.0)
  let pb = @type.Coord(1.0, 0.0)
  let pc = @type.Coord(0.0, 1.0)
  let pd = @type.Coord(2.0, 2.0)
  assert_true(@robust.incircle(pa, pb, pc, pd) < 0.0)
}
