# multi_geometry.mbt

Provides functionality for collections of geometries, including efficient flattening of coordinates (`coord_array`) and unified geometry handling.

## Public API

- `coord_array` (default implementation via `&MultiGeometryTrait`)
- `Show` (default implementation for `&MultiGeometryTrait`)

## Test

### `coord_array`

| Variable | State | Note | 1 |
| :--- | :--- | :--- | :---: |
| `self` | `Valid` | | ✓ |

- Default implementation flattens geometry coordinates

```mbt check
///|
test {
  let mp = MultiPoint::new([
    Point::new(XY::new(1.0, 1.0)),
    Point::new(XY::new(2.0, 2.0)),
  ])
  // MultiPoint uses &MultiGeometryTrait::coordArray implicitly
  inspect(mp.coord_array(), content="[{x: 1, y: 1}, {x: 2, y: 2}]")
}
```

### `Show`

#### `output`

| Variable | State | Note | 1 |
| :--- | :--- | :--- | :---: |
| `self` | `Valid` | | ✓ |

- Default implementation delegates to geometry_array show

```mbt check
///|
test {
  let mp = MultiPoint::new([Point::new(XY::new(1.0, 1.0))])
  let boxed : &MultiGeometryTrait = mp
  inspect(boxed, content="MultiPoint([Point({x: 1, y: 1})])")
}
```
