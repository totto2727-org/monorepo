
# Polygon

## Public API

- `Polygon`
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
test "Polygon new" {
  let p = Polygon::new([
    [
      Coordinates::XY(0.0, 0.0),
      Coordinates::XY(1.0, 0.0),
      Coordinates::XY(1.0, 1.0),
      Coordinates::XY(0.0, 0.0),
    ],
  ])
  inspect(
    p,
    content="{coordinates: [[XY(0, 0), XY(1, 0), XY(1, 1), XY(0, 0)]]}",
  )
}
```

### BBoxTrait

#### bbox

```mbt check
///|
test "Polygon BBoxTrait::bbox" {
  let p = Polygon::new([
    [
      Coordinates::XY(0.0, 0.0),
      Coordinates::XY(1.0, 0.0),
      Coordinates::XY(1.0, 1.0),
      Coordinates::XY(0.0, 0.0),
    ],
  ])
  inspect(p.bbox(), content="BBox2D(0, 0, 1, 1)")
}
```

### GeoJSONTrait

#### to_json

```mbt check
///|
test "Polygon GeoJSONTrait::to_json - with bbox" {
  let poly : Polygon = @json.from_json({
    "type": "Polygon",
    "coordinates": [[[0.0, 0.0], [1.0, 0.0], [1.0, 1.0], [0.0, 0.0]]],
  })
  let json = GeoJSONTrait::to_json(poly, with_bbox=true)
  json_inspect(json, content={
    "type": "Polygon",
    "coordinates": [[[0, 0], [1, 0], [1, 1], [0, 0]]],
    "bbox": [0, 0, 1, 1],
  })
}
```

### ToJson

```mbt check
///|
test "Polygon ToJson::to_json" {
  let poly : Polygon = @json.from_json({
    "type": "Polygon",
    "coordinates": [[[0.0, 0.0], [1.0, 0.0], [1.0, 1.0], [0.0, 0.0]]],
  })
  json_inspect(poly, content={
    "type": "Polygon",
    "coordinates": [[[0, 0], [1, 0], [1, 1], [0, 0]]],
  })
}
```

### FromJson

- Valid

```mbt check
///|
test "Polygon FromJson::from_json - valid" {
  let poly : Polygon = @json.from_json({
    "type": "Polygon",
    "coordinates": [[[0.0, 0.0], [1.0, 0.0], [1.0, 1.0], [0.0, 0.0]]],
  })
  inspect(
    poly,
    content="{coordinates: [[XY(0, 0), XY(1, 0), XY(1, 1), XY(0, 0)]]}",
  )
}
```

- Invalid Ring Count

```mbt check
///|
test "panic_Polygon FromJson::from_json - invalid ring count" {
  let _ : Polygon = @json.from_json({ "type": "Polygon", "coordinates": [] })

}
```

- Invalid Ring Size

```mbt check
///|
test "panic_Polygon FromJson::from_json - invalid ring size" {
  let _ : Polygon = @json.from_json({
    "type": "Polygon",
    "coordinates": [[[0.0, 0.0], [1.0, 1.0]]],
  })

}
```

- Open Ring

```mbt check
///|
test "panic_Polygon FromJson::from_json - open ring" {
  let _ : Polygon = @json.from_json({
    "type": "Polygon",
    "coordinates": [[[0.0, 0.0], [1.0, 0.0], [1.0, 1.0], [0.0, 1.0]]],
  })

}
```
