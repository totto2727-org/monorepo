// Tests for the `ClosestPoint` trait (defined in traits.mbt).

///|
test "ClosestPoint on Line: midpoint" {
  let l = @type.Line::from_tuples((0.0, 0.0), (10.0, 0.0))
  let result = ClosestPoint::closest_point(l, @type.Coord(5.0, 5.0))
  match result {
    SinglePoint(c) => assert_true(c == @type.Coord(5.0, 0.0))
    _ => abort("expected SinglePoint")
  }
}

///|
test "ClosestPoint on Line: clamped to start" {
  let l = @type.Line::from_tuples((0.0, 0.0), (10.0, 0.0))
  let result = ClosestPoint::closest_point(l, @type.Coord(-5.0, 5.0))
  match result {
    SinglePoint(c) => assert_true(c == @type.Coord(0.0, 0.0))
    _ => abort("expected SinglePoint")
  }
}

///|
test "ClosestPoint on Line: target on line" {
  let l = @type.Line::from_tuples((0.0, 0.0), (10.0, 0.0))
  let result = ClosestPoint::closest_point(l, @type.Coord(5.0, 0.0))
  match result {
    Intersection(c) => assert_true(c == @type.Coord(5.0, 0.0))
    _ => abort("expected Intersection")
  }
}
