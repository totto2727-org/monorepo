///|
pub trait PolygonTrait: GeometryTrait {
  exterior(Self) -> Ring[XY]
  interior_array(Self) -> Array[Ring[XY]]
}

///|
pub fn &PolygonTrait::coordArray(self : &PolygonTrait) -> Array[XY] {
  self.exterior().coord_array()
}

///|
pub struct Polygon[Coord] {
  exterior : Ring[Coord]
  interior_array : Array[Ring[Coord]]
} derive(Show, Eq)

///|
/// TODO: Closeしていることの検証が必要
#warnings("-unused_trait_bound")
pub fn[Coord : Coord2DTrait] Polygon::new(
  exterior : Ring[Coord],
  interior_array? : Array[Ring[Coord]] = [],
) -> Polygon[Coord] {
  Polygon::{ exterior, interior_array }
}

// MARK: PolygonTrait

///|
pub impl[Coord : Coord2DTrait] PolygonTrait for Polygon[Coord] with exterior(
  self,
) {
  self.exterior.ring()
}

///|
pub impl[Coord : Coord2DTrait] PolygonTrait for Polygon[Coord] with interior_array(
  self,
) {
  self.interior_array.map(Ring::ring)
}

///|
pub impl[Coord : Coord2DTrait] GeometryTrait for Polygon[Coord] with coord_array(
  self,
) {
  &PolygonTrait::coordArray(self)
}
