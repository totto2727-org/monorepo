
# MultiLineString

## Public API

- `MultiLineString`
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
test "MultiLineString new" {
  let mls = MultiLineString::new([
    [Coordinates::XY(0.0, 0.0), Coordinates::XY(1.0, 1.0)],
  ])
  inspect(mls, content="{coordinates: [[XY(0, 0), XY(1, 1)]]}")
}
```

### BBoxTrait

#### bbox

```mbt check
///|
test "MultiLineString BBoxTrait::bbox" {
  let mls = MultiLineString::new([
    [Coordinates::XY(0.0, 0.0), Coordinates::XY(1.0, 1.0)],
  ])
  inspect(mls.bbox(), content="BBox2D(0, 0, 1, 1)")
}
```

### GeoJSONTrait

#### to_json

```mbt check
///|
test "MultiLineString GeoJSONTrait::to_json - with bbox" {
  let mls : MultiLineString = @json.from_json({
    "type": "MultiLineString",
    "coordinates": [[[0.0, 0.0], [1.0, 1.0]]],
  })
  let json = GeoJSONTrait::to_json(mls, with_bbox=true)
  json_inspect(json, content={
    "type": "MultiLineString",
    "coordinates": [[[0, 0], [1, 1]]],
    "bbox": [0, 0, 1, 1],
  })
}
```

### ToJson

```mbt check
///|
test "MultiLineString ToJson::to_json" {
  let mls : MultiLineString = @json.from_json({
    "type": "MultiLineString",
    "coordinates": [[[0.0, 0.0], [1.0, 1.0]]],
  })
  json_inspect(mls, content={
    "type": "MultiLineString",
    "coordinates": [[[0, 0], [1, 1]]],
  })
}
```

### FromJson

- Valid

```mbt check
///|
test "MultiLineString FromJson::from_json - valid" {
  let mls : MultiLineString = @json.from_json({
    "type": "MultiLineString",
    "coordinates": [[[0.0, 0.0], [1.0, 1.0]]],
  })
  inspect(mls, content="{coordinates: [[XY(0, 0), XY(1, 1)]]}")
}
```

- Empty

```mbt check
///|
test "MultiLineString FromJson::from_json - empty" {
  let mls : MultiLineString = @json.from_json({
    "type": "MultiLineString",
    "coordinates": [],
  })
  inspect(mls, content="{coordinates: []}")
}
```
