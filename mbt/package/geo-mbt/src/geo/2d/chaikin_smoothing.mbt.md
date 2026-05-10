# chaikin_smoothing.mbt

Chaikin's corner-cutting smoothing of a `LineString`. Each segment `(p_i, p_{i+1})` is replaced by the two cut points at 1/4 and 3/4 along it. Endpoints are preserved for open line strings; closed line strings smooth uniformly.

## Public API

- `chaikin_smoothing`

## Test

### `chaikin_smoothing`

| Variable       | State            | Note                                           |  1  |  2  |
| :------------- | :--------------- | :--------------------------------------------- | :-: | :-: |
| `n_iterations` | `0`              | identity (input returned as-is)                |  ✓  |     |
| `n_iterations` | `1` (open input) | open: `n` coords → 2\*(n-1) cuts + 2 endpoints |     |  ✓  |

- 0 iterations is the identity

```mbt check
///|
test "chaikin_smoothing - 0 iterations is identity" {
  let ls = @type.LineString::from_tuples([(0.0, 0.0), (10.0, 0.0)])
  @test.assert_eq(chaikin_smoothing(ls, 0), ls)
}
```

- 1 iteration on a 2-coord open line yields 4 coords (2 cuts + 2 endpoints)

```mbt check
///|
test "chaikin_smoothing - 1 iteration on 2-coord open line yields 4 coords" {
  let ls = @type.LineString::from_tuples([(0.0, 0.0), (10.0, 0.0)])
  @test.assert_eq(chaikin_smoothing(ls, 1).coords().length(), 4)
}
```
