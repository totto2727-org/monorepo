# point.mbt

Represents a single point in space.

## Public API

- `Point::new`
- `coord`
- `coord_array`
- `bbox`

## Test

### `Point::new`

- Simple initialization

```mbt check
///|
test {
  inspect(Point::new(XY::new(1.0, 2.0)), content="Point({x: 1, y: 2})")
}
```

### `coord`

- Getter

```mbt check
///|
test {
  inspect(Point::new(XY::new(3.0, 4.0)).coord(), content="{x: 3, y: 4}")
}
```

### `coord_array`

- Array wrapping

```mbt check
///|
test {
  // let _xy =
  inspect(Point::new(XY::new(1.0, 2.0)).coord_array(), content="[{x: 1, y: 2}]")
}
```

### `bbox`

- Calculate BBox

```mbt check
///|
test {
  inspect(
    Point::new(XY::new(1.0, 2.0)).bbox(),
    content="{min: {x: 1, y: 2}, max: {x: 1, y: 2}}",
  )
}
```
