// Tests for scale.mbt.

///|
test "scale_geometry_around: 2x around origin" {
  let p = @type.Geometry::Point(@type.Point::Point(1.0, 2.0))
  let scaled = scale_geometry_around(p, 2.0, 2.0, @type.Coord(0.0, 0.0))
  match scaled {
    @type.Geometry::Point(pt) => {
      assert_eq(pt.x(), 2.0)
      assert_eq(pt.y(), 4.0)
    }
    _ => abort("expected Point")
  }
}
