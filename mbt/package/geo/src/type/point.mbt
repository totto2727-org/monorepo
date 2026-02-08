///|
pub trait PointTrait: GeometryTrait {
  coord(Self) -> XY
}

///|
pub fn &PointTrait::coordArray(self : &PointTrait) -> Array[XY] {
  [self.coord()]
}

///|
pub fn &PointTrait::bbox(self : &PointTrait) -> BBox[XY] {
  let coord = self.coord()
  BBox::new(coord, coord)
}

///|
pub struct Point[Coord](Coord) derive(Show, Eq)

///|
#warnings("-unused_trait_bound")
pub fn[Coord : Coord2DTrait] Point::new(coord : Coord) -> Point[Coord] {
  Point(coord)
}

// MARK: PointTrait

///|
pub impl[Coord : Coord2DTrait] PointTrait for Point[Coord] with coord(self) {
  self.0.xy()
}

///|
pub impl[Coord : Coord2DTrait] GeometryTrait for Point[Coord] with coord_array(
  self,
) {
  &PointTrait::coordArray(self)
}

///|
pub impl[Coord : Coord2DTrait] GeometryTrait for Point[Coord] with bbox(self) {
  &PointTrait::bbox(self)
}
