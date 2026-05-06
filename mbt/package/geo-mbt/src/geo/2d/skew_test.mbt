// Tests for skew.mbt.

///|
test "skew_geometry: shear x by 45 deg" {
  // tan(45) = 1, so (1, 1) -> (1 + 1*1, 1) = (2, 1)
  let p = @type.Geometry::Point(@type.Point::Point(1.0, 1.0))
  let sheared = skew_geometry(p, 45.0, 0.0)
  match sheared {
    @type.Geometry::Point(pt) => {
      assert_true((pt.x() - 2.0).abs() < 1.0e-9)
      assert_true((pt.y() - 1.0).abs() < 1.0e-9)
    }
    _ => abort("expected Point")
  }
}
