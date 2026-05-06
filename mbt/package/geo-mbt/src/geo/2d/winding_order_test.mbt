// Tests for winding_order.mbt.

///|
test "winding_order: CCW positive area" {
  let ls = @type.LineString::from_tuples([
    (0.0, 0.0),
    (1.0, 0.0),
    (1.0, 1.0),
    (0.0, 1.0),
    (0.0, 0.0),
  ])
  assert_true(winding_order(ls).unwrap() == WindingOrder::CounterClockwise)
}

///|
test "winding_order: CW negative area" {
  let ls = @type.LineString::from_tuples([
    (0.0, 0.0),
    (0.0, 1.0),
    (1.0, 1.0),
    (1.0, 0.0),
    (0.0, 0.0),
  ])
  assert_true(winding_order(ls).unwrap() == WindingOrder::Clockwise)
}

///|
test "reverse_line_string" {
  let ls = @type.LineString::from_tuples([(0.0, 0.0), (1.0, 0.0), (1.0, 1.0)])
  let rev = reverse_line_string(ls)
  let coords = rev.coords()
  assert_true(coords[0] == @type.Coord(1.0, 1.0))
  assert_true(coords[2] == @type.Coord(0.0, 0.0))
}
