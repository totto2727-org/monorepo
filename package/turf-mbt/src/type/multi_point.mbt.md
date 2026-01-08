# multi_point.mbt

Represents a collection of points.

## Public API

- `MultiPoint::new`
- `coord_array`
- `geometry_array`
- `bbox`

## Test

### `MultiPoint::new`

- Simple initialization

```mbt test
let point1 = Point::new(XY::new(1.0, 1.0))
let multi_point = MultiPoint::new([point1])
inspect(multi_point, content="MultiPoint([Point({x: 1, y: 1})])")
```

### `coord_array`

- Getter for coordinates

```mbt test
let point1 = Point::new(XY::new(1.0, 1.0))
let point2 = Point::new(XY::new(2.0, 2.0))
let multi_point = MultiPoint::new([point1, point2])
inspect(multi_point.coord_array(), content="[{x: 1, y: 1}, {x: 2, y: 2}]")
```

### `geometry_array`

- Getter for geometries

```mbt test
let point1 = Point::new(XY::new(1.0, 1.0))
let multi_point = MultiPoint::new([point1])
inspect(multi_point.geometry_array(), content="[Point({x: 1, y: 1})]")
```

### `bbox`

| Variable | State | Note | 1 | 2 |
| :--- | :--- | :--- | :---: | :---: |
| `self` | `Empty` | | - | ✓ |
| `self` | `Valid` | | ✓ | |

- Calculate BBox

```mbt test
let point1 = Point::new(XY::new(1.0, 1.0))
let point2 = Point::new(XY::new(2.0, 2.0))
let multi_point = MultiPoint::new([point1, point2])
inspect(multi_point.bbox(), content="{min: {x: 1, y: 1}, max: {x: 2, y: 2}}")
```

- Panic on empty

```mbt check
test "panic_MultiPoint bbox - empty" {
  (MultiPoint::new([]) : MultiPoint[XY]).bbox() |> ignore
}
```
