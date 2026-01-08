# triangle.mbt

Represents a triangle defined by three vertices.

## Public API

- `Triangle::new`
- `exterior`
- `bbox`

## Test

### `Triangle::new`

- Simple initialization

```mbt test
let a = XY::new(0.0, 0.0)
let b = XY::new(1.0, 0.0)
let c = XY::new(0.0, 1.0)
let tri = Triangle::new(a, b, c)
inspect(tri, content="{a: {x: 0, y: 0}, b: {x: 1, y: 0}, c: {x: 0, y: 1}}")
```

### `exterior`

- Convert to Polygon exterior ring

```mbt test
let a = XY::new(0.0, 0.0)
let b = XY::new(1.0, 0.0)
let c = XY::new(0.0, 1.0)
let tri = Triangle::new(a, b, c)
inspect(
  tri.exterior().coord_array(),
  content="[{x: 0, y: 0}, {x: 1, y: 0}, {x: 0, y: 1}, {x: 0, y: 0}]",
)
```

### `bbox`

- Calculate BBox

```mbt test
let a = XY::new(0.0, 0.0)
let b = XY::new(2.0, 1.0)
let c = XY::new(1.0, 3.0)
let tri = Triangle::new(a, b, c)
inspect(tri.bbox(), content="{min: {x: 0, y: 0}, max: {x: 2, y: 3}}")
```
