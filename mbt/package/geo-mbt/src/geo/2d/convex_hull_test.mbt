// Tests for convex hull.

///|
test "convex hull of triangle is itself" {
  let mp = @type.MultiPoint::from_tuples([(0.0, 0.0), (1.0, 0.0), (0.0, 1.0)])
  let hull = HasConvexHull::convex_hull(mp)
  let coords = hull.exterior().coords()
  // Hull should have 4 coords (3 unique + closing)
  assert_eq(coords.length(), 4)
}

///|
test "convex hull of points includes all corners" {
  // 5 points: 4 corners of a square + 1 inside
  let mp = @type.MultiPoint::from_tuples([
    (0.0, 0.0),
    (10.0, 0.0),
    (10.0, 10.0),
    (0.0, 10.0),
    (5.0, 5.0),
  ])
  let hull = HasConvexHull::convex_hull(mp)
  let coords = hull.exterior().coords()
  // Hull should be the 4 corners (closed = 5 coords)
  assert_eq(coords.length(), 5)
  // Each corner should appear in the hull
  let mut seen_corners = 0
  for c in coords {
    if c == @type.Coord(0.0, 0.0) ||
      c == @type.Coord(10.0, 0.0) ||
      c == @type.Coord(10.0, 10.0) ||
      c == @type.Coord(0.0, 10.0) {
      seen_corners = seen_corners + 1
    }
  }
  // 4 corners + 1 closing duplicate = 5
  assert_true(seen_corners >= 4)
}

///|
test "convex hull is closed and CCW" {
  let mp = @type.MultiPoint::from_tuples([
    (0.0, 0.0),
    (10.0, 0.0),
    (10.0, 10.0),
    (0.0, 10.0),
  ])
  let hull = HasConvexHull::convex_hull(mp)
  let exterior = hull.exterior()
  assert_true(exterior.is_closed())
  // Should be counter-clockwise (positive signed area)
  assert_true(twice_signed_ring_area(exterior) > 0.0)
}

///|
test "convex hull of single point is degenerate" {
  let mp = @type.MultiPoint::from_tuples([(5.0, 5.0)])
  let hull = HasConvexHull::convex_hull(mp)
  // For 1 point we degenerate to a 2-coord linestring (start == end)
  let coords = hull.exterior().coords()
  // Test does not enforce a specific length for degenerate case; just check
  // it does not crash and returns something.
  assert_true(coords.length() >= 2)
}
