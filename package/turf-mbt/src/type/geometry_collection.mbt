///|
pub struct GeometryCollection(Array[&GeometryTrait]) derive(Show)

///|
#warnings("-unused_trait_bound")
pub fn GeometryCollection::new(
  geometry_array : Array[&GeometryTrait],
) -> GeometryCollection {
  GeometryCollection(geometry_array)
}

// MARK: MultiGeometryTrait

///|
pub impl MultiGeometryTrait for GeometryCollection with geometry_array(self) {
  self.0
}

///|
pub impl GeometryTrait for GeometryCollection with coord_array(self) {
  &MultiGeometryTrait::coord_array(self)
}
