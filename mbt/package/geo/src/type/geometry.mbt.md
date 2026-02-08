# geometry.mbt

Defines the core behavior for all geometry types, including bounding box calculation (`bbox`), coordinate extraction (`coord_array`), and point generation (`point_array`).

## Public API

- `point_array` (default implementation)
- `bbox` (default implementation)
- `as_geometry_trait_object` (default implementation)

## Test

### `point_array`

| Variable | State   | Note |  1  |
| :------- | :------ | :--- | :-: |
| `self`   | `Valid` |      |  ✓  |

- Default implementation converts coords to Points

```mbt check
///|
test {
  let ls = LineString::new([XY::new(1.0, 1.0), XY::new(2.0, 2.0)])
  inspect(
    ls.point_array(),
    content="[Point({x: 1, y: 1}), Point({x: 2, y: 2})]",
  )
}
```

### `bbox`

| Variable | State   | Note |  1  |  2  |
| :------- | :------ | :--- | :-: | :-: |
| `self`   | `Empty` |      |  -  |  ✓  |
| `self`   | `Valid` |      |  ✓  |     |

- Default implementation calculates BBox from coords

```mbt check
///|
test {
  let ls = LineString::new([XY::new(1.0, 1.0), XY::new(2.0, 2.0)])
  inspect(ls.bbox(), content="{min: {x: 1, y: 1}, max: {x: 2, y: 2}}")
}
```

- Default implementation panics on empty coords (via coord_array_to_bbox)

```mbt check
///|
test "panic_GeometryTrait bbox - default empty" {
  (LineString::new([]) : LineString[XY]).bbox() |> ignore
}
```
