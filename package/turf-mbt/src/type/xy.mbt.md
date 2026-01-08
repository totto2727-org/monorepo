# xy.mbt

A 2D coordinate structure used as the fundamental building block for geometries. It supports basic arithmetic operations like addition, subtraction, multiplication, and division, as well as dot product calculation.

## Public API

- `XY::new`
- `x`
- `y`
- `set_x`
- `set_y`
- `op_add`
- `op_sub`
- `op_neg`
- `mul`
- `div`
- `dot`

## Test

### `XY::new`

- Simple initialization

  ```mbt test
  let xy = XY::new(1.0, 2.0)
  inspect(xy, content="{x: 1, y: 2}")
  ```

### `x`

- Getter

  ```mbt test
  let xy = XY::new(3.0, 4.0)
  inspect(xy.x(), content="3")
  ```

### `y`

- Getter

  ```mbt test
  let xy = XY::new(3.0, 4.0)
  inspect(xy.y(), content="4")
  ```

### `set_x`

- Update value

  ```mbt test
  let xy = XY::new(1.0, 2.0)
  let updated = xy.set_x(5.0)
  inspect(updated, content="{x: 5, y: 2}")
  // Ensure original is unchanged (immutability check implied)
  inspect(xy, content="{x: 1, y: 2}")
  ```

### `set_y`

- Update value

  ```mbt test
  let xy = XY::new(1.0, 2.0)
  let updated = xy.set_y(6.0)
  inspect(updated, content="{x: 1, y: 6}")
  inspect(xy, content="{x: 1, y: 2}")
  ```

### `op_add`

- Basic addition

  ```mbt test
  let a = XY::new(1.0, 2.0)
  let b = XY::new(3.0, 4.0)
  inspect(a + b, content="{x: 4, y: 6}")
  ```

### `op_sub`

- Basic subtraction

  ```mbt test
  let a = XY::new(3.0, 5.0)
  let b = XY::new(1.0, 2.0)
  inspect(a - b, content="{x: 2, y: 3}")
  ```

### `op_neg`

- Basic negation

  ```mbt test
  let a = XY::new(1.0, -2.0)
  inspect(-a, content="{x: -1, y: 2}")
  ```

### `mul`

- Scalar multiplication

  ```mbt test
  let a = XY::new(2.0, 3.0)
  inspect(a.mul(2.0), content="{x: 4, y: 6}")
  ```

### `div`

- Scalar division

  ```mbt test
  let a = XY::new(4.0, 6.0)
  inspect(a.div(2.0), content="{x: 2, y: 3}")
  ```

### `dot`

- Basic dot product

  ```mbt test
  let a = XY::new(1.0, 2.0)
  let b = XY::new(3.0, 4.0)
  // 1*3 + 2*4 = 11
  inspect(a.dot(b), content="11")
  ```
