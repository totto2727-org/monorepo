///|
pub(open) trait GeometryToBBox {
  to_bbox(Self, re_compute? : Bool) -> BBox raise EmptyPositionsError
  to_bbox_2d(Self, re_compute? : Bool) -> BBox2D raise EmptyPositionsError = _
}

///|
impl GeometryToBBox with to_bbox_2d(self, re_compute? : Bool = false) {
  self.to_bbox(re_compute~).to_bbox_2d()
}
