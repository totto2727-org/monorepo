# coord.mbt

Provides basic coordinate operations including accessors, arithmetic (negation, addition, subtraction, scalar multiplication/division), and dot product calculation.

## Public API

- `xy` (default implementation)
- `dot` (default implementation)

## Test

### `xy`

| Variable | State | Note | 1 |
| :--- | :--- | :--- | :---: |
| `self` | `Valid` | | ✓ |

- Default implementation returns `XY`

  ```mbt check
  ///|
  test {
    let c = XY::new(1.0, 2.0)
    inspect(c.xy(), content="{x: 1, y: 2}")
  }
  ```

### `dot`

| Variable | State | Note | 1 |
| :--- | :--- | :--- | :---: |
| `self` | `Valid` | | ✓ |

- Default implementation calculates dot product

  ```mbt check
  ///|
  test {
    let c1 = XY::new(1.0, 2.0)
    let c2 = XY::new(3.0, 4.0)
    inspect(c1.dot(c2), content="11")
  }
  ```
