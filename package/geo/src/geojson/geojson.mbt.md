
# GeoJSON

## Public API

- `FromGeoJSON`
  - `from_geojson_geometry`
- `ToGeoJSON`
  - `to_geojson`
- `GeoJSON`
  - `BBoxTrait`
    - `bbox`
  - `GeoJSONTrait`
    - `to_json`
  - `ToJson`
    - `to_json`
  - `FromJson`
    - `from_json`
- `GeoJSONTrait`
  - `to_json`

## Test

### BBoxTrait

#### bbox

```mbt check
///|
test "GeoJSON BBoxTrait::bbox" {
  let geojson : GeoJSON = @json.from_json({
    "type": "Point",
    "coordinates": [1.0, 2.0],
  })
  inspect(geojson.bbox(), content="BBox2D(1, 2, 1, 2)")
}
```

### GeoJSONTrait

#### to_json

- FeatureCollection

```mbt check
///|
test "GeoJSON GeoJSONTrait::to_json - FeatureCollection With BBox" {
  let geojson : GeoJSON = @json.from_json({
    "type": "FeatureCollection",
    "features": [],
  })
  let json = GeoJSONTrait::to_json(geojson, with_bbox=true)
  json_inspect(json, content={
    "type": "FeatureCollection",
    "features": [],
    "bbox": [0, 0, 0, 0],
  })
}
```

- Feature

```mbt check
///|
test "GeoJSON GeoJSONTrait::to_json - Feature With BBox" {
  let geojson : GeoJSON = @json.from_json({
    "type": "Feature",
    "geometry": null,
    "properties": null,
  })
  let json = GeoJSONTrait::to_json(geojson, with_bbox=true)
  json_inspect(json, content={
    "type": "Feature",
    "geometry": null,
    "properties": null,
    "bbox": [0, 0, 0, 0],
  })
}
```

- Geometry

```mbt check
///|
test "GeoJSON GeoJSONTrait::to_json - Geometry With BBox" {
  let geojson : GeoJSON = @json.from_json({
    "type": "Point",
    "coordinates": [1.0, 2.0],
  })
  let json = GeoJSONTrait::to_json(geojson, with_bbox=true)
  json_inspect(json, content={
    "type": "Point",
    "coordinates": [1, 2],
    "bbox": [1, 2, 1, 2],
  })
}
```

### ToJson

- FeatureCollection

```mbt check
///|
test "GeoJSON ToJson::to_json - FeatureCollection" {
  let geojson : GeoJSON = @json.from_json({
    "type": "FeatureCollection",
    "features": [],
  })
  json_inspect(geojson, content={ "type": "FeatureCollection", "features": [] })
}
```

- Feature

```mbt check
///|
test "GeoJSON ToJson::to_json - Feature" {
  let geojson : GeoJSON = @json.from_json({
    "type": "Feature",
    "geometry": null,
    "properties": null,
  })
  json_inspect(geojson, content={
    "type": "Feature",
    "geometry": null,
    "properties": null,
  })
}
```

- Geometry

```mbt check
///|
test "GeoJSON ToJson::to_json - Geometry" {
  let geojson : GeoJSON = @json.from_json({
    "type": "Point",
    "coordinates": [1.0, 2.0],
  })
  json_inspect(geojson, content={ "type": "Point", "coordinates": [1, 2] })
}
```

### FromJson

- FeatureCollection

```mbt check
///|
test "GeoJSON FromJson::from_json - FeatureCollection" {
  let geojson : GeoJSON = @json.from_json({
    "type": "FeatureCollection",
    "features": [],
  })
  inspect(geojson, content="FeatureCollection({features: []})")
}
```

- Feature

```mbt check
///|
test "GeoJSON FromJson::from_json - Feature" {
  let geojson : GeoJSON = @json.from_json({
    "type": "Feature",
    "geometry": null,
    "properties": null,
  })
  inspect(
    geojson,
    content="Feature({geometry: None, properties: None, id: None})",
  )
}
```

- Geometry

```mbt check
///|
test "GeoJSON FromJson::from_json - Geometry" {
  let geojson : GeoJSON = @json.from_json({
    "type": "Point",
    "coordinates": [1.0, 2.0],
  })
  inspect(geojson, content="Geometry(Point({coordinates: XY(1, 2)}))")
}
```

- panic_InvalidType

```mbt check
///|
test "panic_GeoJSON FromJson::from_json - Invalid Type" {
  let _ : GeoJSON = @json.from_json({ "type": "Invalid" })

}
```
