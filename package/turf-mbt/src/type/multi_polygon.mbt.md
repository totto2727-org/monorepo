# multi_polygon.mbt

Represents a collection of polygons.

## Public API

- `MultiPolygon::new`
- `coord_array`
- `geometry_array`
- `bbox`

## Test

### `MultiPolygon::new`

- Simple initialization

  ```mbt test
  let exterior = LineString::new([
    XY::new(0.0, 0.0),
    XY::new(10.0, 0.0),
    XY::new(0.0, 10.0),
    XY::new(0.0, 0.0),
  ])
  let polygon1 = Polygon::new(exterior)
  let multi_polygon = MultiPolygon::new([polygon1])
  inspect(
    multi_polygon,
    content="MultiPolygon([{exterior: LineString([{x: 0, y: 0}, {x: 10, y: 0}, {x: 0, y: 10}, {x: 0, y: 0}]), interior_array: []}])",
  )
  ```

### `coord_array`

- Getter for coordinates

  ```mbt test
  let exterior = LineString::new([
    XY::new(0.0, 0.0),
    XY::new(10.0, 0.0),
    XY::new(0.0, 10.0),
    XY::new(0.0, 0.0),
  ])
  let polygon1 = Polygon::new(exterior)
  let multi_polygon = MultiPolygon::new([polygon1])
  inspect(
    multi_polygon.coord_array(),
    content="[{x: 0, y: 0}, {x: 10, y: 0}, {x: 0, y: 10}, {x: 0, y: 0}]",
  )
  ```

### `geometry_array`

- Getter for geometries

  ```mbt test
  let exterior = LineString::new([
    XY::new(0.0, 0.0),
    XY::new(10.0, 0.0),
    XY::new(0.0, 10.0),
    XY::new(0.0, 0.0),
  ])
  let polygon1 = Polygon::new(exterior)
  let multi_polygon = MultiPolygon::new([polygon1])
  inspect(
    multi_polygon.geometry_array(),
    content="[{exterior: LineString([{x: 0, y: 0}, {x: 10, y: 0}, {x: 0, y: 10}, {x: 0, y: 0}]), interior_array: []}]",
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
    XY::new(10.0, 0.0),
    XY::new(0.0, 10.0),
    XY::new(0.0, 0.0),
  ])
  let polygon1 = Polygon::new(exterior)
  let multi_polygon = MultiPolygon::new([polygon1])
  inspect(
    multi_polygon.bbox(),
    content="{min: {x: 0, y: 0}, max: {x: 10, y: 10}}",
  )
  ```

- Panic on empty

  ```mbt check
  test "panic_MultiPolygon bbox - empty" {
    (MultiPolygon::new([]) : MultiPolygon[XY]).bbox() |> ignore
  }
  ```
