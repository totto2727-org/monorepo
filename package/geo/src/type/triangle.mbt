///|
pub struct Triangle[Coord] {
  a : Coord
  b : Coord
  c : Coord
} derive(Show, Eq)

///|
#warnings("-unused_trait_bound")
pub fn[Coord : CoordTrait] Triangle::new(
  a : Coord,
  b : Coord,
  c : Coord,
) -> Triangle[Coord] {
  Triangle::{ a, b, c }
}

// MARK: PolygonTrait

///|
/// TODO: Closeしていることの検証が必要
pub impl[Coord : CoordTrait] PolygonTrait for Triangle[Coord] with exterior(
  self,
) {
  LineString::new([self.a.xy(), self.b.xy(), self.c.xy(), self.a.xy()])
}

///|
pub impl[Coord : CoordTrait] PolygonTrait for Triangle[Coord] with interior_array(
  _,
) {
  []
}

///|
pub impl[Coord : CoordTrait] GeometryTrait for Triangle[Coord] with coord_array(
  self,
) {
  &PolygonTrait::coordArray(self)
}

///|
pub impl[Coord : CoordTrait] GeometryTrait for Triangle[Coord] with bbox(self) {
  let a = self.a.xy()
  let b = self.b.xy()
  let c = self.c.xy()
  let min_x = @cmp.minimum(a.x, @cmp.minimum(b.x, c.x))
  let min_y = @cmp.minimum(a.y, @cmp.minimum(b.y, c.y))
  let max_x = @cmp.maximum(a.x, @cmp.maximum(b.x, c.x))
  let max_y = @cmp.maximum(a.y, @cmp.maximum(b.y, c.y))
  BBox::new(XY::new(min_x, min_y), XY::new(max_x, max_y))
}
