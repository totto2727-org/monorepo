# point.mbt

A single point in 2D space backed by a `Coord` field. Provides accessors, construction from `Coord` / tuple, partial updaters (`with_x` / `with_y`), vector-space arithmetic (negation, addition, subtraction, scalar multiplication and division), and dot / triangle cross products.

## Public API

- `Point::Point`
- `Point::from_coord`
- `Point::from_tuple`
- `Point::coord`
- `Point::x`
- `Point::y`
- `Point::x_y`
- `Point::with_x`
- `Point::with_y`
- `Point::dot`
- `Point::cross_prod`
- `Neg`
- `Add`
- `Sub`
- `Point::mul`
- `Point::div`
- `Eq` (derived)
- `Default` (derived)

## Test

### `Point::Point`

- Simple initialization

```mbt check
///|
test "Point::Point - simple initialization" {
  let p = Point::Point(1.234, 2.345)
  debug_inspect(
    p,
    content=(
      #|{ coord: { x: 1.234, y: 2.345 } }
    ),
  )
}
```

### `Point::from_coord`

- Round-trip via `coord()`

```mbt check
///|
test "Point::from_coord - round-trip via coord()" {
  let c = Coord::Coord(10.0, 20.0)
  let p = Point::from_coord(c)
  @test.assert_eq(p.coord(), c)
}
```

### `Point::from_tuple`

- Round-trip via `x_y()`

```mbt check
///|
test "Point::from_tuple - round-trip via x_y()" {
  let p = Point::from_tuple((40.02, 116.34))
  @test.assert_eq(p.x_y(), (40.02, 116.34))
}
```

### `Point::coord`

- Returns the underlying `Coord`

```mbt check
///|
test "Point coord - returns underlying Coord" {
  let p = Point::Point(1.0, 2.0)
  @test.assert_eq(p.coord(), Coord::Coord(1.0, 2.0))
}
```

### `Point::x`

- Getter

```mbt check
///|
test "Point x - returns x component" {
  let p = Point::Point(1.234, 2.345)
  @test.assert_eq(p.x(), 1.234)
}
```

### `Point::y`

- Getter

```mbt check
///|
test "Point y - returns y component" {
  let p = Point::Point(1.234, 2.345)
  @test.assert_eq(p.y(), 2.345)
}
```

### `Point::x_y`

- Returns tuple

```mbt check
///|
test "Point x_y - returns tuple" {
  let p = Point::Point(1.234, 2.345)
  @test.assert_eq(p.x_y(), (1.234, 2.345))
}
```

### `Point::with_x`

- Replaces `x` while preserving `y`

```mbt check
///|
test "Point with_x - replaces x preserving y" {
  let p = Point::Point(1.234, 2.345).with_x(9.876)
  @test.assert_eq(p, Point::Point(9.876, 2.345))
}
```

### `Point::with_y`

- Replaces `y` while preserving `x`

```mbt check
///|
test "Point with_y - replaces y preserving x" {
  let p = Point::Point(1.234, 2.345).with_y(9.876)
  @test.assert_eq(p, Point::Point(1.234, 9.876))
}
```

### `Point::dot`

- Basic dot product

```mbt check
///|
test "Point dot - basic dot product" {
  let p = Point::Point(1.5, 0.5)
  let q = Point::Point(2.0, 4.5)
  // 1.5*2.0 + 0.5*4.5 = 5.25
  @test.assert_eq(p.dot(q), 5.25)
}
```

### `Point::cross_prod`

- Triangle wedge product

```mbt check
///|
test "Point cross_prod - triangle wedge product" {
  let a = Point::Point(1.0, 2.0)
  let b = Point::Point(3.0, 5.0)
  let c = Point::Point(7.0, 12.0)
  // (3-1)*(12-2) - (5-2)*(7-1) = 20 - 18 = 2
  @test.assert_eq(a.cross_prod(b, c), 2.0)
}
```

### `Neg`

#### `neg`

- Basic negation

```mbt check
///|
test "Point Neg::neg - basic negation" {
  let p = -Point::Point(-1.25, 2.5)
  @test.assert_eq(p, Point::Point(1.25, -2.5))
}
```

### `Add`

#### `add`

- Component-wise addition

```mbt check
///|
test "Point Add::add - component-wise addition" {
  let p = Point::Point(1.25, 2.5) + Point::Point(1.5, 2.5)
  @test.assert_eq(p, Point::Point(2.75, 5.0))
}
```

### `Sub`

#### `sub`

- Component-wise subtraction

```mbt check
///|
test "Point Sub::sub - component-wise subtraction" {
  let p = Point::Point(1.25, 3.0) - Point::Point(1.5, 2.5)
  @test.assert_eq(p, Point::Point(-0.25, 0.5))
}
```

### `Point::mul`

- Scalar multiplication

```mbt check
///|
test "Point mul - scalar multiplication" {
  let p = Point::Point(2.0, 3.0).mul(2.0)
  @test.assert_eq(p, Point::Point(4.0, 6.0))
}
```

### `Point::div`

- Scalar division

```mbt check
///|
test "Point div - scalar division" {
  let p = Point::Point(4.0, 6.0).div(2.0)
  @test.assert_eq(p, Point::Point(2.0, 3.0))
}
```

### `Eq` (derived)

#### `op_equal`

- Equal and unequal points

```mbt check
///|
test "Point Eq::op_equal - equal and unequal" {
  let a = Point::Point(1.0, 2.0)
  let b = Point::Point(1.0, 2.0)
  let c = Point::Point(1.0, 3.0)
  @test.assert_eq(a, b)
  @test.assert_not_eq(a, c)
}
```

### `Default` (derived)

#### `default`

- Default value is origin

```mbt check
///|
test "Point Default::default - is origin" {
  let d : Point = Point::default()
  @test.assert_eq(d, Point::Point(0.0, 0.0))
}
```
