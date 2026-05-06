// Tests for vector_ops.mbt.

///|
test "magnitude" {
  let c = @type.Coord(3.0, 4.0)
  assert_eq(magnitude(c), 5.0)
  assert_eq(magnitude_squared(c), 25.0)
}

///|
test "left / right rotation" {
  let c = @type.Coord(1.0, 0.0)
  assert_true(left(c) == @type.Coord(0.0, 1.0))
  assert_true(right(c) == @type.Coord(0.0, -1.0))
}

///|
test "dot_product / wedge_product" {
  let a = @type.Coord(1.0, 2.0)
  let b = @type.Coord(3.0, 4.0)
  assert_eq(dot_product(a, b), 11.0)
  assert_eq(wedge_product(a, b), -2.0)
}

///|
test "is_finite" {
  assert_true(is_finite(@type.Coord(0.0, 0.0)))
  assert_true(!is_finite(@type.Coord(0.0 / 0.0, 0.0))) // NaN
  assert_true(!is_finite(@type.Coord(1.0 / 0.0, 0.0))) // Inf
}

///|
test "try_normalize" {
  let c = @type.Coord(3.0, 4.0)
  let n = try_normalize(c).unwrap()
  // 3/5 = 0.6, 4/5 = 0.8
  assert_eq(n.x(), 0.6)
  assert_eq(n.y(), 0.8)
}

///|
test "try_normalize zero vector returns None" {
  let c = @type.Coord(0.0, 0.0)
  assert_true(try_normalize(c) == None)
}
