# rect.mbt

Represents an axis-aligned bounding box.

## Public API

- `Rect::new`
- `exterior`
- `bbox`

## Test

### `Rect::new`

- Simple initialization

```mbt check
///|
test {
  let min = XY::new(0.0, 0.0)
  let max = XY::new(10.0, 20.0)
  let rect = Rect::new(min, max)
  inspect(rect, content="{min: {x: 0, y: 0}, max: {x: 10, y: 20}}")
}
```

### `exterior`

- Convert to Polygon exterior ring

```mbt check
///|
test {
  let min = XY::new(0.0, 0.0)
  let max = XY::new(10.0, 20.0)
  let rect = Rect::new(min, max)
  inspect(
    rect.exterior().coord_array(),
    content="[{x: 0, y: 0}, {x: 0, y: 20}, {x: 10, y: 20}, {x: 10, y: 0}, {x: 0, y: 0}]",
  )
}
```

### `bbox`

- Calculate BBox (identity)

```mbt check
///|
test {
  let min = XY::new(1.0, 1.0)
  let max = XY::new(5.0, 5.0)
  let rect = Rect::new(min, max)
  inspect(rect.bbox(), content="{min: {x: 1, y: 1}, max: {x: 5, y: 5}}")
}
```
