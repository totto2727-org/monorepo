# property tests

Cross-cutting invariant / property-style tests that span multiple algorithms. Modelled on the spirit of Rust geo's `fuzz/` and unit tests, these check geometric invariants that should hold regardless of input — using a few representative inputs each.

This file is **not** tied to a single source file; it covers properties whose statement involves more than one algorithm working together (e.g. "centroid lies inside its convex polygon" couples `HasCentroid::centroid` with `CoordPositionFor::coord_position`).

## Test

### `property: signed_area flips sign under coord reversal`

```mbt check
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
  @test.assert_eq(
    HasArea::signed_area(@type.Polygon::Polygon(exterior_ccw, [])),
    -HasArea::signed_area(@type.Polygon::Polygon(exterior_cw, [])),
  )
}
```

### `property: centroid lies inside (or on boundary of) its convex polygon`

```mbt check
///|
test "property: centroid lies inside or on boundary of convex polygon" {
  let p = @type.Polygon::Polygon(
    @type.LineString::from_tuples([
      (0.0, 0.0),
      (10.0, 0.0),
      (10.0, 10.0),
      (0.0, 10.0),
      (0.0, 0.0),
    ]),
    [],
  )
  let c = match HasCentroid::centroid(p) {
    Some(c) => c
    None => abort("expected centroid for convex polygon")
  }
  let pos = CoordPositionFor::coord_position(p, c.coord())
  assert_true(pos == CoordPos::Inside || pos == CoordPos::OnBoundary)
}
```

### `property: bounding rect contains every coord of the geometry`

```mbt check
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
  let bbox = match Bounded::bbox(mp) {
    Some(r) => r
    None => abort("expected bounding rect for non-empty MultiPoint")
  }
  for tuple in coords_input {
    let c = @type.Coord::Coord(tuple.0, tuple.1)
    assert_true(c.x() >= bbox.min().x() && c.x() <= bbox.max().x())
    assert_true(c.y() >= bbox.min().y() && c.y() <= bbox.max().y())
  }
}
```

### `property: convex hull of n points is convex`

```mbt check
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
  assert_true(is_convex(HasConvexHull::convex_hull(mp).exterior()))
}
```

### `property: translate is invertible`

```mbt check
///|
test "property: translate is invertible" {
  let g = @type.Geometry::Point(@type.Point::Point(3.0, 4.0))
  let restored = translate_geometry(
    translate_geometry(g, 10.0, -5.0),
    -10.0,
    5.0,
  )
  let pt = try! restored.try_into_point()
  assert_true((pt.x() - 3.0).abs() < TOLERANCE)
  assert_true((pt.y() - 4.0).abs() < TOLERANCE)
}
```

### `property: simplify preserves first and last coord`

```mbt check
///|
test "property: simplify preserves first and last coord" {
  let ls = @type.LineString::from_tuples([
    (0.0, 0.0),
    (1.0, 0.001),
    (2.0, 0.002),
    (3.0, 0.001),
    (10.0, 0.0),
  ])
  let simplified_coords = Simplify::simplify(ls, 1.0).coords()
  let original_coords = ls.coords()
  @test.assert_eq(simplified_coords[0], original_coords[0])
  @test.assert_eq(
    simplified_coords[simplified_coords.length() - 1],
    original_coords[original_coords.length() - 1],
  )
}
```

### `property: line_locate ∘ line_interpolate ≈ id`

```mbt check
///|
test "property: line_locate after line_interpolate is approximately identity" {
  let l = @type.Line::from_tuples((0.0, 0.0), (10.0, 10.0))
  for f in [0.0, 0.1, 0.25, 0.5, 0.75, 0.9, 1.0] {
    let p = line_interpolate_point(l, f)
    let f2 = match line_locate_point(l, p.coord()) {
      Some(f2) => f2
      None => abort("expected Some(fraction) for non-degenerate line")
    }
    assert_true((f - f2).abs() < TOLERANCE)
  }
}
```

### `property: orient_polygon is idempotent`

```mbt check
///|
test "property: orient_polygon is idempotent" {
  let p = @type.Polygon::Polygon(
    @type.LineString::from_tuples([
      (0.0, 0.0),
      (1.0, 0.0),
      (1.0, 1.0),
      (0.0, 1.0),
      (0.0, 0.0),
    ]),
    [],
  )
  let oriented_once = Orient::orient(p, OrientDirection::Default)
  let oriented_twice = Orient::orient(oriented_once, OrientDirection::Default)
  @test.assert_eq(
    oriented_once.exterior().coords(),
    oriented_twice.exterior().coords(),
  )
}
```

### `property: hausdorff_distance is symmetric`

```mbt check
///|
test "property: hausdorff_distance is symmetric" {
  let a = [
    @type.Coord::Coord(0.0, 0.0),
    @type.Coord::Coord(1.0, 1.0),
    @type.Coord::Coord(2.0, 0.0),
  ]
  let b = [@type.Coord::Coord(5.0, 5.0), @type.Coord::Coord(6.0, 6.0)]
  @test.assert_eq(
    hausdorff_distance_coords(a, b),
    hausdorff_distance_coords(b, a),
  )
}
```

### `property: frechet_distance ≥ euclidean_distance of endpoints`

```mbt check
///|
test "property: frechet_distance is at least the endpoint distance" {
  let a = @type.LineString::from_tuples([(0.0, 0.0), (10.0, 10.0)])
  let b = @type.LineString::from_tuples([(0.0, 5.0), (10.0, 15.0)])
  let endpoint_dist = euclidean_distance_coords(
    @type.Coord::Coord(0.0, 0.0),
    @type.Coord::Coord(0.0, 5.0),
  )
  assert_true(frechet_distance(a, b) >= endpoint_dist - TOLERANCE)
}
```

### `property: scale preserves shape (area scales by factor²)`

```mbt check
///|
test "property: scale by factor f scales area by f²" {
  let p = @type.Polygon::Polygon(
    @type.LineString::from_tuples([
      (0.0, 0.0),
      (4.0, 0.0),
      (4.0, 3.0),
      (0.0, 3.0),
      (0.0, 0.0),
    ]),
    [],
  )
  let original_area = HasArea::unsigned_area(p)
  let scaled = try! scale_geometry_around(
    @type.Geometry::Polygon(p),
    2.0,
    2.0,
    @type.Coord::Coord(0.0, 0.0),
  ).try_into_polygon()
  let scaled_area = HasArea::unsigned_area(scaled)
  // Area scales by factor² = 4.
  assert_true((scaled_area - original_area * 4.0).abs() < TOLERANCE)
}
```
