// Tests for frechet_distance.mbt.

///|
test "frechet_distance: identical lines is 0" {
  let a = @type.LineString::from_tuples([(0.0, 0.0), (10.0, 0.0)])
  let b = @type.LineString::from_tuples([(0.0, 0.0), (10.0, 0.0)])
  assert_eq(frechet_distance(a, b), 0.0)
}

///|
test "frechet_distance: parallel translated lines" {
  let a = @type.LineString::from_tuples([(0.0, 0.0), (10.0, 0.0)])
  let b = @type.LineString::from_tuples([(0.0, 5.0), (10.0, 5.0)])
  // Parallel lines at y=0 and y=5: discrete Fréchet should be 5
  let d = frechet_distance(a, b)
  assert_true((d - 5.0).abs() < 1.0e-9)
}

///|
test "frechet_distance: empty lines" {
  let a = @type.LineString::LineString([])
  let b = @type.LineString::LineString([])
  assert_eq(frechet_distance(a, b), 0.0)
}
