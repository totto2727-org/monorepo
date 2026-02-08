# GeoJSONType

## Public API

- `GeoJSONType`
  - `from_raw_geojson`
  - `ToJson`
    - `to_json`
  - `FromJson`
    - `from_json`

## Test

### from_raw_geojson

TODO

### ToJson

- Feature

```mbt check
///|
test "GeoJSONType ToJson::to_json - Feature" {
  json_inspect(GeoJSONType::Feature, content="Feature")
}
```

- FeatureCollection

```mbt check
///|
test "GeoJSONType ToJson::to_json - FeatureCollection" {
  json_inspect(GeoJSONType::FeatureCollection, content="FeatureCollection")
}
```

- Geometry

```mbt check
///|
test "GeoJSONType ToJson::to_json - Geometry" {
  json_inspect(GeoJSONType::Geometry(GeometryType::Point), content="Point")
}
```

### FromJson

- Feature

```mbt check
///|
test "GeoJSONType FromJson::from_json - Feature" {
  let t : GeoJSONType = @json.from_json("Feature")
  inspect(t, content="Feature")
}
```

- FeatureCollection

```mbt check
///|
test "GeoJSONType FromJson::from_json - FeatureCollection" {
  let t : GeoJSONType = @json.from_json("FeatureCollection")
  inspect(t, content="FeatureCollection")
}
```

- Geometry

```mbt check
///|
test "GeoJSONType FromJson::from_json - Geometry" {
  let t : GeoJSONType = @json.from_json("Point")
  inspect(t, content="Geometry(Point)")
}
```
