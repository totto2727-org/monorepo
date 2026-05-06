# affine_transform.mbt

A 2D affine transform stored as a pair of `AffineRow`s (`row_x` / `row_y`) representing the upper two rows of a 3×3 row-major matrix. Provides factory constructors (`identity` / `translate_xy` / `scale_xy` / `rotate_origin` / `skew_origin`), pointwise `apply`, `compose` (matrix multiplication in the order *first self, then other*), and a generic `transform` over any `MapCoords` instance.

## Public API

- `AffineRow`
- `AffineRow::AffineRow`
- `AffineTransform`
- `AffineTransform::AffineTransform`
- `AffineTransform::identity`
- `AffineTransform::translate_xy`
- `AffineTransform::scale_xy`
- `AffineTransform::rotate_origin`
- `AffineTransform::skew_origin`
- `AffineTransform::apply`
- `AffineTransform::compose`
- `AffineTransform::transform`
- `Eq` (derived, on both structs)

## Test

### `AffineRow::AffineRow`

- Simple initialization

```mbt check
///|
test "AffineRow::AffineRow - simple initialization" {
  let row = AffineRow::AffineRow(2.0, 0.5, 7.0)
  debug_inspect(
    row,
    content=(
      #|{ scale: 2, skew: 0.5, translate: 7 }
    ),
  )
}
```

### `AffineTransform::AffineTransform`

- Simple initialization

```mbt check
///|
test "AffineTransform::AffineTransform - simple initialization" {
  let t = AffineTransform::AffineTransform(
    AffineRow::AffineRow(1.0, 0.0, 0.0),
    AffineRow::AffineRow(1.0, 0.0, 0.0),
  )
  debug_inspect(
    t,
    content=(
      #|{
      #|  row_x: { scale: 1, skew: 0, translate: 0 },
      #|  row_y: { scale: 1, skew: 0, translate: 0 },
      #|}
    ),
  )
}
```

### `AffineTransform::identity`

- Apply leaves the coordinate unchanged

```mbt check
///|
test "AffineTransform::identity - leaves coordinate unchanged" {
  let t = AffineTransform::identity()
  @test.assert_eq(
    t.apply(@type.Coord::Coord(3.0, 4.0)),
    @type.Coord::Coord(3.0, 4.0),
  )
}
```

### `AffineTransform::translate_xy`

- Pure translation

```mbt check
///|
test "AffineTransform::translate_xy - pure translation" {
  let t = AffineTransform::translate_xy(1.0, 2.0)
  @test.assert_eq(
    t.apply(@type.Coord::Coord(0.0, 0.0)),
    @type.Coord::Coord(1.0, 2.0),
  )
}
```

### `AffineTransform::scale_xy`

- Pure axis-aligned scaling

```mbt check
///|
test "AffineTransform::scale_xy - pure scaling" {
  let t = AffineTransform::scale_xy(2.0, 3.0)
  @test.assert_eq(
    t.apply(@type.Coord::Coord(1.0, 1.0)),
    @type.Coord::Coord(2.0, 3.0),
  )
}
```

### `AffineTransform::rotate_origin`

- 90° CCW rotation maps `(1, 0)` to `(0, 1)` (up to floating-point round-off)

```mbt check
///|
test "AffineTransform::rotate_origin - 90 degrees CCW" {
  let t = AffineTransform::rotate_origin(90.0)
  let p = t.apply(@type.Coord::Coord(1.0, 0.0))
  // Up to ~1e-9 floating-point round-off the result is (0, 1).
  assert_true(p.x().abs() < 1.0e-9)
  assert_true((p.y() - 1.0).abs() < 1.0e-9)
}
```

### `AffineTransform::skew_origin`

- 45° X-skew maps `(0, 1)` to `(1, 1)` (`tan(45°) = 1`)

```mbt check
///|
test "AffineTransform::skew_origin - 45 deg X-skew shifts y onto x" {
  let t = AffineTransform::skew_origin(45.0, 0.0)
  let p = t.apply(@type.Coord::Coord(0.0, 1.0))
  // Up to floating-point round-off the result is (1, 1) since tan(45°) = 1.
  assert_true((p.x() - 1.0).abs() < 1.0e-9)
  assert_true((p.y() - 1.0).abs() < 1.0e-9)
}
```

### `AffineTransform::apply`

Exercised by every `identity` / `translate_xy` / `scale_xy` / `rotate_origin` / `skew_origin` test above. No additional dedicated case.

### `AffineTransform::compose`

- Translate then scale: `(0, 0) → (1, 1) → (2, 2)`

```mbt check
///|
test "AffineTransform::compose - translate then scale" {
  let t1 = AffineTransform::translate_xy(1.0, 1.0)
  let t2 = AffineTransform::scale_xy(2.0, 2.0)
  let combined = t1.compose(t2)
  @test.assert_eq(
    combined.apply(@type.Coord::Coord(0.0, 0.0)),
    @type.Coord::Coord(2.0, 2.0),
  )
}
```

### `AffineTransform::transform`

- Lifts `apply` over any `MapCoords` instance — verified on `Point`

```mbt check
///|
test "AffineTransform::transform - applies to a Point via MapCoords" {
  let t = AffineTransform::translate_xy(10.0, 20.0)
  let p = @type.Point::Point(1.0, 2.0)
  @test.assert_eq(t.transform(p), @type.Point::Point(11.0, 22.0))
}
```

### `Eq` (derived)

#### `op_equal`

- Equal and unequal `AffineTransform`s

```mbt check
///|
test "AffineTransform Eq::op_equal - equal and unequal" {
  let a = AffineTransform::identity()
  let b = AffineTransform::identity()
  let c = AffineTransform::scale_xy(2.0, 2.0)
  @test.assert_eq(a, b)
  @test.assert_not_eq(a, c)
}
```
