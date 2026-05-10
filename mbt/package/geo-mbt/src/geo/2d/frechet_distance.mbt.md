# frechet_distance.mbt

Discrete Fréchet distance between two `LineString`s. Two empty inputs give 0; a single empty input gives `+∞`.

## Public API

- `frechet_distance`

## Test

### `frechet_distance`

| Variable | State                         | Note       |  1  |  2  |  3  |
| :------- | :---------------------------- | :--------- | :-: | :-: | :-: |
| `a`/`b`  | `Identical`                   | distance 0 |  ✓  |     |     |
| `a`/`b`  | `Parallel translated by Δy=5` | distance 5 |     |  ✓  |     |
| `a`/`b`  | `Both empty`                  | distance 0 |     |     |  ✓  |

- Identical line strings give 0

```mbt check
///|
test "frechet_distance - identical lines give 0" {
  let a = @type.LineString::from_tuples([(0.0, 0.0), (10.0, 0.0)])
  @test.assert_eq(frechet_distance(a, a), 0.0)
}
```

- Parallel-translated lines: distance equals the translation

```mbt check
///|
test "frechet_distance - parallel translated lines give the offset" {
  let a = @type.LineString::from_tuples([(0.0, 0.0), (10.0, 0.0)])
  let b = @type.LineString::from_tuples([(0.0, 5.0), (10.0, 5.0)])
  let d = frechet_distance(a, b)
  assert_true((d - 5.0).abs() < TOLERANCE)
}
```

- Both empty inputs give 0

```mbt check
///|
test "frechet_distance - both empty give 0" {
  let a = @type.LineString::empty()
  @test.assert_eq(frechet_distance(a, a), 0.0)
}
```
