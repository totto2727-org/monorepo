// Tests for hausdorff_distance.mbt.

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
