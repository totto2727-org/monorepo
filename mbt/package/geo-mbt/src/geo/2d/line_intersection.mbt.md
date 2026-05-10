# line_intersection.mbt

Computes the intersection of two `Line` segments. The result is a `LineIntersection` enum: `SinglePoint(coord, proper)` for a single crossing (with `proper = true` when both segments cross strictly in their interiors), `Collinear(line)` for an overlapping sub-segment, or `None` when there is no intersection.

## Public API

- `LineIntersection`
- `line_intersection`

## Test

### `line_intersection`

| Variable  | State                        | Note                                   |  1  |  2  |  3  |
| :-------- | :--------------------------- | :------------------------------------- | :-: | :-: | :-: |
| `l1`/`l2` | `Classic crossing (X shape)` | `SinglePoint` at center, `proper=true` |  ✓  |     |     |
| `l1`/`l2` | `Parallel non-overlapping`   | `None`                                 |     |  ✓  |     |
| `l1`/`l2` | `Collinear overlapping`      | `Collinear` over the overlap           |     |     |  ✓  |

- Classic crossing intersects at the center proper

```mbt check
///|
test "line_intersection - classic crossing intersects at center" {
  let l1 = @type.Line::from_tuples((0.0, 0.0), (10.0, 10.0))
  let l2 = @type.Line::from_tuples((0.0, 10.0), (10.0, 0.0))
  let result = match line_intersection(l1, l2) {
    Some(LineIntersection::SinglePoint(c, proper)) => (c, proper)
    _ => abort("expected SinglePoint")
  }
  // Up to floating-point round-off the intersection is (5, 5), proper=true.
  assert_true((result.0.x() - 5.0).abs() < TOLERANCE)
  assert_true((result.0.y() - 5.0).abs() < TOLERANCE)
  assert_true(result.1)
}
```

- Parallel non-overlapping segments give `None`

```mbt check
///|
test "line_intersection - parallel non-overlapping returns None" {
  let l1 = @type.Line::from_tuples((0.0, 0.0), (10.0, 0.0))
  let l2 = @type.Line::from_tuples((0.0, 1.0), (10.0, 1.0))
  @test.assert_eq(line_intersection(l1, l2), None)
}
```

- Collinear overlapping segments give a `Collinear` `Line` over the overlap

```mbt check
///|
test "line_intersection - collinear overlapping segments share a sub-line" {
  let l1 = @type.Line::from_tuples((0.0, 0.0), (10.0, 0.0))
  let l2 = @type.Line::from_tuples((5.0, 0.0), (15.0, 0.0))
  @test.assert_eq(
    line_intersection(l1, l2),
    Some(
      LineIntersection::Collinear(
        @type.Line::Line(
          @type.Coord::Coord(5.0, 0.0),
          @type.Coord::Coord(10.0, 0.0),
        ),
      ),
    ),
  )
}
```
