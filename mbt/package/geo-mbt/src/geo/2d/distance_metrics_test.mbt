// Tests for frechet, hausdorff, densify.

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

///|
test "hausdorff_distance: identical sets is 0" {
  let coords = [@type.Coord(0.0, 0.0), @type.Coord(1.0, 1.0)]
  assert_eq(hausdorff_distance_coords(coords, coords), 0.0)
}

///|
test "hausdorff_distance: known case" {
  let a = [@type.Coord(0.0, 0.0), @type.Coord(0.0, 10.0)]
  let b = [@type.Coord(5.0, 5.0)]
  // From a to b: max(min) = max(sqrt(50), sqrt(50)) = sqrt(50)
  // From b to a: max(min) = sqrt(50)
  // So Hausdorff = sqrt(50) ≈ 7.07
  let d = hausdorff_distance_coords(a, b)
  let expected = (50.0 : Double).sqrt()
  assert_true((d - expected).abs() < 1.0e-9)
}

///|
test "densify_line_string: long segment gets split" {
  let ls = @type.LineString::from_tuples([(0.0, 0.0), (10.0, 0.0)])
  // max_segment_length = 5 → 1 segment of 10 → split into 2 of 5 each → 3 coords total
  let densified = densify_line_string(ls, 5.0)
  assert_eq(densified.coords().length(), 3)
  // Middle coord should be exactly halfway
  assert_true(densified.coords()[1] == @type.Coord(5.0, 0.0))
}

///|
test "densify_line_string: short segment unchanged" {
  let ls = @type.LineString::from_tuples([(0.0, 0.0), (3.0, 0.0)])
  let densified = densify_line_string(ls, 5.0)
  assert_eq(densified.coords().length(), 2)
}
