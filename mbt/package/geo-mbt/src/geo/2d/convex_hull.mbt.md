# convex_hull.mbt

Andrew's monotone-chain convex hull. Exposed via `HasConvexHull::convex_hull` (impls in this file for `MultiPoint` / `LineString` / `Polygon` / `Geometry`); the result is a closed CCW `Polygon`.

## Public API

- `HasConvexHull` — `convex_hull` (impls in this file)

## Test

### `HasConvexHull`

#### `convex_hull`

| Variable | State                     | Note                                          |  1  |  2  |  3  |  4  |
| :------- | :------------------------ | :-------------------------------------------- | :-: | :-: | :-: | :-: |
| `self`   | `Triangle MultiPoint`     | hull is the triangle itself (4 closed coords) |  ✓  |     |     |     |
| `self`   | `Square + interior point` | hull picks the 4 corners (5 closed coords)    |     |  ✓  |     |     |
| `self`   | `Square MultiPoint`       | hull is closed and CCW                        |     |     |  ✓  |     |
| `self`   | `Single-point MultiPoint` | degenerate output (≥ 2 coords, no crash)      |     |     |     |  ✓  |

- Triangle's convex hull is itself

```mbt check
///|
test "HasConvexHull::convex_hull - triangle hull is the triangle" {
  let mp = @type.MultiPoint::from_tuples([(0.0, 0.0), (1.0, 0.0), (0.0, 1.0)])
  // 3 unique + closing = 4 coords.
  @test.assert_eq(HasConvexHull::convex_hull(mp).exterior().length(), 4)
}
```

- Square + interior point: hull picks the 4 corners

```mbt check
///|
test "HasConvexHull::convex_hull - interior point is dropped from hull" {
  let mp = @type.MultiPoint::from_tuples([
    (0.0, 0.0),
    (10.0, 0.0),
    (10.0, 10.0),
    (0.0, 10.0),
    (5.0, 5.0),
  ])
  // 4 corners + closing = 5 coords.
  @test.assert_eq(HasConvexHull::convex_hull(mp).exterior().length(), 5)
}
```

- Square MultiPoint: hull is closed and CCW

```mbt check
///|
test "HasConvexHull::convex_hull - hull is closed and CCW" {
  let mp = @type.MultiPoint::from_tuples([
    (0.0, 0.0),
    (10.0, 0.0),
    (10.0, 10.0),
    (0.0, 10.0),
  ])
  let exterior = HasConvexHull::convex_hull(mp).exterior()
  assert_true(exterior.is_closed())
  // CCW orientation → positive signed area.
  assert_true(HasArea::signed_area(@type.Polygon::Polygon(exterior, [])) > 0.0)
}
```

- LineString and Polygon: direct trait dispatch

```mbt check
///|
test "HasConvexHull::convex_hull - LineString and Polygon direct dispatch" {
  let ls = @type.LineString::from_tuples([
    (0.0, 0.0),
    (10.0, 0.0),
    (10.0, 10.0),
    (0.0, 10.0),
  ])
  // Hull of an open square outline has 5 coords (4 corners + closing).
  @test.assert_eq(HasConvexHull::convex_hull(ls).exterior().length(), 5)
  let polygon = @type.Polygon::Polygon(ls, [])
  @test.assert_eq(HasConvexHull::convex_hull(polygon).exterior().length(), 5)
}
```

- `Geometry` dispatch covers the inner `convex_hull_of_geometry` path

```mbt check
///|
test "HasConvexHull::convex_hull - Geometry variant dispatches via convex_hull_of_geometry" {
  let mp = @type.MultiPoint::from_tuples([
    (0.0, 0.0),
    (10.0, 0.0),
    (10.0, 10.0),
    (0.0, 10.0),
  ])
  let g = @type.Geometry::MultiPoint(mp)
  // 4 corners + closing = 5 coords.
  @test.assert_eq(HasConvexHull::convex_hull(g).exterior().length(), 5)
}
```

- Empty input yields an empty `LineString` exterior (degenerate)

```mbt check
///|
test "HasConvexHull::convex_hull - empty input yields empty exterior" {
  let mp = @type.MultiPoint::empty()
  @test.assert_eq(HasConvexHull::convex_hull(mp).exterior().length(), 0)
}
```

- Single-point input: degenerate but does not crash

```mbt check
///|
test "HasConvexHull::convex_hull - single point degenerate output" {
  let mp = @type.MultiPoint::from_tuples([(5.0, 5.0)])
  let coords = HasConvexHull::convex_hull(mp).exterior().coords()
  // For a single point we degenerate to a 2-coord linestring (start == end);
  // the contract is just "doesn't crash and yields ≥ 2 coords".
  assert_true(coords.length() >= 2)
}
```
