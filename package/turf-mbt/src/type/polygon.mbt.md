# polygon.mbt

Represents a closed area defined by an exterior boundary and optional interior holes.

## Public API

- `Polygon::new`
- `exterior`
- `interior_array`
- `coord_array`
- `bbox`

## Test

### `Polygon::new`

| Variable | State | Note | 1 | 2 |
| :--- | :--- | :--- | :---: | :---: |
| `exterior` | `Valid` | | ✓ | ✓ |
| `interior_array` | `Empty` | | ✓ | |
| `interior_array` | `Present` | | | ✓ |

- Exterior only

```mbt test
let exterior = LineString::new([
  XY::new(0.0, 0.0),
  XY::new(10.0, 0.0),
  XY::new(0.0, 10.0),
  XY::new(0.0, 0.0),
])
let polygon = Polygon::new(exterior)
inspect(
  polygon,
  content="{exterior: LineString([{x: 0, y: 0}, {x: 10, y: 0}, {x: 0, y: 10}, {x: 0, y: 0}]), interior_array: []}",
)
```

- With holes

```mbt test
let exterior = LineString::new([
  XY::new(0.0, 0.0),
  XY::new(10.0, 0.0),
  XY::new(10.0, 10.0),
  XY::new(0.0, 10.0),
  XY::new(0.0, 0.0),
])
let hole = LineString::new([
  XY::new(2.0, 2.0),
  XY::new(8.0, 2.0),
  XY::new(8.0, 8.0),
  XY::new(2.0, 8.0),
  XY::new(2.0, 2.0),
])
let polygon = Polygon::new(exterior, interior_array=[hole])
inspect(
  polygon,
  content="{exterior: LineString([{x: 0, y: 0}, {x: 10, y: 0}, {x: 10, y: 10}, {x: 0, y: 10}, {x: 0, y: 0}]), interior_array: [LineString([{x: 2, y: 2}, {x: 8, y: 2}, {x: 8, y: 8}, {x: 2, y: 8}, {x: 2, y: 2}])]}",
)
```

### `exterior`

- Getter

```mbt test
let exterior = LineString::new([
    XY::new(0.0, 0.0),
    XY::new(10.0, 0.0),
    XY::new(0.0, 10.0),
    XY::new(0.0, 0.0),
  ])
let polygon = Polygon::new(exterior)
inspect(
  polygon.exterior(),
  content="LineString([{x: 0, y: 0}, {x: 10, y: 0}, {x: 0, y: 10}, {x: 0, y: 0}])",
)
```

### `interior_array`

| Variable | State | Note | 1 | 2 |
| :--- | :--- | :--- | :---: | :---: |
| `self` | `Empty` | | ✓ | - |
| `self` | `Present` | | - | ✓ |

- Empty

```mbt test
let exterior = LineString::new([
  XY::new(0.0, 0.0),
  XY::new(10.0, 0.0),
  XY::new(0.0, 10.0),
  XY::new(0.0, 0.0),
])
let polygon = Polygon::new(exterior)
inspect(polygon.interior_array(), content="[]")
```

- Present

```mbt test
let exterior = LineString::new([
  XY::new(0.0, 0.0),
  XY::new(10.0, 0.0),
  XY::new(10.0, 10.0),
  XY::new(0.0, 10.0),
  XY::new(0.0, 0.0),
])
let hole = LineString::new([
  XY::new(2.0, 2.0),
  XY::new(8.0, 2.0),
  XY::new(8.0, 8.0),
  XY::new(2.0, 8.0),
  XY::new(2.0, 2.0),
])
let polygon = Polygon::new(exterior, interior_array=[hole])
inspect(
  polygon.interior_array(),
  content="[LineString([{x: 2, y: 2}, {x: 8, y: 2}, {x: 8, y: 8}, {x: 2, y: 8}, {x: 2, y: 2}])]",
)
```

### `coord_array`

- Flattened coordinates

```mbt test
let exterior = LineString::new([
  XY::new(0.0, 0.0),
  XY::new(10.0, 0.0),
  XY::new(0.0, 10.0),
])
let polygon = Polygon::new(exterior)
inspect(
  polygon.coord_array(),
  content="[{x: 0, y: 0}, {x: 10, y: 0}, {x: 0, y: 10}]",
)
```

### `bbox`

| Variable | State | Note | 1 | 2 |
| :--- | :--- | :--- | :---: | :---: |
| `self` | `Empty` | | - | ✓ |
| `self` | `Valid` | | ✓ | |

- Calculate BBox

```mbt test
let exterior = LineString::new([
  XY::new(0.0, 0.0),
  XY::new(10.0, 10.0),
  XY::new(0.0, 10.0),
])
let polygon = Polygon::new(exterior)
inspect(polygon.bbox(), content="{min: {x: 0, y: 0}, max: {x: 10, y: 10}}")
```

- Panic on empty coords

```mbt check
test "panic_Polygon bbox - empty coords" {
  (Polygon::new(LineString::new([])) : Polygon[XY]).bbox() |> ignore
}
```
