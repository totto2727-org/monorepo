# vector_ops.mbt

Treats a `Coord` as a 2D vector and provides magnitude, squared magnitude, 90° rotations (`left` / `right`), dot / wedge products, finite-check, and `try_normalize` (returns `None` for zero or non-finite inputs).

## Public API

- `magnitude`
- `magnitude_squared`
- `left`
- `right`
- `dot_product`
- `wedge_product`
- `is_finite`
- `try_normalize`

## Test

### `magnitude`

- 3-4-5 right triangle: magnitude is 5

```mbt check
///|
test "magnitude - 3-4-5 right triangle is 5" {
  @test.assert_eq(magnitude(@type.Coord::Coord(3.0, 4.0)), 5.0)
}
```

### `magnitude_squared`

- Squared magnitude skips the `sqrt`: `x² + y²`

```mbt check
///|
test "magnitude_squared - x² + y²" {
  @test.assert_eq(magnitude_squared(@type.Coord::Coord(3.0, 4.0)), 25.0)
}
```

### `left`

- 90° CCW rotation maps `(1, 0)` to `(0, 1)`

```mbt check
///|
test "left - rotates 90 deg CCW" {
  @test.assert_eq(
    left(@type.Coord::Coord(1.0, 0.0)),
    @type.Coord::Coord(0.0, 1.0),
  )
}
```

### `right`

- 90° CW rotation maps `(1, 0)` to `(0, -1)`

```mbt check
///|
test "right - rotates 90 deg CW" {
  @test.assert_eq(
    right(@type.Coord::Coord(1.0, 0.0)),
    @type.Coord::Coord(0.0, -1.0),
  )
}
```

### `dot_product`

- Inner product: `(1,2) · (3,4) = 11`

```mbt check
///|
test "dot_product - basic" {
  @test.assert_eq(
    dot_product(@type.Coord::Coord(1.0, 2.0), @type.Coord::Coord(3.0, 4.0)),
    11.0,
  )
}
```

### `wedge_product`

- 2D wedge: `(1,2) ∧ (3,4) = 1*4 - 2*3 = -2`

```mbt check
///|
test "wedge_product - basic" {
  @test.assert_eq(
    wedge_product(@type.Coord::Coord(1.0, 2.0), @type.Coord::Coord(3.0, 4.0)),
    -2.0,
  )
}
```

### `is_finite`

| Variable | State           | Note    |  1  |  2  |  3  |
| :------- | :-------------- | :------ | :-: | :-: | :-: |
| `c`      | `(0, 0)`        | true    |  ✓  |     |     |
| `c`      | `Has NaN`       | false   |     |  ✓  |     |
| `c`      | `Has infinity`  | false   |     |     |  ✓  |

- All-finite is true

```mbt check
///|
test "is_finite - all-finite is true" {
  assert_true(is_finite(@type.Coord::Coord(0.0, 0.0)))
}
```

- NaN is false

```mbt check
///|
test "is_finite - NaN is false" {
  assert_false(is_finite(@type.Coord::Coord(0.0 / 0.0, 0.0)))
}
```

- Infinity is false

```mbt check
///|
test "is_finite - infinity is false" {
  assert_false(is_finite(@type.Coord::Coord(1.0 / 0.0, 0.0)))
}
```

### `try_normalize`

| Variable | State                 | Note                                     |  1  |  2  |
| :------- | :-------------------- | :--------------------------------------- | :-: | :-: |
| `c`      | `Non-zero (3,4)`      | unit vector `(0.6, 0.8)`                 |  ✓  |     |
| `c`      | `Zero vector`         | `None` (division produces non-finite)    |     |  ✓  |

- Non-zero vector normalises to its unit vector

```mbt check
///|
test "try_normalize - non-zero gives unit vector" {
  @test.assert_eq(
    try_normalize(@type.Coord::Coord(3.0, 4.0)),
    Some(@type.Coord::Coord(0.6, 0.8)),
  )
}
```

- Zero vector returns `None`

```mbt check
///|
test "try_normalize - zero vector returns None" {
  @test.assert_eq(try_normalize(@type.Coord::Coord(0.0, 0.0)), None)
}
```
