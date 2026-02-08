
# GeometryType

## Public API

- `GeometryType`
  - `from_raw_geojson`
  - `ToJson`
    - `to_json`
  - `FromJson`
    - `from_json`

## Test

### ToJson

- point

```mbt check
///|
test "GeometryType ToJson::to_json - point" {
  json_inspect(GeometryType::Point, content="Point")
}
```

- line string

```mbt check
///|
test "GeometryType ToJson::to_json - line string" {
  json_inspect(GeometryType::LineString, content="LineString")
}
```

- polygon

```mbt check
///|
test "GeometryType ToJson::to_json - polygon" {
  json_inspect(GeometryType::Polygon, content="Polygon")
}
```

- multi point

```mbt check
///|
test "GeometryType ToJson::to_json - multi point" {
  json_inspect(GeometryType::MultiPoint, content="MultiPoint")
}
```

- multi line string

```mbt check
///|
test "GeometryType ToJson::to_json - multi line string" {
  json_inspect(GeometryType::MultiLineString, content="MultiLineString")
}
```

- multi polygon

```mbt check
///|
test "GeometryType ToJson::to_json - multi polygon" {
  json_inspect(GeometryType::MultiPolygon, content="MultiPolygon")
}
```

- geometry collection

```mbt check
///|
test "GeometryType ToJson::to_json - geometry collection" {
  json_inspect(GeometryType::GeometryCollection, content="GeometryCollection")
}
```

### FromJson

- point

```mbt check
///|
test "GeometryType FromJson::from_json - point" {
  let t : GeometryType = @json.from_json("Point")
  inspect(t, content="Point")
}
```

- line string

```mbt check
///|
test "GeometryType FromJson::from_json - line string" {
  let t : GeometryType = @json.from_json("LineString")
  inspect(t, content="LineString")
}
```

- polygon

```mbt check
///|
test "GeometryType FromJson::from_json - polygon" {
  let t : GeometryType = @json.from_json("Polygon")
  inspect(t, content="Polygon")
}
```

- multi point

```mbt check
///|
test "GeometryType FromJson::from_json - multi point" {
  let t : GeometryType = @json.from_json("MultiPoint")
  inspect(t, content="MultiPoint")
}
```

- multi line string

```mbt check
///|
test "GeometryType FromJson::from_json - multi line string" {
  let t : GeometryType = @json.from_json("MultiLineString")
  inspect(t, content="MultiLineString")
}
```

- multi polygon

```mbt check
///|
test "GeometryType FromJson::from_json - multi polygon" {
  let t : GeometryType = @json.from_json("MultiPolygon")
  inspect(t, content="MultiPolygon")
}
```

- geometry collection

```mbt check
///|
test "GeometryType FromJson::from_json - geometry collection" {
  let t : GeometryType = @json.from_json("GeometryCollection")
  inspect(t, content="GeometryCollection")
}
```

- panic_Invalid

```mbt check
///|
test "panic_GeometryType FromJson::from_json - invalid" {
  let _ : GeometryType = @json.from_json("Invalid")

}
```
