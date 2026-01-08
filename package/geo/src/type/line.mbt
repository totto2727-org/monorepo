///|
pub trait LineTrait: GeometryTrait {
  line(Self) -> Line[XY] = _
  start(Self) -> XY
  end(Self) -> XY
}

///|
impl LineTrait with line(self) {
  Line::new(self.start(), self.end())
}

///|
pub struct Line[Coord] {
  start : Coord
  end : Coord
} derive(Show, Eq)

///|
#warnings("-unused_trait_bound")
pub fn[Coord : CoordTrait] Line::new(start : Coord, end : Coord) -> Line[Coord] {
  Line::{ start, end }
}

// MARK: LineTrait

///|
pub impl[Coord : CoordTrait] LineTrait for Line[Coord] with start(self) {
  self.start.xy()
}

///|
pub impl[Coord : CoordTrait] LineTrait for Line[Coord] with end(self) {
  self.end.xy()
}

///|
pub impl[Coord : CoordTrait] GeometryTrait for Line[Coord] with coord_array(
  self,
) {
  [self.start(), self.end()]
}

///|
pub impl[Coord : CoordTrait] GeometryTrait for Line[Coord] with bbox(self) {
  let start = self.start.xy()
  let end = self.end.xy()
  let min_x = @cmp.minimum(start.x, end.x)
  let min_y = @cmp.minimum(start.y, end.y)
  let max_x = @cmp.maximum(start.x, end.x)
  let max_y = @cmp.maximum(start.y, end.y)
  Rect::new(XY::new(min_x, min_y), XY::new(max_x, max_y))
}
