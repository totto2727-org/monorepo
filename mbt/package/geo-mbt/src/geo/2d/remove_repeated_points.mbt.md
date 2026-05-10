# remove_repeated_points.mbt

Removes consecutive duplicate coordinates from a `LineString` (and from each ring of a `Polygon`).

## Public API

- `remove_repeated_points_line_string`
- `remove_repeated_points_polygon`

## Test

### `remove_repeated_points_line_string`

- Collapses consecutive duplicates while preserving non-duplicate order

```mbt check
///|
test "remove_repeated_points_line_string - collapses consecutive duplicates" {
  let ls = @type.LineString::from_tuples([
    (0.0, 0.0),
    (0.0, 0.0),
    (5.0, 0.0),
    (5.0, 0.0),
    (10.0, 0.0),
  ])
  @test.assert_eq(
    remove_repeated_points_line_string(ls),
    @type.LineString::from_tuples([(0.0, 0.0), (5.0, 0.0), (10.0, 0.0)]),
  )
}
```

### `remove_repeated_points_polygon`

- Collapses duplicates in both the exterior ring and every interior ring

```mbt check
///|
test "remove_repeated_points_polygon - collapses duplicates in every ring" {
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
  let cleaned = remove_repeated_points_polygon(polygon)
  // 7-coord exterior with two duplicate pairs → 5 unique + closing = collapses
  // to the canonical 5-coord ring after Polygon::Polygon's auto-closure.
  @test.assert_eq(cleaned.exterior().length(), 5)
  @test.assert_eq(cleaned.interiors()[0].length(), 5)
}
```
