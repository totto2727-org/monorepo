
# LineString

## Public API

- `LineString`
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
test "LineString new" {
  let ls = LineString::new([
    Coordinates::XY(0.0, 0.0),
    Coordinates::XY(1.0, 1.0),
  ])
  inspect(ls, content="{coordinates: [XY(0, 0), XY(1, 1)]}")
}
```

### BBoxTrait

#### bbox

```mbt check
///|
test "LineString BBoxTrait::bbox" {
  let ls = LineString::new([
    Coordinates::XY(0.0, 0.0),
    Coordinates::XY(1.0, 1.0),
  ])
  inspect(ls.bbox(), content="BBox2D(0, 0, 1, 1)")
}
```

### GeoJSONTrait

#### to_json

```mbt check
///|
test "LineString GeoJSONTrait::to_json - with bbox" {
  let ls : LineString = @json.from_json({
    "type": "LineString",
    "coordinates": [[0.0, 0.0], [1.0, 1.0]],
  })
  let json = GeoJSONTrait::to_json(ls, with_bbox=true)
  json_inspect(json, content={
    "type": "LineString",
    "coordinates": [[0, 0], [1, 1]],
    "bbox": [0, 0, 1, 1],
  })
}
```

### ToJson

```mbt check
///|
test "LineString ToJson::to_json" {
  let ls : LineString = @json.from_json({
    "type": "LineString",
    "coordinates": [[0.0, 0.0], [1.0, 1.0]],
  })
  json_inspect(ls, content={
    "type": "LineString",
    "coordinates": [[0, 0], [1, 1]],
  })
}
```

### FromJson

- Valid

```mbt check
///|
test "LineString FromJson::from_json - valid" {
  let ls : LineString = @json.from_json({
    "type": "LineString",
    "coordinates": [[0.0, 0.0], [1.0, 1.0]],
  })
  inspect(ls, content="{coordinates: [XY(0, 0), XY(1, 1)]}")
}
```

- Invalid Length

```mbt check
///|
test "panic_LineString FromJson::from_json - invalid length" {
  let _ : LineString = @json.from_json({
    "type": "LineString",
    "coordinates": [[0.0, 0.0]],
  })

}
```
