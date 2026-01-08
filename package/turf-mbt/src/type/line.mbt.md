# line.mbt

Represents a line segment defined by two points.

## Public API

- `Line::new`
- `start`
- `end`
- `coord_array`
- `bbox`

## Test

### `Line::new`

- Simple initialization

  ```mbt test
  let start = XY::new(0.0, 0.0)
  let end = XY::new(10.0, 5.0)
  let line = Line::new(start, end)
  inspect(line, content="{start: {x: 0, y: 0}, end: {x: 10, y: 5}}")
  ```

### `start`

- Getter

  ```mbt test
  let start = XY::new(1.0, 2.0)
  let end = XY::new(3.0, 4.0)
  let line = Line::new(start, end)
  inspect(line.start(), content="{x: 1, y: 2}")
  ```

### `end`

- Getter

  ```mbt test
  let start = XY::new(1.0, 2.0)
  let end = XY::new(3.0, 4.0)
  let line = Line::new(start, end)
  inspect(line.end(), content="{x: 3, y: 4}")
  ```

### `coord_array`

- Sequence of coords

  ```mbt test
  let start = XY::new(0.0, 0.0)
  let end = XY::new(10.0, 10.0)
  let line = Line::new(start, end)
  inspect(line.coord_array(), content="[{x: 0, y: 0}, {x: 10, y: 10}]")
  ```

### `bbox`

- Calculate BBox

  ```mbt test
  let start = XY::new(1.0, 5.0)
  let end = XY::new(4.0, 2.0)
  let line = Line::new(start, end)
  inspect(line.bbox(), content="{min: {x: 1, y: 2}, max: {x: 4, y: 5}}")
  ```
