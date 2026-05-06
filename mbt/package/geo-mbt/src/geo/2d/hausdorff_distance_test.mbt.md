# hausdorff_distance.mbt

Hausdorff distance between two coordinate sets, lifted to whole geometries via their full coord arrays. Returns `+∞` when either set is empty.

## Public API

- `hausdorff_distance_coords`
- `hausdorff_distance_geometry`

## Test

### `hausdorff_distance_coords`

| Variable | State                  | Note                              |  1  |  2  |
| :------- | :--------------------- | :-------------------------------- | :-: | :-: |
| `a`/`b`  | `Identical`            | distance is 0                     |  ✓  |     |
| `a`/`b`  | `Disjoint, both finite`| max(min) in either direction      |     |  ✓  |

- Identical sets give distance 0

```mbt check
///|
test "hausdorff_distance_coords - identical sets give 0" {
  let coords = [@type.Coord::Coord(0.0, 0.0), @type.Coord::Coord(1.0, 1.0)]
  @test.assert_eq(hausdorff_distance_coords(coords, coords), 0.0)
}
```

- Two-vs-one set: max-min is `√50`

```mbt check
///|
test "hausdorff_distance_coords - 2 vs 1 corners gives sqrt 50" {
  let a = [@type.Coord::Coord(0.0, 0.0), @type.Coord::Coord(0.0, 10.0)]
  let b = [@type.Coord::Coord(5.0, 5.0)]
  let d = hausdorff_distance_coords(a, b)
  let expected = (50.0 : Double).sqrt()
  assert_true((d - expected).abs() < 1.0e-9)
}
```

### `hausdorff_distance_geometry`

- Two coincident points have distance 0

```mbt check
///|
test "hausdorff_distance_geometry - coincident points give 0" {
  let p = @type.Geometry::Point(@type.Point::Point(3.0, 4.0))
  @test.assert_eq(hausdorff_distance_geometry(p, p), 0.0)
}
```
