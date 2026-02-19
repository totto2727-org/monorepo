///|
pub struct GeometryCollection {
  geometries : Array[Geometry]
} derive(Eq, Show)

///|
pub fn GeometryCollection::new(
  geometries : Array[Geometry],
) -> GeometryCollection {
  { geometries, }
}

///|
pub impl GeoJSONTrait for GeometryCollection with to_json(
  self,
  with_bbox? = false,
) {
  let map = {}
  set_geometry_type(map, GeometryType::GeometryCollection)
  map.set(
    "geometries",
    self.geometries.map(x => GeoJSONTrait::to_json(x, with_bbox~)).to_json(),
  )
  if with_bbox {
    set_bbox(map, self)
  }
  map.to_json()
}

///|
pub impl ToJson for GeometryCollection with to_json(self) {
  GeoJSONTrait::to_json(self)
}

///|
pub impl FromJson for GeometryCollection with from_json(json, path) {
  let geometries : Array[Geometry] = @json_helper.from_json_property_or_array_or_empty(
    "geometries", json, path,
  )
  GeometryCollection::{ geometries, }
}

///|
pub impl BBoxTrait for GeometryCollection with bbox(self) {
  let coords = self.geometries
    .map(geom => {
      match geom.bbox() {
        BBox2D(x1, y1, x2, y2) => [Coordinates::XY(x1, y1), XY(x2, y2)]
        BBox3D(x1, y1, z1, x2, y2, z2) =>
          [Coordinates::XYZ_OR_XYM(x1, y1, z1), XYZ_OR_XYM(x2, y2, z2)]
      }
    })
    .flatten()
  BBox::from_coordinate_array(coords)
}
