// Tests for euclidean.mbt.

///|
test "euclidean_distance_coords" {
  let a = @type.Coord(0.0, 0.0)
  let b = @type.Coord(3.0, 4.0)
  assert_eq(euclidean_distance_coords(a, b), 5.0)
}

///|
test "euclidean_length_line" {
  let l = @type.Line::from_tuples((0.0, 0.0), (3.0, 4.0))
  assert_eq(euclidean_length_line(l), 5.0)
}

///|
test "euclidean_length_line_string" {
  let ls = @type.LineString::from_tuples([(0.0, 0.0), (3.0, 0.0), (3.0, 4.0)])
  // 3 + 4 = 7
  assert_eq(euclidean_length_line_string(ls), 7.0)
}

///|
test "euclidean_distance_coord_to_line — point on segment" {
  let l = @type.Line::from_tuples((0.0, 0.0), (10.0, 0.0))
  // Point (5, 3) — perpendicular distance = 3 (projection at 5,0)
  let p = @type.Coord(5.0, 3.0)
  assert_eq(euclidean_distance_coord_to_line(p, l), 3.0)
}

///|
test "euclidean_distance_coord_to_line — point off-segment" {
  let l = @type.Line::from_tuples((0.0, 0.0), (10.0, 0.0))
  // Point (-5, 3) — closest is start (0,0); distance = sqrt(25+9) ≈ 5.831
  let p = @type.Coord(-5.0, 3.0)
  let d = euclidean_distance_coord_to_line(p, l)
  // Should equal sqrt(25+9) = sqrt(34)
  let expected = (34.0 : Double).sqrt()
  assert_true((d - expected).abs() < 1.0e-9)
}

///|
test "euclidean_destination roundtrip with bearing" {
  // From origin, heading 0 deg (east), distance 5 → (5, 0)
  let dest = euclidean_destination(@type.Coord(0.0, 0.0), 0.0, 5.0)
  assert_true((dest.x() - 5.0).abs() < 1.0e-9)
  assert_true(dest.y().abs() < 1.0e-9)
  // Heading 90 deg (north / +y), distance 5 → (0, 5)
  let dest2 = euclidean_destination(@type.Coord(0.0, 0.0), 90.0, 5.0)
  assert_true(dest2.x().abs() < 1.0e-9)
  assert_true((dest2.y() - 5.0).abs() < 1.0e-9)
}
