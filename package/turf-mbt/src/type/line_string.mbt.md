# line_string.mbt

Represents a sequence of points forming a path.

## Public API

- `LineString::new`
- `coord_array`
- `line_array`
- `bbox`

## Test

### `LineString::new`

- Simple initialization

```mbt test
let point1 = XY::new(0.0, 0.0)
let point2 = XY::new(1.0, 1.0)
let line_string = LineString::new([point1, point2])
inspect(line_string, content="LineString([{x: 0, y: 0}, {x: 1, y: 1}])")
```

### `coord_array`

- Getter

```mbt test
let point1 = XY::new(0.0, 0.0)
let point2 = XY::new(10.0, 10.0)
let line_string = LineString::new([point1, point2])
inspect(line_string.coord_array(), content="[{x: 0, y: 0}, {x: 10, y: 10}]")
```

### `line_array`

- Get lines as segments

```mbt test
let point1 = XY::new(0.0, 0.0)
let point2 = XY::new(10.0, 10.0)
let point3 = XY::new(20.0, 0.0)
let line_string = LineString::new([point1, point2, point3])
inspect(
  line_string.line_array(),
  content="[{start: {x: 0, y: 0}, end: {x: 10, y: 10}}, {start: {x: 10, y: 10}, end: {x: 20, y: 0}}]",
)
```

### `bbox`

| Variable | State | Note | 1 | 2 |
| :--- | :--- | :--- | :---: | :---: |
| `self` | `Empty` | | - | ✓ |
| `self` | `Valid` | | ✓ | |

- Calculate BBox

```mbt test
let point1 = XY::new(0.0, 0.0)
let point2 = XY::new(10.0, 10.0)
let point3 = XY::new(20.0, 0.0)
let line_string = LineString::new([point1, point2, point3])
inspect(
  line_string.bbox(),
  content="{min: {x: 0, y: 0}, max: {x: 20, y: 10}}",
)
```

- Panic on empty coordinates

```mbt check
test "panic_LineString bbox - empty coords" {
  (LineString::new([]) : LineString[XY]).bbox() |> ignore
}
```
