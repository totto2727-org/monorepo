///|
pub trait LineStringTrait: GeometryTrait {
  line_string(Self) -> LineString[XY]
  line_array(Self) -> Array[Line[XY]] = _
}

///|
impl LineStringTrait with line_array(self) {
  let coord_array = self.coord_array()
  let zipped_coord_array = Array::zip(coord_array, coord_array[1:].to_array())
  zipped_coord_array.map(coord_tuple => Line::new(coord_tuple.0, coord_tuple.1))
}

///|
pub struct LineString[Coord](Array[Coord]) derive(Show, Eq)

///|
#warnings("-unused_trait_bound")
pub fn[Coord : CoordTrait] LineString::new(
  coord_array : Array[Coord],
) -> LineString[Coord] {
  LineString(coord_array)
}

// MARK: LineStringTrait

///|
pub impl[Coord : CoordTrait] LineStringTrait for LineString[Coord] with line_string(
  self,
) {
  LineString(self.coord_array())
}

///|
pub impl[Coord : CoordTrait] GeometryTrait for LineString[Coord] with coord_array(
  self,
) {
  self.0.map(CoordTrait::xy)
}
