# remove_repeated_points.mbt

Returns a copy of the geometry with consecutive duplicate coordinates collapsed. Exposed via the `RemoveRepeatedPoints` trait — the per-type free functions are package-private dispatch internals.

## Public API

- `RemoveRepeatedPoints` trait — impls on `LineString` / `Polygon`
  - `remove_repeated_points(Self) -> Self`

## Test

### `RemoveRepeatedPoints` for `LineString`

- Collapses consecutive duplicates while preserving non-duplicate order

```mbt check
///|
test "RemoveRepeatedPoints::remove_repeated_points - LineString collapses consecutive duplicates" {
  let ls = @type.LineString::from_tuples([
    (0.0, 0.0),
    (0.0, 0.0),
    (5.0, 0.0),
    (5.0, 0.0),
    (10.0, 0.0),
  ])
  @test.assert_eq(
    RemoveRepeatedPoints::remove_repeated_points(ls),
    @type.LineString::from_tuples([(0.0, 0.0), (5.0, 0.0), (10.0, 0.0)]),
  )
}
```

### `RemoveRepeatedPoints` for `Polygon`

- Collapses duplicates in both the exterior ring and every interior ring

```mbt check
///|
test "RemoveRepeatedPoints::remove_repeated_points - Polygon collapses in every ring" {
  let exterior = @type.LineString::from_tuples([
    (0.0, 0.0),
    (0.0, 0.0),
    (4.0, 0.0),
    (4.0, 4.0),
    (0.0, 4.0),
    (0.0, 4.0),
    (0.0, 0.0),
  ])
  let interior = @type.LineString::from_tuples([
    (1.0, 1.0),
    (1.0, 1.0),
    (3.0, 1.0),
    (3.0, 3.0),
    (1.0, 3.0),
    (1.0, 1.0),
  ])
  let polygon = @type.Polygon::Polygon(exterior, [interior])
  let cleaned = RemoveRepeatedPoints::remove_repeated_points(polygon)
  // 7-coord exterior with two duplicate pairs → 5 unique + closing = collapses
  // to the canonical 5-coord ring after Polygon::Polygon's auto-closure.
  @test.assert_eq(cleaned.exterior().length(), 5)
  @test.assert_eq(cleaned.interiors()[0].length(), 5)
}
```
