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
  bbox : @primary.BBox?
} derive(Show, Eq, Compare, Hash)

///|
pub fn GeometryCollection::new(
  geometries : Array[Geometry],
  bbox? : @primary.BBox? = None,
) -> GeometryCollection {
  GeometryCollection::{ geometries, bbox }
}

///|
pub impl @primary.ToGeoJSONObject for GeometryCollection with to_geojson_object(
  self : GeometryCollection,
) -> @primary.GeoJSONObject {
  @primary.GeoJSONObject::new(
    @primary.GeoJSONTypes::geometry(
      @primary.GeoJSONGeometryTypes::geometry_collection(),
    ),
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
    bbox=@primary.GeoJSONObject::from_json(json, path).bbox,
  )
}
