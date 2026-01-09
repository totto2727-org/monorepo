# xyz.mbt

Provides a 3D coordinate structure `XYZ` and implements associated traits for arithmetic and coordinate manipulation.

## Public API

- `XYZ::new`
- `Add`, `Sub`, `Neg` implementation
- `CoordTrait` implementation
- `Coord2DTrait` implementation
- `Coord3DTrait` implementation

## Test

### XYZ::new

- Create new XYZ

```mbt check
///|
test {
  let p = XYZ::new(1.0, 2.0, 3.0)
  inspect(p, content="{x: 1, y: 2, z: 3}")
}
```

### Add

- Addition

```mbt check
///|
test {
  let p1 = XYZ::new(1.0, 2.0, 3.0)
  let p2 = XYZ::new(4.0, 5.0, 6.0)
  inspect(p1 + p2, content="{x: 5, y: 7, z: 9}")
}
```

### Sub

- Subtraction

```mbt check
///|
test {
  let p1 = XYZ::new(4.0, 5.0, 6.0)
  let p2 = XYZ::new(1.0, 2.0, 3.0)
  inspect(p1 - p2, content="{x: 3, y: 3, z: 3}")
}
```

### Neg

- Negation

```mbt check
///|
test {
  let p = XYZ::new(1.0, -2.0, 3.0)
  inspect(-p, content="{x: -1, y: 2, z: -3}")
}
```

### CoordTrait

#### mul

- Multiplication

```mbt check
///|
test {
  let p = XYZ::new(2.0, 4.0, 6.0)
  inspect(p.mul(2.0), content="{x: 4, y: 8, z: 12}")
}
```

#### div

- Division

```mbt check
///|
test {
  let p = XYZ::new(2.0, 4.0, 6.0)
  inspect(p.div(2.0), content="{x: 1, y: 2, z: 3}")
}
```

#### dot

- Dot product

```mbt check
///|
test {
  let p1 = XYZ::new(1.0, 2.0, 3.0)
  let p2 = XYZ::new(4.0, 5.0, 6.0)
  // 1*4 + 2*5 + 3*6 = 4 + 10 + 18 = 32
  inspect(p1.dot(p2), content="32")
}
```

### Coord2DTrait

#### x

- Get x

```mbt check
///|
test {
  let p = XYZ::new(1.0, 2.0, 3.0)
  inspect(p.x(), content="1")
}
```

#### y

- Get y

```mbt check
///|
test {
  let p = XYZ::new(1.0, 2.0, 3.0)
  inspect(p.y(), content="2")
}
```

#### set_x

- Set x

```mbt check
///|
test {
  let p = XYZ::new(1.0, 2.0, 3.0)
  inspect(p.set_x(4.0), content="{x: 4, y: 2, z: 3}")
}
```

#### set_y

- Set y

```mbt check
///|
test {
  let p = XYZ::new(1.0, 2.0, 3.0)
  inspect(p.set_y(5.0), content="{x: 1, y: 5, z: 3}")
}
```

### Coord3DTrait

#### z

- Get z

```mbt check
///|
test {
  let p = XYZ::new(1.0, 2.0, 3.0)
  inspect(p.z(), content="3")
}
```

#### set_z

- Set z

```mbt check
///|
test {
  let p = XYZ::new(1.0, 2.0, 3.0)
  inspect(p.set_z(4.0), content="{x: 1, y: 2, z: 4}")
}
```
