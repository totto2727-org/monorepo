///|
pub trait MultiGeometryTrait: GeometryTrait {
  geometry_array(Self) -> Array[&GeometryTrait]
}

///|
pub fn &MultiGeometryTrait::coord_array(
  self : &MultiGeometryTrait,
) -> Array[XY] {
  self.geometry_array()
  |> Array::map(GeometryTrait::coord_array)
  |> Array::flatten
}
