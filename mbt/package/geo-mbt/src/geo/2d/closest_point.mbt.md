# closest_point.mbt

Defines the `Closest` enum (the result of a closest-point query): `Intersection` if the query lies on the geometry, `SinglePoint` for a unique nearest point off the geometry, `Indeterminate` for degenerate ties. The `ClosestPoint::closest_point` trait is the canonical entry point.

## Public API

- `Closest`
- `ClosestPoint` — `closest_point` (impls in this file)

## Test

### `ClosestPoint`

#### `closest_point`

| Variable | State                               | Note                                    |  1  |  2  |  3  |
| :------- | :---------------------------------- | :-------------------------------------- | :-: | :-: | :-: |
| `target` | `Above midpoint of horizontal Line` | `SinglePoint` at the foot of the normal |  ✓  |     |     |
| `target` | `Beyond start of Line`              | clamped to start (`SinglePoint`)        |     |  ✓  |     |
| `target` | `On the Line`                       | `Intersection`                          |     |     |  ✓  |

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

- LineString direct dispatch and degenerate / multi-segment cases

```mbt check
///|
test "ClosestPoint::closest_point - LineString empty / single / multi-segment" {
  // Empty LineString → Indeterminate.
  @test.assert_eq(
    ClosestPoint::closest_point(
      @type.LineString::empty(),
      @type.Coord::Coord(0.0, 0.0),
    ),
    Closest::Indeterminate,
  )
  // Multi-segment LineString picks the closer segment, exercising the
  // SinglePoint vs SinglePoint comparison branch.
  let ls = @type.LineString::from_tuples([(0.0, 0.0), (10.0, 0.0), (10.0, 10.0)])
  @test.assert_eq(
    ClosestPoint::closest_point(ls, @type.Coord::Coord(5.0, -1.0)),
    Closest::SinglePoint(@type.Coord::Coord(5.0, 0.0)),
  )
  // Target on the LineString → Intersection.
  @test.assert_eq(
    ClosestPoint::closest_point(ls, @type.Coord::Coord(5.0, 0.0)),
    Closest::Intersection(@type.Coord::Coord(5.0, 0.0)),
  )
}
```

- Line with `start == end` (degenerate): target on / off the point

```mbt check
///|
test "ClosestPoint::closest_point - Line degenerate (start == end)" {
  let degenerate = @type.Line::from_tuples((3.0, 4.0), (3.0, 4.0))
  @test.assert_eq(
    ClosestPoint::closest_point(degenerate, @type.Coord::Coord(3.0, 4.0)),
    Closest::Intersection(@type.Coord::Coord(3.0, 4.0)),
  )
  @test.assert_eq(
    ClosestPoint::closest_point(degenerate, @type.Coord::Coord(10.0, 10.0)),
    Closest::SinglePoint(@type.Coord::Coord(3.0, 4.0)),
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
