# simplify_vw.mbt

Visvalingam-Whyatt simplification of a `LineString`. Iteratively removes the interior coord whose associated triangle area is smallest, until the smallest remaining triangle exceeds `epsilon * 2`.

## Public API

- `simplify_vw_line_string`

## Test

### `simplify_vw_line_string`

- Removes a low-area middle vertex when its 2× area is below `epsilon * 2`

```mbt check
///|
test "simplify_vw_line_string - removes lowest-area middle vertex" {
  let ls = @type.LineString::from_tuples([(0.0, 0.0), (5.0, 0.5), (10.0, 0.0)])
  // Triangle 2*area = |10*0.5 - 0*5| = 5; epsilon=10 → threshold=20; 5 < 20: dropped.
  @test.assert_eq(
    simplify_vw_line_string(ls, 10.0),
    @type.LineString::from_tuples([(0.0, 0.0), (10.0, 0.0)]),
  )
}
```
