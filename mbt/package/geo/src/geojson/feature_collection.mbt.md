# FeatureCollection

## Public API

- `FeatureCollection`
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
test "FeatureCollection new" {
  let fc = FeatureCollection::new([])
  inspect(fc, content="{features: []}")
}
```

### BBoxTrait

#### bbox

```mbt check
///|
test "FeatureCollection BBoxTrait::bbox" {
  let fc = FeatureCollection::new([
    Feature::new(
      geometry=Some(Geometry::Point(Point::new(Coordinates::XY(0.0, 0.0)))),
    ),
    Feature::new(
      geometry=Some(Geometry::Point(Point::new(Coordinates::XY(10.0, 10.0)))),
    ),
  ])
  inspect(fc.bbox(), content="BBox2D(0, 0, 10, 10)")
}
```

### GeoJSONTrait

#### to_json

- With BBox

```mbt check
///|
test "FeatureCollection GeoJSONTrait::to_json - With BBox" {
  let fc : FeatureCollection = @json.from_json({
    "type": "FeatureCollection",
    "features": [{ "type": "Feature", "geometry": null, "properties": null }],
  })
  let json = GeoJSONTrait::to_json(fc, with_bbox=true)
  json_inspect(json, content={
    "type": "FeatureCollection",
    "features": [{ "type": "Feature", "geometry": null, "properties": null }],
    "bbox": [0, 0, 0, 0],
  })
}
```

### ToJson

```mbt check
///|
test "FeatureCollection ToJson::to_json" {
  let fc : FeatureCollection = @json.from_json({
    "type": "FeatureCollection",
    "features": [{ "type": "Feature", "geometry": null, "properties": null }],
  })
  json_inspect(fc, content={
    "type": "FeatureCollection",
    "features": [{ "type": "Feature", "geometry": null, "properties": null }],
  })
}
```

### FromJson

- With Features

```mbt check
///|
test "FeatureCollection FromJson::from_json - With Features" {
  let fc : FeatureCollection = @json.from_json({
    "type": "FeatureCollection",
    "features": [{ "type": "Feature", "geometry": null, "properties": null }],
  })
  inspect(
    fc,
    content="{features: [{geometry: None, properties: None, id: None}]}",
  )
}
```

- Empty

```mbt check
///|
test "FeatureCollection FromJson::from_json - Empty" {
  let fc : FeatureCollection = @json.from_json({
    "type": "FeatureCollection",
    "features": [],
  })
  inspect(fc, content="{features: []}")
}
```
