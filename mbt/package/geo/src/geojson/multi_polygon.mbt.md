# MultiPolygon

## Public API

- `MultiPolygon`
  - `new`
  - `BBoxTrait`
    - `bbox`
  - `GeoJSONTrait`
    - `to_json`
  - `ToJson`
    - `to_json`
  - `FromJson`
    - `from_json`

## Test

### new

```mbt check
///|
test "MultiPolygon new" {
  let mp = MultiPolygon::new([
    [
      [
        Coordinates::XY(0.0, 0.0),
        Coordinates::XY(1.0, 1.0),
        Coordinates::XY(0.0, 0.0),
      ],
    ],
  ])
  inspect(mp, content="{coordinates: [[[XY(0, 0), XY(1, 1), XY(0, 0)]]]}")
}
```

### BBoxTrait

#### bbox

```mbt check
///|
test "MultiPolygon BBoxTrait::bbox" {
  let mp = MultiPolygon::new([
    [
      [
        Coordinates::XY(0.0, 0.0),
        Coordinates::XY(1.0, 1.0),
        Coordinates::XY(0.0, 0.0),
      ],
    ],
  ])
  inspect(mp.bbox(), content="BBox2D(0, 0, 1, 1)")
}
```

### GeoJSONTrait

#### to_json

```mbt check
///|
test "MultiPolygon GeoJSONTrait::to_json - with bbox" {
  let multi_polyfill : MultiPolygon = @json.from_json({
    "type": "MultiPolygon",
    "coordinates": [[[[0.0, 0.0], [1.0, 0.0], [1.0, 1.0], [0.0, 0.0]]]],
  })
  let json = GeoJSONTrait::to_json(multi_polyfill, with_bbox=true)
  json_inspect(json, content={
    "type": "MultiPolygon",
    "coordinates": [[[[0, 0], [1, 0], [1, 1], [0, 0]]]],
    "bbox": [0, 0, 1, 1],
  })
}
```

### ToJson

```mbt check
///|
test "MultiPolygon ToJson::to_json" {
  let multi_polyfill : MultiPolygon = @json.from_json({
    "type": "MultiPolygon",
    "coordinates": [[[[0.0, 0.0], [1.0, 0.0], [1.0, 1.0], [0.0, 0.0]]]],
  })
  json_inspect(multi_polyfill, content={
    "type": "MultiPolygon",
    "coordinates": [[[[0, 0], [1, 0], [1, 1], [0, 0]]]],
  })
}
```

### FromJson

- Valid

```mbt check
///|
test "MultiPolygon FromJson::from_json - valid" {
  let multi_polyfill : MultiPolygon = @json.from_json({
    "type": "MultiPolygon",
    "coordinates": [[[[0.0, 0.0], [1.0, 0.0], [1.0, 1.0], [0.0, 0.0]]]],
  })
  inspect(
    multi_polyfill,
    content="{coordinates: [[[XY(0, 0), XY(1, 0), XY(1, 1), XY(0, 0)]]]}",
  )
}
```

- Empty

```mbt check
///|
test "MultiPolygon FromJson::from_json - empty" {
  let multi_polyfill : MultiPolygon = @json.from_json({
    "type": "MultiPolygon",
    "coordinates": [],
  })
  inspect(multi_polyfill, content="{coordinates: []}")
}
```
