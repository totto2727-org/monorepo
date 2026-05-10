// Tests for incircle.mbt — ported from georust/robust unit tests.

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
