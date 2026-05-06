# simplify.mbt

Ramer-Douglas-Peucker simplification of a `LineString` (and each ring of a `Polygon`). Coordinates whose perpendicular distance to the working segment is at most `epsilon` are dropped. The trait `Simplify::simplify` exposes this for `LineString` / `Polygon`; `simplify_line_string_indices` returns the kept indices for advanced callers.

## Public API

- `simplify_line_string_indices`
- `Simplify` — `simplify` (impls in traits.mbt for `LineString` / `Polygon`)

## Test

### `simplify_line_string_indices`

- Returns the kept indices when an interior coord lies above `epsilon`

```mbt check
///|
test "simplify_line_string_indices - keeps interior above epsilon" {
  let ls = @type.LineString::from_tuples([(0.0, 0.0), (5.0, 0.001), (10.0, 0.0)])
  // eps=0: middle is 0.001 above the line, retained.
  @test.assert_eq(simplify_line_string_indices(ls, 0.0), [0, 1, 2])
}
```

- Drops a nearly-collinear interior coord at higher epsilon

```mbt check
///|
test "simplify_line_string_indices - drops nearly collinear interior" {
  let ls = @type.LineString::from_tuples([(0.0, 0.0), (5.0, 0.001), (10.0, 0.0)])
  @test.assert_eq(simplify_line_string_indices(ls, 0.01), [0, 2])
}
```

### `Simplify`

#### `simplify`

| Variable | State                          | Note                                     |  1  |  2  |  3  |
| :------- | :----------------------------- | :--------------------------------------- | :-: | :-: | :-: |
| `self`   | `eps = 0`, interior above line | keep all (only strict-collinear dropped) |  ✓  |     |     |
| `self`   | `eps > distance`               | drop nearly-collinear interior           |     |  ✓  |     |
| `self`   | `< 3 coords`                   | unchanged                                |     |     |  ✓  |

- `eps = 0`: above-line interior is kept

```mbt check
///|
test "Simplify::simplify - eps 0 keeps non-collinear interior" {
  let ls = @type.LineString::from_tuples([(0.0, 0.0), (5.0, 0.001), (10.0, 0.0)])
  @test.assert_eq(Simplify::simplify(ls, 0.0).coords().length(), 3)
}
```

- `eps > distance`: interior is dropped

```mbt check
///|
test "Simplify::simplify - drops nearly collinear interior" {
  let ls = @type.LineString::from_tuples([(0.0, 0.0), (5.0, 0.001), (10.0, 0.0)])
  @test.assert_eq(Simplify::simplify(ls, 0.01).coords().length(), 2)
}
```

- Fewer than 3 coords is unchanged

```mbt check
///|
test "Simplify::simplify - fewer than 3 coords is unchanged" {
  let ls = @type.LineString::from_tuples([(0.0, 0.0), (10.0, 10.0)])
  @test.assert_eq(Simplify::simplify(ls, 1.0), ls)
}
```
