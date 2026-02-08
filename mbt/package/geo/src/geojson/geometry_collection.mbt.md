# GeometryCollection

## Public API

- `GeometryCollection`
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
test "GeometryCollection new" {
  let gc = GeometryCollection::new([])
  inspect(gc, content="{geometries: []}")
}
```

### BBoxTrait

#### bbox

```mbt check
///|
test "GeometryCollection BBoxTrait::bbox" {
  let gc = GeometryCollection::new([
    Geometry::Point(Point::new(Coordinates::XY(0.0, 0.0))),
    Geometry::Point(Point::new(Coordinates::XY(10.0, 10.0))),
  ])
  inspect(gc.bbox(), content="BBox2D(0, 0, 10, 10)")
}
```

### GeoJSONTrait

#### to_json

```mbt check
///|
test "GeometryCollection GeoJSONTrait::to_json - With BBox" {
  let gc : GeometryCollection = @json.from_json({
    "type": "GeometryCollection",
    "geometries": [{ "type": "Point", "coordinates": [0.0, 0.0] }],
  })
  let json = GeoJSONTrait::to_json(gc, with_bbox=true)
  json_inspect(json, content={
    "type": "GeometryCollection",
    "geometries": [
      { "type": "Point", "coordinates": [0, 0], "bbox": [0, 0, 0, 0] },
    ],
    "bbox": [0, 0, 0, 0],
  })
}
```

### ToJson

```mbt check
///|
test "GeometryCollection ToJson::to_json" {
  let gc : GeometryCollection = @json.from_json({
    "type": "GeometryCollection",
    "geometries": [{ "type": "Point", "coordinates": [0.0, 0.0] }],
  })
  json_inspect(gc, content={
    "type": "GeometryCollection",
    "geometries": [{ "type": "Point", "coordinates": [0, 0] }],
  })
}
```

### FromJson

- Valid

```mbt check
///|
test "GeometryCollection FromJson::from_json - Valid" {
  let gc : GeometryCollection = @json.from_json({
    "type": "GeometryCollection",
    "geometries": [{ "type": "Point", "coordinates": [0.0, 0.0] }],
  })
  inspect(gc, content="{geometries: [Point({coordinates: XY(0, 0)})]}")
}
```

- Empty

```mbt check
///|
test "GeometryCollection FromJson::from_json - Empty" {
  let gc : GeometryCollection = @json.from_json({
    "type": "GeometryCollection",
    "geometries": [],
  })
  inspect(gc, content="{geometries: []}")
}
```
