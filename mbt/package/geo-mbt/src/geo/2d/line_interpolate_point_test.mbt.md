# line_interpolate_point.mbt

Returns the `Point` at a fractional position `0..=1` along a `Line` (or `LineString`'s total length). Out-of-range fractions are clamped.

## Public API

- `line_interpolate_point`
- `line_string_interpolate_point`

## Test

### `line_interpolate_point`

| Variable    | State        | Note         |  1  |  2  |  3  |
| :---------- | :----------- | :----------- | :-: | :-: | :-: |
| `fraction`  | `0`          | start        |  ✓  |     |     |
| `fraction`  | `1`          | end          |     |  ✓  |     |
| `fraction`  | `0.5`        | midpoint     |     |     |  ✓  |

- `f = 0` returns the start

```mbt check
///|
test "line_interpolate_point - f=0 returns start" {
  let l = @type.Line::from_tuples((1.0, 2.0), (5.0, 10.0))
  @test.assert_eq(line_interpolate_point(l, 0.0), @type.Point::Point(1.0, 2.0))
}
```

- `f = 1` returns the end

```mbt check
///|
test "line_interpolate_point - f=1 returns end" {
  let l = @type.Line::from_tuples((1.0, 2.0), (5.0, 10.0))
  @test.assert_eq(line_interpolate_point(l, 1.0), @type.Point::Point(5.0, 10.0))
}
```

- `f = 0.5` returns the midpoint

```mbt check
///|
test "line_interpolate_point - f=0.5 returns midpoint" {
  let l = @type.Line::from_tuples((0.0, 0.0), (10.0, 20.0))
  @test.assert_eq(line_interpolate_point(l, 0.5), @type.Point::Point(5.0, 10.0))
}
```

### `line_string_interpolate_point`

- Halfway along a two-segment polyline (total length 20) lands at `(10, 0)`

```mbt check
///|
test "line_string_interpolate_point - half-way along" {
  let ls = @type.LineString::from_tuples([(0.0, 0.0), (10.0, 0.0), (10.0, 10.0)])
  let p = match line_string_interpolate_point(ls, 0.5) {
    Some(p) => p
    None => abort("expected Some for non-empty linestring")
  }
  // Up to floating-point round-off the result is (10, 0).
  assert_true((p.x() - 10.0).abs() < 1.0e-9)
  assert_true(p.y().abs() < 1.0e-9)
}
```
