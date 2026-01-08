# geometry_collection.mbt

Represents a heterogeneous collection of geometries.

## Public API

- `GeometryCollection::new`
- `coord_array`
- `geometry_array`
- `bbox`

## Test

### `GeometryCollection::new`

- Simple initialization

  ```mbt test
  let point = Point::new(XY::new(1.0, 1.0))
  let geometry_collection = GeometryCollection::new([point])
  inspect(
    geometry_collection.geometry_array(),
    content="[Point({x: 1, y: 1})]",
  )
  ```

### `coord_array`

- Getter for coordinates (mixed)

  ```mbt test
  let point = Point::new(XY::new(1.0, 1.0))
  let line_string = LineString::new([XY::new(2.0, 2.0), XY::new(3.0, 3.0)])
  let geometry_collection = GeometryCollection::new([point, line_string])
  inspect(
    geometry_collection.coord_array(),
    content="[{x: 1, y: 1}, {x: 2, y: 2}, {x: 3, y: 3}]",
  )
  ```

### `geometry_array`

- Getter for geometries

  ```mbt test
  let point = Point::new(XY::new(1.0, 1.0))
  let line_string = LineString::new([XY::new(2.0, 2.0), XY::new(3.0, 3.0)])
  let geometry_collection = GeometryCollection::new([point, line_string])
  inspect(
    geometry_collection.geometry_array(),
    content="[Point({x: 1, y: 1}), LineString([{x: 2, y: 2}, {x: 3, y: 3}])]",
  )
  ```

### `bbox`

| Variable | State | Note | 1 | 2 |
| :--- | :--- | :--- | :---: | :---: |
| `geoms` | `Empty` | | - | ✓ |
| `geoms` | `Valid` | | ✓ | |

- Calculate BBox

  ```mbt test
  let point = Point::new(XY::new(1.0, 1.0))
  let line_string = LineString::new([XY::new(2.0, 2.0), XY::new(3.0, 3.0)])
  let geometry_collection = GeometryCollection::new([point, line_string])
  inspect(
    geometry_collection.bbox(),
    content="{min: {x: 1, y: 1}, max: {x: 3, y: 3}}",
  )
  ```

- Panic on empty

  ```mbt check
  test "panic_GeometryCollection bbox - empty" {
    (GeometryCollection::new([]) : GeometryCollection).bbox() |> ignore
  }
  ```
