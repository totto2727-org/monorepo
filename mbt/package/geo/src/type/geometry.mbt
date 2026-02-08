///|
pub suberror NonExistCoordError

///|
pub trait GeometryTrait: Show {
  coord_array(Self) -> Array[XY]
  point_array(Self) -> Array[Point[XY]] = _
  bbox(Self) -> BBox[XY] raise NonExistCoordError = _
}

///|
impl GeometryTrait with point_array(self) {
  self.coord_array().map(Point::new)
}

///|
impl GeometryTrait with bbox(self) {
  coord_array_to_bbox(self.coord_array())
}

///|
fn coord_array_to_bbox(
  coord_array : Array[XY],
) -> BBox[XY] raise NonExistCoordError {
  guard coord_array.length() is (1..<_) else { raise NonExistCoordError }
  let xs = coord_array.map(XY::x)
  let ys = coord_array.map(XY::y)
  let min_x = xs.iter().minimum().unwrap_or_error(NonExistCoordError)
  let min_y = ys.iter().minimum().unwrap_or_error(NonExistCoordError)
  let max_x = xs.iter().maximum().unwrap_or_error(NonExistCoordError)
  let max_y = ys.iter().maximum().unwrap_or_error(NonExistCoordError)
  BBox::new(XY::new(min_x, min_y), XY::new(max_x, max_y))
}
