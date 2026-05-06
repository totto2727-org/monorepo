// Tests for orient.mbt.

///|
test "orient_polygon: makes exterior CCW by default" {
  // CW exterior input
  let cw_exterior = @type.LineString::from_tuples([
    (0.0, 0.0),
    (0.0, 1.0),
    (1.0, 1.0),
    (1.0, 0.0),
    (0.0, 0.0),
  ])
  let p = @type.Polygon::Polygon(cw_exterior, [])
  let oriented = orient_polygon(p, OrientDirection::Default)
  assert_true(
    winding_order(oriented.exterior()).unwrap() ==
    WindingOrder::CounterClockwise,
  )
}
