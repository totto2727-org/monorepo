// Property-style invariant tests, modelled on the spirit of Rust geo's
// `fuzz/` and unit tests. These check geometric invariants across the
// algorithm surface using a few representative inputs:
//
// 1. signed_area inversion under coord reversal
// 2. centroid is inside its (convex) polygon
// 3. bounding rect contains all coords
// 4. convex hull is convex
// 5. translate then translate back is identity
// 6. simplify preserves first/last endpoints
// 7. line_locate_point composed with line_interpolate_point is approx identity
// 8. orient_polygon idempotence

///|
test "property: signed_area flips sign when coords are reversed" {
  let exterior_ccw = @type.LineString::from_tuples([
    (0.0, 0.0),
    (5.0, 0.0),
    (5.0, 6.0),
    (0.0, 6.0),
    (0.0, 0.0),
  ])
  let exterior_cw = reverse_line_string(exterior_ccw)
  let p_ccw = @type.Polygon::Polygon(exterior_ccw, [])
  let p_cw = @type.Polygon::Polygon(exterior_cw, [])
  assert_eq(HasArea::signed_area(p_ccw), -HasArea::signed_area(p_cw))
}

///|
test "property: centroid is inside (or on boundary of) convex polygon" {
  let exterior = @type.LineString::from_tuples([
    (0.0, 0.0),
    (10.0, 0.0),
    (10.0, 10.0),
    (0.0, 10.0),
    (0.0, 0.0),
  ])
  let p = @type.Polygon::Polygon(exterior, [])
  let c = HasCentroid::centroid(p).unwrap()
  let pos = CoordPositionFor::coord_position(p, c.coord())
  let inside_or_boundary = match pos {
    Inside => true
    OnBoundary => true
    Outside => false
  }
  assert_true(inside_or_boundary)
}

///|
test "property: bounding rect contains every coord of the geometry" {
  let coords_input = [
    (1.5, 2.5),
    (3.0, -1.0),
    (-2.0, 4.0),
    (5.5, 0.0),
    (0.0, 7.0),
  ]
  let mp = @type.MultiPoint::from_tuples(coords_input)
  let bbox = Bounded::bbox(mp).unwrap()
  for tuple in coords_input {
    let c = @type.Coord(tuple.0, tuple.1)
    assert_true(c.x() >= bbox.min().x() && c.x() <= bbox.max().x())
    assert_true(c.y() >= bbox.min().y() && c.y() <= bbox.max().y())
  }
}

///|
test "property: convex hull of n points is convex" {
  let mp = @type.MultiPoint::from_tuples([
    (0.0, 0.0),
    (10.0, 0.0),
    (10.0, 10.0),
    (0.0, 10.0),
    (5.0, 5.0),
    (3.0, 7.0),
    (7.0, 3.0),
  ])
  let hull = HasConvexHull::convex_hull(mp)
  assert_true(is_convex(hull.exterior()))
}

///|
test "property: translate is invertible" {
  let p = @type.Geometry::Point(@type.Point::Point(3.0, 4.0))
  let translated = translate_geometry(p, 10.0, -5.0)
  let restored = translate_geometry(translated, -10.0, 5.0)
  match restored {
    @type.Geometry::Point(pt) => {
      assert_true((pt.x() - 3.0).abs() < 1.0e-9)
      assert_true((pt.y() - 4.0).abs() < 1.0e-9)
    }
    _ => abort("expected Point")
  }
}

///|
test "property: simplify preserves first and last coord" {
  let ls = @type.LineString::from_tuples([
    (0.0, 0.0),
    (1.0, 0.001),
    (2.0, 0.002),
    (3.0, 0.001),
    (10.0, 0.0),
  ])
  let simplified = Simplify::simplify(ls, 1.0)
  let original = ls.coords()
  let simplified_coords = simplified.coords()
  assert_true(simplified_coords[0] == original[0])
  assert_true(
    simplified_coords[simplified_coords.length() - 1] ==
    original[original.length() - 1],
  )
}

///|
test "property: line_locate ∘ line_interpolate ≈ id" {
  let l = @type.Line::from_tuples((0.0, 0.0), (10.0, 10.0))
  let fractions = [0.0, 0.1, 0.25, 0.5, 0.75, 0.9, 1.0]
  for f in fractions {
    let p = line_interpolate_point(l, f)
    let f2 = line_locate_point(l, p.coord()).unwrap()
    assert_true((f - f2).abs() < 1.0e-9)
  }
}

///|
test "property: orient_polygon is idempotent" {
  let exterior = @type.LineString::from_tuples([
    (0.0, 0.0),
    (1.0, 0.0),
    (1.0, 1.0),
    (0.0, 1.0),
    (0.0, 0.0),
  ])
  let p = @type.Polygon::Polygon(exterior, [])
  let oriented_once = orient_polygon(p, OrientDirection::Default)
  let oriented_twice = orient_polygon(oriented_once, OrientDirection::Default)
  // Coords of both should match exactly
  let c1 = oriented_once.exterior().coords()
  let c2 = oriented_twice.exterior().coords()
  assert_eq(c1.length(), c2.length())
  for i = 0; i < c1.length(); i = i + 1 {
    assert_true(c1[i] == c2[i])
  }
}

///|
test "property: hausdorff_distance is symmetric" {
  let a = [@type.Coord(0.0, 0.0), @type.Coord(1.0, 1.0), @type.Coord(2.0, 0.0)]
  let b = [@type.Coord(5.0, 5.0), @type.Coord(6.0, 6.0)]
  let d_ab = hausdorff_distance_coords(a, b)
  let d_ba = hausdorff_distance_coords(b, a)
  assert_eq(d_ab, d_ba)
}

///|
test "property: frechet_distance >= euclidean_distance of endpoints" {
  let a = @type.LineString::from_tuples([(0.0, 0.0), (10.0, 10.0)])
  let b = @type.LineString::from_tuples([(0.0, 5.0), (10.0, 15.0)])
  let frechet = frechet_distance(a, b)
  let endpoint_dist = euclidean_distance_coords(
    @type.Coord(0.0, 0.0),
    @type.Coord(0.0, 5.0),
  )
  assert_true(frechet >= endpoint_dist - 1.0e-9)
}

///|
test "property: scale preserves shape (area scales by factor squared)" {
  let exterior = @type.LineString::from_tuples([
    (0.0, 0.0),
    (4.0, 0.0),
    (4.0, 3.0),
    (0.0, 3.0),
    (0.0, 0.0),
  ])
  let p = @type.Polygon::Polygon(exterior, [])
  let original_area = HasArea::unsigned_area(p)
  let scaled = scale_geometry_around(
    @type.Geometry::Polygon(p),
    2.0,
    2.0,
    @type.Coord(0.0, 0.0),
  )
  match scaled {
    @type.Geometry::Polygon(sp) => {
      let scaled_area = HasArea::unsigned_area(sp)
      // Area scales by factor² = 4
      assert_true((scaled_area - original_area * 4.0).abs() < 1.0e-9)
    }
    _ => abort("expected Polygon")
  }
}
