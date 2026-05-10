// Whitebox tests for the package-private `twice_signed_ring_area` helper in
// `area.mbt`. The function is the shoelace primitive shared by
// `linestring_signed_area` (private, same file) and `winding_order` (in
// `winding_order.mbt`). The tests live in a `_wbtest.mbt` file because
// `twice_signed_ring_area` is intentionally not part of the public API
// (no caller outside the `geo/2d` package needs it).

///|
test "twice_signed_ring_area - closed CCW square" {
  let ls = @type.LineString::from_tuples([
    (0.0, 0.0),
    (5.0, 0.0),
    (5.0, 6.0),
    (0.0, 6.0),
    (0.0, 0.0),
  ])
  assert_eq(twice_signed_ring_area(ls), 60.0)
}

///|
test "twice_signed_ring_area - closed CW square is negative" {
  let ls = @type.LineString::from_tuples([
    (0.0, 0.0),
    (0.0, 6.0),
    (5.0, 6.0),
    (5.0, 0.0),
    (0.0, 0.0),
  ])
  assert_eq(twice_signed_ring_area(ls), -60.0)
}

///|
test "twice_signed_ring_area - open ring returns zero" {
  let ls = @type.LineString::from_tuples([
    (0.0, 0.0),
    (5.0, 0.0),
    (5.0, 6.0),
    (0.0, 6.0),
  ])
  assert_eq(twice_signed_ring_area(ls), 0.0)
}

///|
test "twice_signed_ring_area - fewer than 3 coords returns zero" {
  let ls = @type.LineString::from_tuples([(0.0, 0.0), (1.0, 1.0)])
  assert_eq(twice_signed_ring_area(ls), 0.0)
}
