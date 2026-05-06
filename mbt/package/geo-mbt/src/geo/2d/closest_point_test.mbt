// Tests for closest_point.mbt.

///|
test "closest_point_on_line: midpoint" {
  let l = @type.Line::from_tuples((0.0, 0.0), (10.0, 0.0))
  let result = closest_point_on_line(l, @type.Coord(5.0, 5.0))
  match result {
    SinglePoint(c) => assert_true(c == @type.Coord(5.0, 0.0))
    _ => abort("expected SinglePoint")
  }
}

///|
test "closest_point_on_line: clamped to start" {
  let l = @type.Line::from_tuples((0.0, 0.0), (10.0, 0.0))
  let result = closest_point_on_line(l, @type.Coord(-5.0, 5.0))
  match result {
    SinglePoint(c) => assert_true(c == @type.Coord(0.0, 0.0))
    _ => abort("expected SinglePoint")
  }
}

///|
test "closest_point_on_line: target on line" {
  let l = @type.Line::from_tuples((0.0, 0.0), (10.0, 0.0))
  let result = closest_point_on_line(l, @type.Coord(5.0, 0.0))
  match result {
    Intersection(c) => assert_true(c == @type.Coord(5.0, 0.0))
    _ => abort("expected Intersection")
  }
}
