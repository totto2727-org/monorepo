<!-- markdownlint-disable no-duplicate-heading -->

# geojson.mbt

GeoJSON specification implementation for MoonBit. Provides types and serialization for GeoJSON objects including Points, LineStrings, Polygons, and their Multi variants, as well as Features and FeatureCollections.

## Public API

- `GeoJSON` - Top-level enum (FeatureCollection, Feature, Geometry)
- `FeatureCollection` - Collection of Features
- `Feature` - A feature with geometry, properties, and optional id
- `ID` - Feature identifier (String or Number)
- `Geometry` - Geometry enum (Point, LineString, Polygon, Multi*, GeometryCollection)
- `Point`, `LineString`, `Polygon` - Basic geometry types
- `MultiPoint`, `MultiLineString`, `MultiPolygon` - Multi geometry types
- `GeometryCollection` - Collection of geometries
- `GeoJSONType`, `GeometryType` - Type discriminators
- `BBox` - Bounding box (2D or 3D)
- `Coordinates` - Position (XY, XYZ_OR_XYM, XYZM)

## Test

### Coordinates

#### ToJson

- XY

```mbt check
///|
test {
  json_inspect(Coordinates::XY(1.0, 2.0), content=[1, 2])
}
```

- XYZ_OR_XYM

```mbt check
///|
test {
  json_inspect(Coordinates::XYZ_OR_XYM(1.0, 2.0, 3.0), content=[1, 2, 3])
}
```

- XYZM

```mbt check
///|
test {
  json_inspect(Coordinates::XYZM(1.0, 2.0, 3.0, 4.0), content=[1, 2, 3, 4])
}
```

#### FromJson

- XY

```mbt check
///|
test {
  let coordinates : Coordinates = @json.from_json([1.0, 2.0])
  inspect(coordinates, content="XY(1, 2)")
}
```

- XYZ_OR_XYM

```mbt check
///|
test {
  let coordinates : Coordinates = @json.from_json([1.0, 2.0, 3.0])
  inspect(coordinates, content="XYZ_OR_XYM(1, 2, 3)")
}
```

- XYZM

```mbt check
///|
test {
  let coordinates : Coordinates = @json.from_json([1.0, 2.0, 3.0, 4.0])
  inspect(coordinates, content="XYZM(1, 2, 3, 4)")
}
```

- panic_Invalid

```mbt check
///|
test "panic_Coordinates from_json" {
  let _ : Coordinates = @json.from_json([1.0])

}
```

#### x

```mbt check
///|
test {
  let coord = Coordinates::XY(1, 2)
  inspect(coord.x(), content="1")
}
```

#### y

```mbt check
///|
test "Coordinates y on XY" {
  let coord = Coordinates::XY(1, 2)
  inspect(coord.y(), content="2")
}
```

#### z

- non panic

```mbt check
///|
test "Coordinates z on XYZ_OR_XYM" {
  let coord = Coordinates::XYZ_OR_XYM(1, 2, 3)
  inspect(coord.z(), content="3")
}
```

- panic on XY

```mbt check
///|
test "panic_Coordinates z on XY" {
  let coord = Coordinates::XY(0.0, 0.0)
  coord.z() |> ignore
}
```

---

### BBox

#### ToJson

- BBox2D

```mbt check
///|
test {
  json_inspect(BBox::BBox2D(0.0, 1.0, 2.0, 3.0), content=[0, 1, 2, 3])
}
```

- BBox3D

```mbt check
///|
test {
  json_inspect(BBox::BBox3D(0.0, 1.0, 2.0, 3.0, 4.0, 5.0), content=[
    0, 1, 2, 3, 4, 5,
  ])
}
```

#### FromJson

- BBox2D

```mbt check
///|
test {
  let bbox : BBox = @json.from_json([0.0, 1.0, 2.0, 3.0])
  inspect(bbox, content="BBox2D(0, 1, 2, 3)")
}
```

- BBox3D

```mbt check
///|
test {
  let bbox : BBox = @json.from_json([0.0, 1.0, 2.0, 3.0, 4.0, 5.0])
  inspect(bbox, content="BBox3D(0, 1, 2, 3, 4, 5)")
}
```

- panic_Invalid

```mbt check
///|
test "panic_BBox from_json" {
  let _ : BBox = @json.from_json([0.0, 1.0])

}
```

#### new_2d

- non sorting

```mbt check
///|
test "BBox::new_2d sorting" {
  let bbox = BBox::new_2d(10.0, 20.0, 0.0, 5.0)
  inspect(bbox, content="BBox2D(0, 5, 10, 20)")
}
```

- sorting

```mbt check
///|
test "BBox::new_2d non-sorting" {
  let bbox = BBox::new_2d(0.0, 5.0, 10.0, 20.0)
  inspect(bbox, content="BBox2D(0, 5, 10, 20)")
}
```

#### new_3d

- sorting

```mbt check
///|
test "BBox::new_3d sorting" {
  let bbox = BBox::new_3d(10.0, 20.0, 30.0, 0.0, 5.0, 10.0)
  inspect(bbox, content="BBox3D(0, 5, 10, 10, 20, 30)")
}
```

- non sorting

```mbt check
///|
test "BBox::new_3d non-sorting" {
  let bbox = BBox::new_3d(0.0, 5.0, 10.0, 20.0, 30.0, 10.0)
  inspect(bbox, content="BBox3D(0, 5, 10, 20, 30, 10)")
}
```

#### from_coordinate_array

- 2D

```mbt check
///|
test "BBox::from_coordinate_array 2D" {
  let coords = [
    Coordinates::XY(0.0, 0.0),
    Coordinates::XY(10.0, 10.0),
    Coordinates::XY(5.0, 5.0),
  ]
  inspect(coords, content="[XY(0, 0), XY(10, 10), XY(5, 5)]")
}
```

- 3D

```mbt check
///|
test "BBox::from_coordinate_array 3D" {
  let coords = [
    Coordinates::XYZ_OR_XYM(0.0, 0.0, 0.0),
    Coordinates::XYZ_OR_XYM(10.0, 10.0, 10.0),
    Coordinates::XYZ_OR_XYM(5.0, 5.0, 5.0),
  ]
  inspect(
    coords,
    content="[XYZ_OR_XYM(0, 0, 0), XYZ_OR_XYM(10, 10, 10), XYZ_OR_XYM(5, 5, 5)]",
  )
}
```

- Empty

```mbt check
///|
test "panic_BBox from_coordinate_array empty" {
  let _ = BBox::from_coordinate_array([])

}
```

- Mixed dimensions

```mbt check
///|
test "panic_BBox from_coordinate_array mixed dimensions" {
  let coords = [
    Coordinates::XY(0.0, 0.0),
    Coordinates::XYZ_OR_XYM(0.0, 0.0, 0.0),
  ]
  let _ = BBox::from_coordinate_array(coords)

}
```

---

### GeometryType

#### ToJson

- Point

```mbt check
///|
test {
  json_inspect(GeometryType::Point, content="Point")
}
```

- LineString

```mbt check
///|
test {
  json_inspect(GeometryType::LineString, content="LineString")
}
```

- Polygon

```mbt check
///|
test {
  json_inspect(GeometryType::Polygon, content="Polygon")
}
```

- MultiPoint

```mbt check
///|
test {
  json_inspect(GeometryType::MultiPoint, content="MultiPoint")
}
```

- MultiLineString

```mbt check
///|
test {
  json_inspect(GeometryType::MultiLineString, content="MultiLineString")
}
```

- MultiPolygon

```mbt check
///|
test {
  json_inspect(GeometryType::MultiPolygon, content="MultiPolygon")
}
```

- GeometryCollection

```mbt check
///|
test {
  json_inspect(GeometryType::GeometryCollection, content="GeometryCollection")
}
```

#### FromJson

- Point

```mbt check
///|
test {
  let t : GeometryType = @json.from_json("Point")
  inspect(t, content="Point")
}
```

- LineString

```mbt check
///|
test {
  let t : GeometryType = @json.from_json("LineString")
  inspect(t, content="LineString")
}
```

- Polygon

```mbt check
///|
test {
  let t : GeometryType = @json.from_json("Polygon")
  inspect(t, content="Polygon")
}
```

- MultiPoint

```mbt check
///|
test {
  let t : GeometryType = @json.from_json("MultiPoint")
  inspect(t, content="MultiPoint")
}
```

- MultiLineString

```mbt check
///|
test {
  let t : GeometryType = @json.from_json("MultiLineString")
  inspect(t, content="MultiLineString")
}
```

- MultiPolygon

```mbt check
///|
test {
  let t : GeometryType = @json.from_json("MultiPolygon")
  inspect(t, content="MultiPolygon")
}
```

- GeometryCollection

```mbt check
///|
test {
  let t : GeometryType = @json.from_json("GeometryCollection")
  inspect(t, content="GeometryCollection")
}
```

- panic_Invalid

```mbt check
///|
test "panic_GeometryType from_json - invalid" {
  let _ : GeometryType = @json.from_json("Invalid")

}
```

---

### GeoJSONType

#### ToJson

- FeatureCollection

```mbt check
///|
test {
  json_inspect(GeoJSONType::FeatureCollection, content="FeatureCollection")
}
```

- Feature

```mbt check
///|
test {
  json_inspect(GeoJSONType::Feature, content="Feature")
}
```

- Geometry

```mbt check
///|
test {
  json_inspect(GeoJSONType::Geometry(GeometryType::Point), content="Point")
}
```

#### FromJson

- FeatureCollection

```mbt check
///|
test {
  let t : GeoJSONType = @json.from_json("FeatureCollection")
  inspect(t, content="FeatureCollection")
}
```

- Feature

```mbt check
///|
test {
  let t : GeoJSONType = @json.from_json("Feature")
  inspect(t, content="Feature")
}
```

- Geometry

```mbt check
///|
test {
  let t : GeoJSONType = @json.from_json("Point")
  inspect(t, content="Geometry(Point)")
}
```

- panic_Invalid

```mbt check
///|
test "panic_GeoJSONType from_json - invalid" {
  let _ : GeoJSONType = @json.from_json("Invalid")

}
```

---

### ID

#### ToJson

- String

```mbt check
///|
test {
  json_inspect(ID::String("abc"), content="abc")
}
```

- Number

```mbt check
///|
test {
  json_inspect(ID::Number(123.0), content=123)
}
```

#### FromJson

- String

```mbt check
///|
test {
  let id : ID = @json.from_json("abc")
  inspect(id, content="String(\"abc\")")
}
```

- Number

```mbt check
///|
test {
  let id : ID = @json.from_json(123.0)
  inspect(id, content="Number(123)")
}
```

- panic_Invalid

```mbt check
///|
test "panic_ID from_json - invalid" {
  let _ : ID = @json.from_json(true)

}
```

---

### Point

#### ToJson

```mbt check
///|
test {
  let point : Point = @json.from_json({
    "type": "Point",
    "coordinates": [1.0, 2.0],
  })
  json_inspect(point, content={ "type": "Point", "coordinates": [1, 2] })
}
```

#### FromJson

```mbt check
///|
test {
  let point : Point = @json.from_json({
    "type": "Point",
    "coordinates": [1.0, 2.0],
  })
  inspect(point, content="{coordinates: XY(1, 2)}")
}
```

---

### LineString

#### ToJson

```mbt check
///|
test {
  let line : LineString = @json.from_json({
    "type": "LineString",
    "coordinates": [[0.0, 0.0], [1.0, 1.0]],
  })
  json_inspect(line, content={
    "type": "LineString",
    "coordinates": [[0, 0], [1, 1]],
  })
}
```

#### FromJson

- Valid

```mbt check
///|
test {
  let line : LineString = @json.from_json({
    "type": "LineString",
    "coordinates": [[0.0, 0.0], [1.0, 1.0]],
  })
  inspect(line, content="{coordinates: [XY(0, 0), XY(1, 1)]}")
}
```

- panic_TooFewCoordinates

```mbt check
///|
test "panic_LineString from_json - too few coordinates" {
  let _ : LineString = @json.from_json({
    "type": "LineString",
    "coordinates": [[0.0, 0.0]],
  })

}
```

---

### Polygon

#### ToJson

```mbt check
///|
test {
  let polygon : Polygon = @json.from_json({
    "type": "Polygon",
    "coordinates": [[[0.0, 0.0], [1.0, 0.0], [1.0, 1.0], [0.0, 0.0]]],
  })
  json_inspect(polygon, content={
    "type": "Polygon",
    "coordinates": [[[0, 0], [1, 0], [1, 1], [0, 0]]],
  })
}
```

#### FromJson

- Valid

```mbt check
///|
test {
  let polygon : Polygon = @json.from_json({
    "type": "Polygon",
    "coordinates": [[[0.0, 0.0], [1.0, 0.0], [1.0, 1.0], [0.0, 0.0]]],
  })
  inspect(
    polygon,
    content="{coordinates: [[XY(0, 0), XY(1, 0), XY(1, 1), XY(0, 0)]]}",
  )
}
```

- panic_EmptyRings

```mbt check
///|
test "panic_Polygon from_json - empty rings" {
  let _ : Polygon = @json.from_json({ "type": "Polygon", "coordinates": [] })

}
```

- panic_TooFewPointsInRing

```mbt check
///|
test "panic_Polygon from_json - too few points in ring" {
  let _ : Polygon = @json.from_json({
    "type": "Polygon",
    "coordinates": [[[0.0, 0.0], [0.0, 0.0]]],
  })

}
```

- panic_RingNotClosed

```mbt check
///|
test "panic_Polygon from_json - ring not closed" {
  let _ : Polygon = @json.from_json({
    "type": "Polygon",
    "coordinates": [[[0.0, 0.0], [1.0, 0.0], [1.0, 1.0]]],
  })

}
```

---

### MultiPoint

#### ToJson

```mbt check
///|
test {
  let mp : MultiPoint = @json.from_json({
    "type": "MultiPoint",
    "coordinates": [[0.0, 0.0], [1.0, 1.0]],
  })
  json_inspect(mp, content={
    "type": "MultiPoint",
    "coordinates": [[0, 0], [1, 1]],
  })
}
```

#### FromJson

- Valid

```mbt check
///|
test {
  let mp : MultiPoint = @json.from_json({
    "type": "MultiPoint",
    "coordinates": [[0.0, 0.0]],
  })
  inspect(mp, content="{coordinates: [XY(0, 0)]}")
}
```

- Empty

```mbt check
///|
test {
  let mp : MultiPoint = @json.from_json({
    "type": "MultiPoint",
    "coordinates": [],
  })
  inspect(mp, content="{coordinates: []}")
}
```

---

### MultiLineString

#### ToJson

```mbt check
///|
test {
  let mls : MultiLineString = @json.from_json({
    "type": "MultiLineString",
    "coordinates": [[[0.0, 0.0], [1.0, 1.0]]],
  })
  json_inspect(mls, content={
    "type": "MultiLineString",
    "coordinates": [[[0, 0], [1, 1]]],
  })
}
```

#### FromJson

- Valid

```mbt check
///|
test {
  let mls : MultiLineString = @json.from_json({
    "type": "MultiLineString",
    "coordinates": [[[0.0, 0.0], [1.0, 1.0]]],
  })
  inspect(mls, content="{coordinates: [[XY(0, 0), XY(1, 1)]]}")
}
```

- Empty

```mbt check
///|
test {
  let mls : MultiLineString = @json.from_json({
    "type": "MultiLineString",
    "coordinates": [],
  })
  inspect(mls, content="{coordinates: []}")
}
```

---

### MultiPolygon

#### ToJson

```mbt check
///|
test {
  let multi_polyfill : MultiPolygon = @json.from_json({
    "type": "MultiPolygon",
    "coordinates": [[[[0.0, 0.0], [1.0, 0.0], [1.0, 1.0], [0.0, 0.0]]]],
  })
  json_inspect(multi_polyfill, content={
    "type": "MultiPolygon",
    "coordinates": [[[[0, 0], [1, 0], [1, 1], [0, 0]]]],
  })
}
```

#### FromJson

- Valid

```mbt check
///|
test {
  let multi_polyfill : MultiPolygon = @json.from_json({
    "type": "MultiPolygon",
    "coordinates": [[[[0.0, 0.0], [1.0, 0.0], [1.0, 1.0], [0.0, 0.0]]]],
  })
  inspect(
    multi_polyfill,
    content="{coordinates: [[[XY(0, 0), XY(1, 0), XY(1, 1), XY(0, 0)]]]}",
  )
}
```

- Empty

```mbt check
///|
test {
  let multi_polyfill : MultiPolygon = @json.from_json({
    "type": "MultiPolygon",
    "coordinates": [],
  })
  inspect(multi_polyfill, content="{coordinates: []}")
}
```

---

### GeometryCollection

#### ToJson

```mbt check
///|
test {
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

#### FromJson

- Valid

```mbt check
///|
test {
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
test {
  let gc : GeometryCollection = @json.from_json({
    "type": "GeometryCollection",
    "geometries": [],
  })
  inspect(gc, content="{geometries: []}")
}
```

---

### Geometry

#### ToJson

- Point

```mbt check
///|
test {
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
test {
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

#### FromJson

- Point

```mbt check
///|
test {
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
test {
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
test "panic_Geometry from_json - invalid type" {
  let _ : Geometry = @json.from_json({
    "type": "Invalid",
    "coordinates": [1.0, 2.0],
  })

}
```

---

### Feature

#### ToJson

- WithoutBBox

```mbt check
///|
test {
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

- WithBBox

```mbt check
///|
test "Feature::to_json with bbox" {
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

#### FromJson

- WithGeometryAndProperties

```mbt check
///|
test {
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

- WithoutGeometryAndProperties

```mbt check
///|
test {
  let feature : Feature = @json.from_json({
    "type": "Feature",
    "geometry": null,
    "properties": null,
  })
  inspect(feature, content="{geometry: None, properties: None, id: None}")
}
```

- WithId

```mbt check
///|
test {
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

---

### FeatureCollection

#### ToJson

```mbt check
///|
test {
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

#### FromJson

- WithFeatures

```mbt check
///|
test {
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
test {
  let fc : FeatureCollection = @json.from_json({
    "type": "FeatureCollection",
    "features": [],
  })
  inspect(fc, content="{features: []}")
}
```

---

### GeoJSON

#### ToJson

- FeatureCollection

```mbt check
///|
test {
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
test {
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
test {
  let geojson : GeoJSON = @json.from_json({
    "type": "Point",
    "coordinates": [1.0, 2.0],
  })
  json_inspect(geojson, content={ "type": "Point", "coordinates": [1, 2] })
}
```

#### FromJson

- FeatureCollection

```mbt check
///|
test {
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
test {
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
test {
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
test "panic_GeoJSON from_json - invalid type" {
  let _ : GeoJSON = @json.from_json({ "type": "Invalid" })

}
```
