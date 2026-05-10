# densify.mbt

Inserts intermediate coordinates along each segment of a `LineString` (or each ring of a `Polygon`) so that no segment exceeds `max_segment_length`. Exposed as the `Densify::densify` trait.

## Public API

- `Densify` — `densify` (impls in this file)

## Test

### `Densify`

#### `densify`

| Variable | State                          | Note            |  1  |  2  |
| :------- | :----------------------------- | :-------------- | :-: | :-: |
| `self`   | `Long segment (length > max)`  | gets subdivided |  ✓  |     |
| `self`   | `Short segment (length ≤ max)` | unchanged       |     |  ✓  |

- Long segment splits into equal-length sub-segments

```mbt check
///|
test "Densify::densify - long segment gets subdivided" {
  let ls = @type.LineString::from_tuples([(0.0, 0.0), (10.0, 0.0)])
  // max=5, length=10 → 2 sub-segments of 5 each → 3 coords with midpoint at (5,0).
  @test.assert_eq(
    Densify::densify(ls, 5.0),
    @type.LineString::from_tuples([(0.0, 0.0), (5.0, 0.0), (10.0, 0.0)]),
  )
}
```

- Polygon direct dispatch: every ring densified

```mbt check
///|
test "Densify::densify - Polygon direct dispatch" {
  let polygon = @type.Polygon::Polygon(
    @type.LineString::from_tuples([
      (0.0, 0.0),
      (10.0, 0.0),
      (10.0, 10.0),
      (0.0, 10.0),
    ]),
    [],
  )
  let densified = Densify::densify(polygon, 5.0)
  // Each 10-length edge becomes two 5-length sub-edges, so the exterior coord
  // count grows after densification.
  assert_true(
    densified.exterior().coords().length() >
    polygon.exterior().coords().length(),
  )
}
```

- Short segment is left unchanged

```mbt check
///|
test "Densify::densify - short segment unchanged" {
  let ls = @type.LineString::from_tuples([(0.0, 0.0), (3.0, 0.0)])
  @test.assert_eq(Densify::densify(ls, 5.0), ls)
}
```
