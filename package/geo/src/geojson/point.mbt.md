
# Point

## Public API

- `Point`
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
test "Point new" {
  let p = Point::new(Coordinates::XY(1.0, 2.0))
  inspect(p, content="{coordinates: XY(1, 2)}")
}
```

### BBoxTrait

#### bbox

```mbt check
///|
test "Point BBoxTrait::bbox" {
  let p = Point::new(Coordinates::XY(1.0, 2.0))
  inspect(p.bbox(), content="BBox2D(1, 2, 1, 2)")
}
```

### GeoJSONTrait

#### to_json

```mbt check
///|
test "Point GeoJSONTrait::to_json - with bbox" {
  let p = Point::new(Coordinates::XY(1.0, 2.0))
  let json = GeoJSONTrait::to_json(p, with_bbox=true)
  json_inspect(json, content={
    "type": "Point",
    "coordinates": [1, 2],
    "bbox": [1, 2, 1, 2],
  })
}
```

### ToJson

```mbt check
///|
test "Point ToJson::to_json" {
  let p = Point::new(Coordinates::XY(1.0, 2.0))
  json_inspect(p, content={ "type": "Point", "coordinates": [1, 2] })
}
```

### FromJson

- Valid

```mbt check
///|
test "Point FromJson::from_json - valid" {
  let p : Point = @json.from_json({ "type": "Point", "coordinates": [1.0, 2.0] })
  inspect(p, content="{coordinates: XY(1, 2)}")
}
```

- Invalid Coordinates

```mbt check
///|
test "panic_Point FromJson::from_json - invalid coordinates" {
  let _ : Point = @json.from_json({ "type": "Point", "coordinates": [1.0] })

}
```
