
# MultiPoint

## Public API

- `MultiPoint`
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
test "MultiPoint new" {
  let mp = MultiPoint::new([
    Coordinates::XY(0.0, 0.0),
    Coordinates::XY(1.0, 1.0),
  ])
  inspect(mp, content="{coordinates: [XY(0, 0), XY(1, 1)]}")
}
```

### BBoxTrait

#### bbox

```mbt check
///|
test "MultiPoint BBoxTrait::bbox" {
  let mp = MultiPoint::new([
    Coordinates::XY(0.0, 0.0),
    Coordinates::XY(1.0, 1.0),
  ])
  inspect(mp.bbox(), content="BBox2D(0, 0, 1, 1)")
}
```

### GeoJSONTrait

#### to_json

```mbt check
///|
test "MultiPoint GeoJSONTrait::to_json - with bbox" {
  let mp : MultiPoint = @json.from_json({
    "type": "MultiPoint",
    "coordinates": [[0.0, 0.0], [1.0, 1.0]],
  })
  let json = GeoJSONTrait::to_json(mp, with_bbox=true)
  json_inspect(json, content={
    "type": "MultiPoint",
    "coordinates": [[0, 0], [1, 1]],
    "bbox": [0, 0, 1, 1],
  })
}
```

### ToJson

```mbt check
///|
test "MultiPoint ToJson::to_json" {
  let mp : MultiPoint = @json.from_json({
    "type": "MultiPoint",
    "coordinates": [[0.0, 0.0], [1.0, 1.0]],
  })
  json_inspect(mp, content={
    "type": "MultiPoint",
    "coordinates": [[0, 0], [1, 1]],
  })
}
```

### FromJson

- Valid

```mbt check
///|
test "MultiPoint FromJson::from_json - valid" {
  let mp : MultiPoint = @json.from_json({
    "type": "MultiPoint",
    "coordinates": [[0.0, 0.0]],
  })
  inspect(mp, content="{coordinates: [XY(0, 0)]}")
}
```

- Empty

```mbt check
///|
test "MultiPoint FromJson::from_json - empty" {
  let mp : MultiPoint = @json.from_json({
    "type": "MultiPoint",
    "coordinates": [],
  })
  inspect(mp, content="{coordinates: []}")
}
```
