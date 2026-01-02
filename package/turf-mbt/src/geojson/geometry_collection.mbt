///|
/// GeometryCollection geometry object.
/// https://tools.ietf.org/html/rfc7946#section-3.1.8
///
/// To maximize interoperability, implementations SHOULD avoid nested GeometryCollections.
/// Furthermore, GeometryCollections SHOULD avoid a structure that has only a single member,
/// and implementations SHOULD avoid nesting other Geometry types within a GeometryCollection
/// when a more specific Geometry type is available.
pub struct GeometryCollection {
  geometries : Array[Geometry]
  bbox : BBox?
} derive(Show, Eq, Compare, Hash)

///|
pub fn GeometryCollection::new(
  geometries : Array[Geometry],
  bbox? : BBox? = None,
) -> GeometryCollection {
  GeometryCollection::{ geometries, bbox }
}

///|
pub impl GeometryToBBox for GeometryCollection with to_bbox(
  self,
  re_compute? = false,
) {
  match (self.bbox, re_compute) {
    (Some(bbox), false) => bbox
    _ => {
      let positions = self.geometries
        .map(geometry => geometry.to_bbox().to_bbox_2d())
        .map(bbox => [bbox.min, bbox.max])
        .flatten()
      BBox2D::from_positions(positions).to_bbox()
    }
  }
}

///|
pub impl ToGeoJSONObject for GeometryCollection with to_geojson_object(
  self : GeometryCollection,
) -> GeoJSONObject {
  GeoJSONObject::new(
    GeoJSONTypes::geometry(GeoJSONGeometryTypes::geometry_collection()),
    bbox=self.bbox,
  )
}

///|
pub impl ToGeometry for GeometryCollection with to_geometry(self) {
  Geometry::GeometryCollection(self)
}

///|
pub impl ToJson for GeometryCollection with to_json(self) {
  let base = self.to_geojson_object().to_json_map()
  base.set("geometries", self.geometries.to_json())
  base.to_json()
}

///|
pub impl FromJson for GeometryCollection with from_json(
  json : Json,
  path : @json.JsonPath,
) {
  GeometryCollection::new(
    @json.from_json(@helper.get_geometries_field(json, path), path~),
    bbox=GeoJSONObject::from_json(json, path).bbox,
  )
}
