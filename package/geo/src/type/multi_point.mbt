///|
pub struct MultiPoint[Coord](Array[Point[Coord]]) derive(Show, Eq)

///|
#warnings("-unused_trait_bound")
pub fn[Coord : CoordTrait] MultiPoint::new(
  point_array : Array[Point[Coord]],
) -> MultiPoint[Coord] {
  MultiPoint(point_array)
}

// MARK: MultiGeometryTrait

///|
pub impl[Coord : CoordTrait] MultiGeometryTrait for MultiPoint[Coord] with geometry_array(
  self,
) {
  self.0.map(x => x)
}

///|
pub impl[Coord : CoordTrait] GeometryTrait for MultiPoint[Coord] with coord_array(
  self,
) {
  &MultiGeometryTrait::coord_array(self)
}
