# winding_order.mbt

Winding-order predicate for a closed `LineString` ring (the sign of the signed area). Returns `None` for degenerate / open rings whose signed area is zero. Also exposes `reverse_line_string` (returns a new `LineString` with the coords in reverse order).

## Public API

- `WindingOrder`
- `winding_order`
- `reverse_line_string`

## Test

### `winding_order`

| Variable | State               | Note                      |  1  |  2  |  3  |
| :------- | :------------------ | :------------------------ | :-: | :-: | :-: |
| `ls`     | `Closed CCW square` | `CounterClockwise`        |  ✓  |     |     |
| `ls`     | `Closed CW square`  | `Clockwise`               |     |  ✓  |     |
| `ls`     | `Open ring`         | `None` (signed area is 0) |     |     |  ✓  |

- CCW closed square has positive area

```mbt check
///|
test "winding_order - CCW closed square" {
  let ls = @type.LineString::from_tuples([
    (0.0, 0.0),
    (1.0, 0.0),
    (1.0, 1.0),
    (0.0, 1.0),
    (0.0, 0.0),
  ])
  @test.assert_eq(winding_order(ls), Some(WindingOrder::CounterClockwise))
}
```

- CW closed square has negative area

```mbt check
///|
test "winding_order - CW closed square" {
  let ls = @type.LineString::from_tuples([
    (0.0, 0.0),
    (0.0, 1.0),
    (1.0, 1.0),
    (1.0, 0.0),
    (0.0, 0.0),
  ])
  @test.assert_eq(winding_order(ls), Some(WindingOrder::Clockwise))
}
```

- Open ring (no closing coord) returns `None`

```mbt check
///|
test "winding_order - open ring returns None" {
  let ls = @type.LineString::from_tuples([(0.0, 0.0), (1.0, 0.0), (1.0, 1.0)])
  @test.assert_eq(winding_order(ls), None)
}
```

### `reverse_line_string`

- Reverses coord order

```mbt check
///|
test "reverse_line_string - reverses coord order" {
  let ls = @type.LineString::from_tuples([(0.0, 0.0), (1.0, 0.0), (1.0, 1.0)])
  @test.assert_eq(
    reverse_line_string(ls),
    @type.LineString::from_tuples([(1.0, 1.0), (1.0, 0.0), (0.0, 0.0)]),
  )
}
```
