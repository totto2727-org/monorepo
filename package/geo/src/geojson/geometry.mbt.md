
# Geometry

## Public API

- `Geometry`
  - `BBoxTrait`
    - `bbox`
  - `GeoJSONTrait`
    - `to_json`
  - `ToJson`
    - `to_json`
  - `FromJson`
    - `from_json`

## Test

### BBoxTrait

#### bbox

```mbt check
///|
test "Geometry BBoxTrait::bbox" {
  let geom : Geometry = @json.from_json({
    "type": "Point",
    "coordinates": [1.0, 2.0],
  })
  inspect(geom.bbox(), content="BBox2D(1, 2, 1, 2)")
}
```

### GeoJSONTrait

#### to_json

- point with bbox

```mbt check
///|
test "Geometry GeoJSONTrait::to_json - point with bbox" {
  let geom : Geometry = @json.from_json({
    "type": "Point",
    "coordinates": [1.0, 2.0],
  })
  let json = GeoJSONTrait::to_json(geom, with_bbox=true)
  json_inspect(json, content={
    "type": "Point",
    "coordinates": [1, 2],
    "bbox": [1, 2, 1, 2],
  })
}
```

### ToJson

- Point

```mbt check
///|
test "Geometry ToJson::to_json - Point" {
  let geom : Geometry = @json.from_json({
    "type": "Point",
    "coordinates": [1.0, 2.0],
  })
  json_inspect(geom, content={ "type": "Point", "coordinates": [1, 2] })
}
```

- LineString

```mbt check
///|
test "Geometry ToJson::to_json - LineString" {
  let geom : Geometry = @json.from_json({
    "type": "LineString",
    "coordinates": [[0.0, 0.0], [1.0, 1.0]],
  })
  json_inspect(geom, content={
    "type": "LineString",
    "coordinates": [[0, 0], [1, 1]],
  })
}
```

### FromJson

- Point

```mbt check
///|
test "Geometry FromJson::from_json - Point" {
  let geom : Geometry = @json.from_json({
    "type": "Point",
    "coordinates": [1.0, 2.0],
  })
  inspect(geom, content="Point({coordinates: XY(1, 2)})")
}
```

- Polygon

```mbt check
///|
test "Geometry FromJson::from_json - Polygon" {
  let geom : Geometry = @json.from_json({
    "type": "Polygon",
    "coordinates": [[[0.0, 0.0], [1.0, 0.0], [1.0, 1.0], [0.0, 0.0]]],
  })
  match geom {
    Polygon(p) =>
      inspect(
        p,
        content="{coordinates: [[XY(0, 0), XY(1, 0), XY(1, 1), XY(0, 0)]]}",
      )
    _ => fail("Expected Polygon")
  }
}
```

- panic_InvalidType

```mbt check
///|
test "panic_Geometry FromJson::from_json - invalid type" {
  let _ : Geometry = @json.from_json({
    "type": "Invalid",
    "coordinates": [1.0, 2.0],
  })

}
```
