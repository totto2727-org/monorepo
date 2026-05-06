# densify.mbt

Inserts intermediate coordinates along each segment of a `LineString` (or each ring of a `Polygon`) so that no segment exceeds `max_segment_length`. Exposed as the `Densify::densify` trait.

## Public API

- `Densify` — `densify` (impls in traits.mbt for `LineString` / `Polygon`)

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

- Short segment is left unchanged

```mbt check
///|
test "Densify::densify - short segment unchanged" {
  let ls = @type.LineString::from_tuples([(0.0, 0.0), (3.0, 0.0)])
  @test.assert_eq(Densify::densify(ls, 5.0), ls)
}
```
