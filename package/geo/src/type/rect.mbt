///|
#alias(BBox)
pub struct Rect[Coord] {
  min : Coord
  max : Coord
} derive(Show, Eq)

///|
#warnings("-unused_trait_bound")
pub fn[Coord : CoordTrait] Rect::new(min : Coord, max : Coord) -> Rect[Coord] {
  Rect::{ min, max }
}

// MARK: PolygonTrait

///|
/// TODO: Closeしていることの検証が必要
pub impl[Coord : CoordTrait] PolygonTrait for Rect[Coord] with exterior(self) {
  let min = self.min.xy()
  let max = self.max.xy()
  LineString::new([min, XY::new(min.x, max.y), max, XY::new(max.x, min.y), min])
}

///|
pub impl[Coord : CoordTrait] PolygonTrait for Rect[Coord] with interior_array(_) {
  []
}

///|
pub impl[Coord : CoordTrait] GeometryTrait for Rect[Coord] with coord_array(
  self,
) {
  &PolygonTrait::coordArray(self)
}

///|
pub impl[Coord : CoordTrait] GeometryTrait for Rect[Coord] with bbox(self) {
  Rect::new(self.min.xy(), self.max.xy())
}
