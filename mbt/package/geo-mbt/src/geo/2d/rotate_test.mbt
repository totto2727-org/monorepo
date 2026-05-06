// Tests for rotate.mbt.

///|
test "rotate_geometry_around: pivot at origin, square 180" {
  // Rotate the unit square 180 degrees around origin: (1,0) -> (-1,0)
  let exterior = @type.LineString::from_tuples([
    (0.0, 0.0),
    (1.0, 0.0),
    (1.0, 1.0),
    (0.0, 1.0),
  ])
  let polygon = @type.Polygon::Polygon(exterior, [])
  let rotated = rotate_geometry_around(
    @type.Geometry::Polygon(polygon),
    180.0,
    @type.Coord(0.0, 0.0),
  )
  match rotated {
    @type.Geometry::Polygon(p) => {
      let coords = p.exterior().coords()
      assert_true((coords[1].x() - -1.0).abs() < 1.0e-9)
      assert_true(coords[1].y().abs() < 1.0e-9)
    }
    _ => abort("expected Polygon")
  }
}
