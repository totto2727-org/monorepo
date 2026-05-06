// Tests for affine_transform.mbt.

///|
test "AffineTransform::identity" {
  let t = AffineTransform::identity()
  let p = t.apply(@type.Coord(3.0, 4.0))
  assert_true(p == @type.Coord(3.0, 4.0))
}

///|
test "AffineTransform::translate_xy" {
  let t = AffineTransform::translate_xy(1.0, 2.0)
  let p = t.apply(@type.Coord(0.0, 0.0))
  assert_true(p == @type.Coord(1.0, 2.0))
}

///|
test "AffineTransform::scale_xy" {
  let t = AffineTransform::scale_xy(2.0, 3.0)
  let p = t.apply(@type.Coord(1.0, 1.0))
  assert_true(p == @type.Coord(2.0, 3.0))
}

///|
test "AffineTransform::rotate_origin 90 degrees" {
  // Rotating (1, 0) by 90 deg CCW gives (0, 1)
  let t = AffineTransform::rotate_origin(90.0)
  let p = t.apply(@type.Coord(1.0, 0.0))
  assert_true(p.x().abs() < 1.0e-9)
  assert_true((p.y() - 1.0).abs() < 1.0e-9)
}

///|
test "AffineTransform::compose: translate then scale" {
  // First translate by (1,1), then scale by 2: (0,0) -> (1,1) -> (2,2)
  let t1 = AffineTransform::translate_xy(1.0, 1.0)
  let t2 = AffineTransform::scale_xy(2.0, 2.0)
  let combined = t1.compose(t2)
  let p = combined.apply(@type.Coord(0.0, 0.0))
  assert_eq(p.x(), 2.0)
  assert_eq(p.y(), 2.0)
}
