///|
pub struct MultiPolygon[Coord](Array[Polygon[Coord]]) derive(Show, Eq)

///|
#warnings("-unused_trait_bound")
pub fn[Coord : Coord2DTrait] MultiPolygon::new(
  polygon_array : Array[Polygon[Coord]],
) -> MultiPolygon[Coord] {
  MultiPolygon(polygon_array)
}

// MARK: MultiGeometryTrait

///|
pub impl[Coord : Coord2DTrait] MultiGeometryTrait for MultiPolygon[Coord] with geometry_array(
  self,
) {
  self.0.map(x => x)
}

///|
pub impl[Coord : Coord2DTrait] GeometryTrait for MultiPolygon[Coord] with coord_array(
  self,
) {
  &MultiGeometryTrait::coord_array(self)
}
