# coord.mbt

A lightweight 2D Cartesian coordinate (`x : Double`, `y : Double`) ported from `georust/geo-types`. Provides accessors, conversions to and from tuples and arrays, vector-space arithmetic (negation, addition, subtraction, scalar multiplication and division), and dot and cross products.

## Public API

- `Coord::Coord`
- `Coord::zero`
- `Coord::is_zero`
- `Coord::x`
- `Coord::y`
- `Coord::x_y`
- `Coord::from_tuple`
- `Coord::from_array`
- `Coord::to_array`
- `Neg`
- `Add`
- `Sub`
- `Coord::mul`
- `Coord::div`
- `Coord::dot`
- `Coord::cross`
- `Eq` (derived)
- `Default` (derived)

## Test

### `Coord::Coord`

- Simple initialization

```mbt check
///|
test "Coord::Coord - simple initialization" {
  let c = Coord::Coord(1.0, 2.0)
  debug_inspect(
    c,
    content=(
      #|{ x: 1, y: 2 }
    ),
  )
}
```

### `Coord::zero`

- Origin coordinate

```mbt check
///|
test "Coord::zero - origin" {
  @test.assert_eq(Coord::zero(), Coord::Coord(0.0, 0.0))
}
```

### `Coord::is_zero`

- True at origin

```mbt check
///|
test "Coord is_zero - origin" {
  let c = Coord::zero()
  assert_true(c.is_zero())
}
```

### `Coord::x`

- Getter

```mbt check
///|
test "Coord x - returns x component" {
  let c = Coord::Coord(1.0, 2.0)
  @test.assert_eq(c.x(), 1.0)
}
```

### `Coord::y`

- Getter

```mbt check
///|
test "Coord y - returns y component" {
  let c = Coord::Coord(1.0, 2.0)
  @test.assert_eq(c.y(), 2.0)
}
```

### `Coord::x_y`

- Returns tuple

```mbt check
///|
test "Coord x_y - returns tuple" {
  let c = Coord::Coord(40.02, 116.34)
  @test.assert_eq(c.x_y(), (40.02, 116.34))
}
```

### `Coord::from_tuple`

- Round-trip from tuple

```mbt check
///|
test "Coord::from_tuple - round-trip" {
  let c = Coord::from_tuple((40.02, 116.34))
  @test.assert_eq(c.x_y(), (40.02, 116.34))
}
```

### `Coord::from_array`

| Variable | State          | Note       |  1  |  2  |
| :------- | :------------- | :--------- | :-: | :-: |
| `a`      | `Length 2`     | valid      |  ✓  |     |
| `a`      | `Other length` | abort path |     |  ✓  |

- Round-trip from `[x, y]`

```mbt check
///|
test "Coord::from_array - round-trip" {
  let c = Coord::from_array([1.0, 2.0])
  @test.assert_eq(c.to_array(), [1.0, 2.0])
}
```

- Aborts on wrong length

```mbt check
///|
test "panic_Coord::from_array - wrong length" {
  Coord::from_array([1.0]) |> ignore
}
```

### `Coord::to_array`

- Builds 2-element array

```mbt check
///|
test "Coord to_array - 2-element array" {
  let c = Coord::Coord(1.0, 2.0)
  @test.assert_eq(c.to_array(), [1.0, 2.0])
}
```

### `Neg`

#### `neg`

- Basic negation

```mbt check
///|
test "Coord Neg::neg - basic negation" {
  let p = Coord::Coord(1.25, 2.5)
  @test.assert_eq(-p, Coord::Coord(-1.25, -2.5))
}
```

### `Add`

#### `add`

- Component-wise addition

```mbt check
///|
test "Coord Add::add - component-wise addition" {
  let p = Coord::Coord(1.25, 2.5)
  let q = Coord::Coord(1.5, 2.5)
  @test.assert_eq(p + q, Coord::Coord(2.75, 5.0))
}
```

### `Sub`

#### `sub`

- Component-wise subtraction

```mbt check
///|
test "Coord Sub::sub - component-wise subtraction" {
  let p = Coord::Coord(1.5, 2.5)
  let q = Coord::Coord(1.25, 2.5)
  @test.assert_eq(p - q, Coord::Coord(0.25, 0.0))
}
```

### `Coord::mul`

- Scalar multiplication

```mbt check
///|
test "Coord mul - scalar multiplication" {
  let p = Coord::Coord(1.25, 2.5)
  @test.assert_eq(p.mul(4.0), Coord::Coord(5.0, 10.0))
}
```

### `Coord::div`

- Scalar division

```mbt check
///|
test "Coord div - scalar division" {
  let p = Coord::Coord(5.0, 10.0)
  @test.assert_eq(p.div(4.0), Coord::Coord(1.25, 2.5))
}
```

### `Coord::dot`

- Basic dot product

```mbt check
///|
test "Coord dot - basic dot product" {
  let p = Coord::Coord(1.0, 2.0)
  let q = Coord::Coord(3.0, 4.0)
  // 1*3 + 2*4 = 11
  @test.assert_eq(p.dot(q), 11.0)
}
```

### `Coord::cross`

| Variable | State    | Note |  1  |  2  |
| :------- | :------- | :--- | :-: | :-: |
| `self`   | `(1, 0)` |      |  ✓  |     |
| `self`   | `(0, 1)` |      |     |  ✓  |
| `other`  | `(0, 1)` |      |  ✓  |     |
| `other`  | `(1, 0)` |      |     |  ✓  |

- CCW pair gives positive wedge

```mbt check
///|
test "Coord cross - CCW positive" {
  let p = Coord::Coord(1.0, 0.0)
  let q = Coord::Coord(0.0, 1.0)
  @test.assert_eq(p.cross(q), 1.0)
}
```

- CW pair gives negative wedge

```mbt check
///|
test "Coord cross - CW negative" {
  let p = Coord::Coord(0.0, 1.0)
  let q = Coord::Coord(1.0, 0.0)
  @test.assert_eq(p.cross(q), -1.0)
}
```

### `Eq` (derived)

#### `op_equal`

- Equal and unequal coordinates

```mbt check
///|
test "Coord Eq::op_equal - equal and unequal" {
  let a = Coord::Coord(1.0, 2.0)
  let b = Coord::Coord(1.0, 2.0)
  let c = Coord::Coord(1.0, 3.0)
  @test.assert_eq(a, b)
  @test.assert_not_eq(a, c)
}
```

### `Default` (derived)

#### `default`

- Default value equals origin

```mbt check
///|
test "Coord Default::default - is zero" {
  let d : Coord = Coord::default()
  @test.assert_eq(d, Coord::zero())
}
```
