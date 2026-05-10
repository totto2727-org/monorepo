# line_locate_point.mbt

Project a `target` coord onto a `Line` (or `LineString`) and return the fractional position `0..=1` of the closest point along it.

## Public API

- `line_locate_point`
- `line_string_locate_point`

## Test

### `line_locate_point`

| Variable | State                       | Note           |  1  |  2  |  3  |
| :------- | :-------------------------- | :------------- | :-: | :-: | :-: |
| `target` | `Above midpoint`            | fraction 0.5   |  ✓  |     |     |
| `target` | `Beyond end`                | clamped to 1.0 |     |  ✓  |     |
| `line`   | `Degenerate (start == end)` | returns `None` |     |     |  ✓  |

- Midpoint projects to 0.5

```mbt check
///|
test "line_locate_point - midpoint projects to 0.5" {
  let l = @type.Line::from_tuples((0.0, 0.0), (10.0, 0.0))
  @test.assert_eq(line_locate_point(l, @type.Coord::Coord(5.0, 5.0)), Some(0.5))
}
```

- Beyond end clamps to 1.0

```mbt check
///|
test "line_locate_point - beyond end is clamped to 1.0" {
  let l = @type.Line::from_tuples((0.0, 0.0), (10.0, 0.0))
  @test.assert_eq(
    line_locate_point(l, @type.Coord::Coord(20.0, 0.0)),
    Some(1.0),
  )
}
```

- Degenerate (zero-length) line returns `None`

```mbt check
///|
test "line_locate_point - degenerate line returns None" {
  let l = @type.Line::from_tuples((3.0, 4.0), (3.0, 4.0))
  @test.assert_eq(line_locate_point(l, @type.Coord::Coord(0.0, 0.0)), None)
}
```

### `line_string_locate_point`

- Midpoint of a single-segment line string is 0.5

```mbt check
///|
test "line_string_locate_point - midpoint of single segment is 0.5" {
  let ls = @type.LineString::from_tuples([(0.0, 0.0), (10.0, 0.0)])
  @test.assert_eq(
    line_string_locate_point(ls, @type.Coord::Coord(5.0, 5.0)),
    Some(0.5),
  )
}
```

- Empty / single-coord line string returns `None`

```mbt check
///|
test "line_string_locate_point - empty returns None" {
  let ls = @type.LineString::empty()
  @test.assert_eq(
    line_string_locate_point(ls, @type.Coord::Coord(0.0, 0.0)),
    None,
  )
}
```
