# multi_line_string.mbt

Represents a collection of line strings.

## Public API

- `MultiLineString::new`
- `coord_array`
- `geometry_array`
- `bbox`

## Test

### `MultiLineString::new`

- Simple initialization

```mbt test
let line_string1 = LineString::new([XY::new(0.0, 0.0), XY::new(1.0, 1.0)])
let multi_line_string = MultiLineString::new([line_string1])
inspect(multi_line_string, content="MultiLineString([LineString([{x: 0, y: 0}, {x: 1, y: 1}])])")
```

### `coord_array`

- Getter for coordinates

```mbt test
let line_string1 = LineString::new([XY::new(0.0, 0.0), XY::new(1.0, 1.0)])
let line_string2 = LineString::new([XY::new(2.0, 2.0), XY::new(3.0, 3.0)])
let multi_line_string = MultiLineString::new([line_string1, line_string2])
inspect(
  multi_line_string.coord_array(),
  content="[{x: 0, y: 0}, {x: 1, y: 1}, {x: 2, y: 2}, {x: 3, y: 3}]",
)
```

### `geometry_array`

- Getter for geometries

```mbt test
let line_string1 = LineString::new([XY::new(0.0, 0.0), XY::new(1.0, 1.0)])
let multi_line_string = MultiLineString::new([line_string1])
inspect(multi_line_string.geometry_array(), content="[LineString([{x: 0, y: 0}, {x: 1, y: 1}])]")
```

### `bbox`

| Variable | State | Note | 1 | 2 |
| :--- | :--- | :--- | :---: | :---: |
| `self` | `Empty` | | - | ✓ |
| `self` | `Valid` | | ✓ | |

- Calculate BBox

```mbt test
let line_string1 = LineString::new([XY::new(0.0, 0.0), XY::new(1.0, 1.0)])
let line_string2 = LineString::new([XY::new(2.0, 2.0), XY::new(3.0, 3.0)])
let multi_line_string = MultiLineString::new([line_string1, line_string2])
inspect(
  multi_line_string.bbox(),
  content="{min: {x: 0, y: 0}, max: {x: 3, y: 3}}",
)
```

- Panic on empty

```mbt check
test "panic_MultiLineString bbox - empty" {
  (MultiLineString::new([]) : MultiLineString[XY]).bbox() |> ignore
}
```
