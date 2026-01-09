# coord.mbt

Provides basic coordinate operations including accessors, arithmetic (negation, addition, subtraction, scalar multiplication/division), and dot product calculation.

## Public API

- `xy` (default implementation)
- `dot` (default implementation)

## Test

### `Coord2DTrait`

#### `xy`

- Default implementation returns `XY`

```mbt check
///|
test {
  let c = XY::new(1.0, 2.0)
  inspect(c.xy(), content="{x: 1, y: 2}")
}
```

#### `xyz`

- Default implementation returns `XYZ`

```mbt check
///|
test {
  let c = XYZ::new(1.0, 2.0, 3.0)
  inspect(c.xyz(), content="{x: 1, y: 2, z: 3}")
}
```
