
# Feature

## Public API

- `Feature`
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
test "Feature new" {
  let feature = Feature::new(
    geometry=Some(Geometry::Point(Point::new(Coordinates::XY(1.0, 2.0)))),
  )
  inspect(
    feature,
    content="{geometry: Some(Point({coordinates: XY(1, 2)})), properties: None, id: None}",
  )
}
```

### BBoxTrait

#### bbox

```mbt check
///|
test "Feature BBoxTrait::bbox" {
  let feature = Feature::new(
    geometry=Some(Geometry::Point(Point::new(Coordinates::XY(1.0, 2.0)))),
  )
  inspect(feature.bbox(), content="BBox2D(1, 2, 1, 2)")
}
```

### GeoJSONTrait

#### to_json

- With BBox

```mbt check
///|
test "Feature GeoJSONTrait::to_json - With BBox" {
  let feature = Feature::new(
    geometry=Some(Geometry::Point(Point::new(Coordinates::XY(1.0, 2.0)))),
    properties=None,
    id=None,
  )
  let json = GeoJSONTrait::to_json(feature, with_bbox=true)
  json_inspect(json, content={
    "type": "Feature",
    "geometry": { "type": "Point", "coordinates": [1, 2] },
    "properties": null,
    "bbox": [1, 2, 1, 2],
  })
}
```

### ToJson

- Without BBox

```mbt check
///|
test "Feature ToJson::to_json - Without BBox" {
  let feature : Feature = @json.from_json({
    "type": "Feature",
    "geometry": { "type": "Point", "coordinates": [1.0, 2.0] },
    "properties": { "name": "test" },
    "id": "feature-1",
  })
  json_inspect(feature, content={
    "type": "Feature",
    "geometry": { "type": "Point", "coordinates": [1, 2] },
    "properties": { "name": "test" },
    "id": "feature-1",
  })
}
```

### FromJson

- With Geometry and Properties

```mbt check
///|
test "Feature FromJson::from_json - With Geometry and Properties" {
  let feature : Feature = @json.from_json({
    "type": "Feature",
    "geometry": { "type": "Point", "coordinates": [1.0, 2.0] },
    "properties": { "name": "test" },
  })
  inspect(
    feature,
    content=(
      #|{geometry: Some(Point({coordinates: XY(1, 2)})), properties: Some({"name": String("test")}), id: None}
    ),
  )
}
```

- Without Geometry and Properties

```mbt check
///|
test "Feature FromJson::from_json - Without Geometry and Properties" {
  let feature : Feature = @json.from_json({
    "type": "Feature",
    "geometry": null,
    "properties": null,
  })
  inspect(feature, content="{geometry: None, properties: None, id: None}")
}
```

- With ID

```mbt check
///|
test "Feature FromJson::from_json - With ID" {
  let feature : Feature = @json.from_json({
    "type": "Feature",
    "geometry": null,
    "properties": null,
    "id": "abc",
  })
  inspect(
    feature,
    content="{geometry: None, properties: None, id: Some(String(\"abc\"))}",
  )
}
```
