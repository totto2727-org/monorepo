///|
pub trait PolygonTrait: GeometryTrait {
  exterior(Self) -> LineString[XY]
  interior_array(Self) -> Array[LineString[XY]]
}

///|
pub fn &PolygonTrait::coordArray(self : &PolygonTrait) -> Array[XY] {
  self.exterior().coord_array()
}

///|
pub struct Polygon[Coord] {
  exterior : LineString[Coord]
  interior_array : Array[LineString[Coord]]
} derive(Show, Eq)

///|
/// TODO: Closeしていることの検証が必要
#warnings("-unused_trait_bound")
pub fn[Coord : CoordTrait] Polygon::new(
  exterior : LineString[Coord],
  interior_array? : Array[LineString[Coord]] = [],
) -> Polygon[Coord] {
  Polygon::{ exterior, interior_array }
}

// MARK: PolygonTrait

///|
pub impl[Coord : CoordTrait] PolygonTrait for Polygon[Coord] with exterior(self) {
  self.exterior.line_string()
}

///|
pub impl[Coord : CoordTrait] PolygonTrait for Polygon[Coord] with interior_array(
  self,
) {
  self.interior_array.map(LineString::line_string)
}

///|
pub impl[Coord : CoordTrait] GeometryTrait for Polygon[Coord] with coord_array(
  self,
) {
  &PolygonTrait::coordArray(self)
}
