// Tests for affine transforms.

///|
test "AffineTransform::identity" {
  let t = AffineTransform::identity()
  let p = t.apply(@type.Coord::new(3.0, 4.0))
  assert_true(p == @type.Coord::new(3.0, 4.0))
}

///|
test "AffineTransform::translate_xy" {
  let t = AffineTransform::translate_xy(1.0, 2.0)
  let p = t.apply(@type.Coord::new(0.0, 0.0))
  assert_true(p == @type.Coord::new(1.0, 2.0))
}

///|
test "AffineTransform::scale_xy" {
  let t = AffineTransform::scale_xy(2.0, 3.0)
  let p = t.apply(@type.Coord::new(1.0, 1.0))
  assert_true(p == @type.Coord::new(2.0, 3.0))
}

///|
test "AffineTransform::rotate_origin 90 degrees" {
  // Rotating (1, 0) by 90 deg CCW gives (0, 1)
  let t = AffineTransform::rotate_origin(90.0)
  let p = t.apply(@type.Coord::new(1.0, 0.0))
  assert_true(p.x().abs() < 1.0e-9)
  assert_true((p.y() - 1.0).abs() < 1.0e-9)
}

///|
test "translate_polygon shifts all coords" {
  let exterior = @type.LineString::from_tuples([
    (0.0, 0.0),
    (1.0, 0.0),
    (1.0, 1.0),
    (0.0, 1.0),
  ])
  let polygon = @type.Polygon::new(exterior, [])
  let translated = translate_polygon(polygon, 10.0, 20.0)
  let coords = translated.exterior().coords()
  assert_true(coords[0] == @type.Coord::new(10.0, 20.0))
  assert_true(coords[1] == @type.Coord::new(11.0, 20.0))
  assert_true(coords[2] == @type.Coord::new(11.0, 21.0))
}

///|
test "rotate_geometry_around: pivot at origin, square 180" {
  // Rotate the unit square 180 degrees around origin: (1,0) -> (-1,0)
  let exterior = @type.LineString::from_tuples([
    (0.0, 0.0),
    (1.0, 0.0),
    (1.0, 1.0),
    (0.0, 1.0),
  ])
  let polygon = @type.Polygon::new(exterior, [])
  let rotated = rotate_geometry_around(
    @type.Geometry::Polygon(polygon),
    180.0,
    @type.Coord::new(0.0, 0.0),
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

///|
test "scale_geometry_around: 2x around origin" {
  let p = @type.Geometry::Point(@type.Point::new(1.0, 2.0))
  let scaled = scale_geometry_around(
    p,
    2.0,
    2.0,
    @type.Coord::new(0.0, 0.0),
  )
  match scaled {
    @type.Geometry::Point(pt) => {
      assert_eq(pt.x(), 2.0)
      assert_eq(pt.y(), 4.0)
    }
    _ => abort("expected Point")
  }
}

///|
test "AffineTransform composition: translate then scale" {
  // First translate by (1,1), then scale by 2: (0,0) -> (1,1) -> (2,2)
  let t1 = AffineTransform::translate_xy(1.0, 1.0)
  let t2 = AffineTransform::scale_xy(2.0, 2.0)
  let combined = t1.compose(t2)
  let p = combined.apply(@type.Coord::new(0.0, 0.0))
  assert_eq(p.x(), 2.0)
  assert_eq(p.y(), 2.0)
}

///|
test "skew_geometry: shear x by 45 deg" {
  // tan(45) = 1, so (1, 1) -> (1 + 1*1, 1) = (2, 1)
  let p = @type.Geometry::Point(@type.Point::new(1.0, 1.0))
  let sheared = skew_geometry(p, 45.0, 0.0)
  match sheared {
    @type.Geometry::Point(pt) => {
      assert_true((pt.x() - 2.0).abs() < 1.0e-9)
      assert_true((pt.y() - 1.0).abs() < 1.0e-9)
    }
    _ => abort("expected Point")
  }
}
