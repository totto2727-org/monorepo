///|
pub struct MultiLineString[Coord](Array[LineString[Coord]]) derive(Show, Eq)

///|
#warnings("-unused_trait_bound")
pub fn[Coord : Coord2DTrait] MultiLineString::new(
  line_string_array : Array[LineString[Coord]],
) -> MultiLineString[Coord] {
  MultiLineString(line_string_array)
}

// MARK: MultiGeometryTrait

///|
pub impl[Coord : Coord2DTrait] MultiGeometryTrait for MultiLineString[Coord] with geometry_array(
  self,
) {
  self.0.map(x => x)
}

///|
pub impl[Coord : Coord2DTrait] GeometryTrait for MultiLineString[Coord] with coord_array(
  self,
) {
  &MultiGeometryTrait::coord_array(self)
}
