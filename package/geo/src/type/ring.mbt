///|
pub trait RingTrait: LineStringTrait {
  ring(Self) -> Ring[XY]
}

///|
pub struct Ring[Coord](Array[Coord]) derive(Show, Eq)

///|
#warnings("-unused_trait_bound")
pub fn[Coord : Coord2DTrait] Ring::new(coords : Array[Coord]) -> Ring[Coord] {
  // TODO: check closed
  Ring(coords)
}

// MARK: RingTrait

///|
pub impl[Coord : Coord2DTrait] RingTrait for Ring[Coord] with ring(self) {
  Ring::new(self.coord_array())
}

///|
pub impl[Coord : Coord2DTrait] LineStringTrait for Ring[Coord] with line_string(
  self,
) {
  LineString::new(self.coord_array())
}

///|
pub impl[Coord : Coord2DTrait] GeometryTrait for Ring[Coord] with coord_array(
  self,
) {
  self.0.map(Coord2DTrait::xy)
}
