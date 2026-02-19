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

- Point With BBox

```mbt check
///|
test "Geometry GeoJSONTrait::to_json - Point With BBox" {
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

- LineString With BBox

```mbt check
///|
test "Geometry GeoJSONTrait::to_json - LineString With BBox" {
  let geom : Geometry = @json.from_json({
    "type": "LineString",
    "coordinates": [[0.0, 0.0], [1.0, 1.0]],
  })
  let json = GeoJSONTrait::to_json(geom, with_bbox=true)
  json_inspect(json, content={
    "type": "LineString",
    "coordinates": [[0, 0], [1, 1]],
    "bbox": [0, 0, 1, 1],
  })
}
```

- Polygon With BBox

```mbt check
///|
test "Geometry GeoJSONTrait::to_json - Polygon With BBox" {
  let geom : Geometry = @json.from_json({
    "type": "Polygon",
    "coordinates": [[[0.0, 0.0], [1.0, 0.0], [1.0, 1.0], [0.0, 0.0]]],
  })
  let json = GeoJSONTrait::to_json(geom, with_bbox=true)
  json_inspect(json, content={
    "type": "Polygon",
    "coordinates": [[[0, 0], [1, 0], [1, 1], [0, 0]]],
    "bbox": [0, 0, 1, 1],
  })
}
```

- MultiPoint With BBox

```mbt check
///|
test "Geometry GeoJSONTrait::to_json - MultiPoint With BBox" {
  let geom : Geometry = @json.from_json({
    "type": "MultiPoint",
    "coordinates": [[0.0, 0.0], [1.0, 1.0]],
  })
  let json = GeoJSONTrait::to_json(geom, with_bbox=true)
  json_inspect(json, content={
    "type": "MultiPoint",
    "coordinates": [[0, 0], [1, 1]],
    "bbox": [0, 0, 1, 1],
  })
}
```

- MultiLineString With BBox

```mbt check
///|
test "Geometry GeoJSONTrait::to_json - MultiLineString With BBox" {
  let geom : Geometry = @json.from_json({
    "type": "MultiLineString",
    "coordinates": [[[0.0, 0.0], [1.0, 1.0]]],
  })
  let json = GeoJSONTrait::to_json(geom, with_bbox=true)
  json_inspect(json, content={
    "type": "MultiLineString",
    "coordinates": [[[0, 0], [1, 1]]],
    "bbox": [0, 0, 1, 1],
  })
}
```

- MultiPolygon With BBox

```mbt check
///|
test "Geometry GeoJSONTrait::to_json - MultiPolygon With BBox" {
  let geom : Geometry = @json.from_json({
    "type": "MultiPolygon",
    "coordinates": [[[[0.0, 0.0], [1.0, 0.0], [1.0, 1.0], [0.0, 0.0]]]],
  })
  let json = GeoJSONTrait::to_json(geom, with_bbox=true)
  json_inspect(json, content={
    "type": "MultiPolygon",
    "coordinates": [[[[0, 0], [1, 0], [1, 1], [0, 0]]]],
    "bbox": [0, 0, 1, 1],
  })
}
```

- GeometryCollection With BBox

```mbt check
///|
test "Geometry GeoJSONTrait::to_json - GeometryCollection With BBox" {
  let geom : Geometry = @json.from_json({
    "type": "GeometryCollection",
    "geometries": [{ "type": "Point", "coordinates": [0.0, 0.0] }],
  })
  let json = GeoJSONTrait::to_json(geom, with_bbox=true)
  json_inspect(json, content={
    "type": "GeometryCollection",
    "geometries": [
      { "type": "Point", "coordinates": [0, 0], "bbox": [0, 0, 0, 0] },
    ],
    "bbox": [0, 0, 0, 0],
  })
}
```

- Point Without BBox

```mbt check
///|
test "Geometry GeoJSONTrait::to_json - Point Without BBox" {
  let geom : Geometry = @json.from_json({
    "type": "Point",
    "coordinates": [1.0, 2.0],
  })
  let json = GeoJSONTrait::to_json(geom, with_bbox=false)
  json_inspect(json, content={ "type": "Point", "coordinates": [1, 2] })
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

- Polygon

```mbt check
///|
test "Geometry ToJson::to_json - Polygon" {
  let geom : Geometry = @json.from_json({
    "type": "Polygon",
    "coordinates": [[[0.0, 0.0], [1.0, 0.0], [1.0, 1.0], [0.0, 0.0]]],
  })
  json_inspect(geom, content={
    "type": "Polygon",
    "coordinates": [[[0, 0], [1, 0], [1, 1], [0, 0]]],
  })
}
```

- MultiPoint

```mbt check
///|
test "Geometry ToJson::to_json - MultiPoint" {
  let geom : Geometry = @json.from_json({
    "type": "MultiPoint",
    "coordinates": [[0.0, 0.0], [1.0, 1.0]],
  })
  json_inspect(geom, content={
    "type": "MultiPoint",
    "coordinates": [[0, 0], [1, 1]],
  })
}
```

- MultiLineString

```mbt check
///|
test "Geometry ToJson::to_json - MultiLineString" {
  let geom : Geometry = @json.from_json({
    "type": "MultiLineString",
    "coordinates": [[[0.0, 0.0], [1.0, 1.0]]],
  })
  json_inspect(geom, content={
    "type": "MultiLineString",
    "coordinates": [[[0, 0], [1, 1]]],
  })
}
```

- MultiPolygon

```mbt check
///|
test "Geometry ToJson::to_json - MultiPolygon" {
  let geom : Geometry = @json.from_json({
    "type": "MultiPolygon",
    "coordinates": [[[[0.0, 0.0], [1.0, 0.0], [1.0, 1.0], [0.0, 0.0]]]],
  })
  json_inspect(geom, content={
    "type": "MultiPolygon",
    "coordinates": [[[[0, 0], [1, 0], [1, 1], [0, 0]]]],
  })
}
```

- GeometryCollection

```mbt check
///|
test "Geometry ToJson::to_json - GeometryCollection" {
  let geom : Geometry = @json.from_json({
    "type": "GeometryCollection",
    "geometries": [{ "type": "Point", "coordinates": [0.0, 0.0] }],
  })
  json_inspect(geom, content={
    "type": "GeometryCollection",
    "geometries": [{ "type": "Point", "coordinates": [0, 0] }],
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

- LineString

```mbt check
///|
test "Geometry FromJson::from_json - LineString" {
  let geom : Geometry = @json.from_json({
    "type": "LineString",
    "coordinates": [[0.0, 0.0], [1.0, 1.0]],
  })
  inspect(geom, content="LineString({coordinates: [XY(0, 0), XY(1, 1)]})")
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

- MultiPoint

```mbt check
///|
test "Geometry FromJson::from_json - MultiPoint" {
  let geom : Geometry = @json.from_json({
    "type": "MultiPoint",
    "coordinates": [[0.0, 0.0], [1.0, 1.0]],
  })
  inspect(geom, content="MultiPoint({coordinates: [XY(0, 0), XY(1, 1)]})")
}
```

- MultiLineString

```mbt check
///|
test "Geometry FromJson::from_json - MultiLineString" {
  let geom : Geometry = @json.from_json({
    "type": "MultiLineString",
    "coordinates": [[[0.0, 0.0], [1.0, 1.0]]],
  })
  inspect(
    geom,
    content="MultiLineString({coordinates: [[XY(0, 0), XY(1, 1)]]})",
  )
}
```

- MultiPolygon

```mbt check
///|
test "Geometry FromJson::from_json - MultiPolygon" {
  let geom : Geometry = @json.from_json({
    "type": "MultiPolygon",
    "coordinates": [[[[0.0, 0.0], [1.0, 0.0], [1.0, 1.0], [0.0, 0.0]]]],
  })
  inspect(
    geom,
    content="MultiPolygon({coordinates: [[[XY(0, 0), XY(1, 0), XY(1, 1), XY(0, 0)]]]})",
  )
}
```

- GeometryCollection

```mbt check
///|
test "Geometry FromJson::from_json - GeometryCollection" {
  let geom : Geometry = @json.from_json({
    "type": "GeometryCollection",
    "geometries": [{ "type": "Point", "coordinates": [0.0, 0.0] }],
  })
  inspect(
    geom,
    content="GeometryCollection({geometries: [Point({coordinates: XY(0, 0)})]})",
  )
}
```

- Invalid Type

```mbt check
///|
test "panic_Geometry FromJson::from_json - Invalid Type" {
  let _ : Geometry = @json.from_json({
    "type": "Invalid",
    "coordinates": [1.0, 2.0],
  })
}
```
