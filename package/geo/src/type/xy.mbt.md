# xy.mbt

A 2D coordinate structure used as the fundamental building block for geometries. It supports basic arithmetic operations like addition, subtraction, multiplication, and division, as well as dot product calculation.

## Public API

- `XY::new`
- `add`
- `sub`
- `neg`
- `mul`
- `div`
- `dot`
- `x`
- `y`
- `set_x`
- `set_y`

## Test

### XY::new

- Simple initialization

```mbt check
///|
test {
  let xy = XY::new(1.0, 2.0)
  inspect(xy, content="{x: 1, y: 2}")
}
```

### Add

#### add

- Basic addition

```mbt check
///|
test {
  let a = XY::new(1.0, 2.0)
  let b = XY::new(3.0, 4.0)
  inspect(a + b, content="{x: 4, y: 6}")
}
```

### Sub

#### sub

- Basic subtraction

```mbt check
///|
test {
  let a = XY::new(3.0, 5.0)
  let b = XY::new(1.0, 2.0)
  inspect(a - b, content="{x: 2, y: 3}")
}
```

### Neg

#### neg

- Basic negation

```mbt check
///|
test {
  let a = XY::new(1.0, -2.0)
  inspect(-a, content="{x: -1, y: 2}")
}
```

### CoordTrait

#### mul

- Scalar multiplication

```mbt check
///|
test {
  let a = XY::new(2.0, 3.0)
  inspect(a.mul(2.0), content="{x: 4, y: 6}")
}
```

#### div

- Scalar division

```mbt check
///|
test {
  let b = XY::new(4.0, 6.0)
  inspect(b.div(2.0), content="{x: 2, y: 3}")
}
```

#### dot

- Basic dot product

```mbt check
///|
test {
  let a = XY::new(1.0, 2.0)
  let b = XY::new(3.0, 4.0)
  // 1*3 + 2*4 = 11
  inspect(a.dot(b), content="11")
}
```

### Coord2DTrait

#### x

- Getter

```mbt check
///|
test {
  let xy = XY::new(3.0, 4.0)
  inspect(xy.x(), content="3")
}
```

#### y

- Getter

```mbt check
///|
test {
  let xy = XY::new(3.0, 4.0)
  inspect(xy.y(), content="4")
}
```

#### set_x

- Update value

```mbt check
///|
test {
  let xy = XY::new(1.0, 2.0)
  let updated_x = xy.set_x(5.0)
  inspect(updated_x, content="{x: 5, y: 2}")
  // Ensure original is unchanged
  inspect(xy, content="{x: 1, y: 2}")
}
```

#### set_y

- Update value

```mbt check
///|
test {
  let xy = XY::new(1.0, 2.0)
  let updated_y = xy.set_y(6.0)
  inspect(updated_y, content="{x: 1, y: 6}")
  // Ensure original is unchanged
  inspect(xy, content="{x: 1, y: 2}")
}
```
