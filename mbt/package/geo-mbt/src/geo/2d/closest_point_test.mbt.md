# closest_point.mbt

Defines the `Closest` enum (the result of a closest-point query): `Intersection` if the query lies on the geometry, `SinglePoint` for a unique nearest point off the geometry, `Indeterminate` for degenerate ties. The `ClosestPoint::closest_point` trait (in `traits.mbt`) is the canonical entry point.

## Public API

- `Closest`
- `ClosestPoint` — `closest_point` (impls in traits.mbt for `Line` / `LineString` / `Polygon` / `Geometry` / etc.)

## Test

### `ClosestPoint`

#### `closest_point`

| Variable | State                                | Note                                    |  1  |  2  |  3  |
| :------- | :----------------------------------- | :-------------------------------------- | :-: | :-: | :-: |
| `target` | `Above midpoint of horizontal Line`  | `SinglePoint` at the foot of the normal |  ✓  |     |     |
| `target` | `Beyond start of Line`               | clamped to start (`SinglePoint`)        |     |  ✓  |     |
| `target` | `On the Line`                        | `Intersection`                          |     |     |  ✓  |

- Foot of normal at midpoint: `SinglePoint`

```mbt check
///|
test "ClosestPoint::closest_point - foot of normal at midpoint" {
  let l = @type.Line::from_tuples((0.0, 0.0), (10.0, 0.0))
  @test.assert_eq(
    ClosestPoint::closest_point(l, @type.Coord::Coord(5.0, 5.0)),
    Closest::SinglePoint(@type.Coord::Coord(5.0, 0.0)),
  )
}
```

- Beyond start: clamped to start

```mbt check
///|
test "ClosestPoint::closest_point - beyond start clamps to start" {
  let l = @type.Line::from_tuples((0.0, 0.0), (10.0, 0.0))
  @test.assert_eq(
    ClosestPoint::closest_point(l, @type.Coord::Coord(-5.0, 5.0)),
    Closest::SinglePoint(@type.Coord::Coord(0.0, 0.0)),
  )
}
```

- Target on the line: `Intersection`

```mbt check
///|
test "ClosestPoint::closest_point - target on line gives Intersection" {
  let l = @type.Line::from_tuples((0.0, 0.0), (10.0, 0.0))
  @test.assert_eq(
    ClosestPoint::closest_point(l, @type.Coord::Coord(5.0, 0.0)),
    Closest::Intersection(@type.Coord::Coord(5.0, 0.0)),
  )
}
```
