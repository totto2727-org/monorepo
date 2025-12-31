# geojson

Original: <https://github.com/DefinitelyTyped/DefinitelyTyped/blob/6ac7ae07d4144eaf312094ddb680e0a591d88ff1/types/geojson/index.d.ts>
RFC: <https://www.rfc-editor.org/rfc/rfc7946>

## Status

Implemented the following types compliant with RFC 7946:

- [x] `Feature`
- [x] `FeatureCollection`
- [x] `Geometry`
  - [x] `Point`
  - [x] `MultiPoint`
  - [x] `LineString`
  - [x] `MultiLineString`
  - [x] `Polygon`
  - [x] `MultiPolygon`
  - [x] `GeometryCollection`
- [x] `Position`
- [x] `BBox`

All types implement `ToJson` and `FromJson` traits, enabling JSON serialization/deserialization.
