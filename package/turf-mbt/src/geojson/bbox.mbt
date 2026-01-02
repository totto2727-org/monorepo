///|
/// Bounding box
/// https://tools.ietf.org/html/rfc7946#section-5
pub enum BBox {
  BBox2D(BBox2D)
  BBox3D(BBox3D)
} derive(Show, Eq, Compare, Hash)

///|
pub(open) trait ToBBox {
  to_bbox(Self) -> BBox
  to_bbox_2d(Self) -> BBox2D = _
}

///|
impl ToBBox with to_bbox_2d(self) {
  self.to_bbox().to_bbox_2d()
}

///|
/// Identity Implementation
pub impl ToBBox for BBox with to_bbox(self) {
  self
}

///|
pub impl ToBBox for BBox with to_bbox_2d(self) {
  match self {
    BBox::BBox2D(bbox2D) => bbox2D
    BBox::BBox3D(bbox3D) => bbox3D.to_bbox_2d()
  }
}

///|
pub impl ToJson for BBox with to_json(self) {
  match self {
    BBox::BBox2D(bbox2D) => bbox2D.to_json()
    BBox::BBox3D(bbox3D) => bbox3D.to_json()
  }
}

///|
pub impl FromJson for BBox with from_json(json, path) {
  match json {
    Array(
      [
        Number(x1, ..),
        Number(x2, ..),
        Number(x3, ..),
        Number(x4, ..),
        Number(x5, ..),
        Number(x6, ..),
      ]
    ) =>
      BBox3D::new(Position3D::new((x1, x2, x3)), Position3D::new((x4, x5, x6))).to_bbox()
    Array([Number(x1, ..), Number(x2, ..), Number(x3, ..), Number(x4, ..)]) =>
      BBox2D::new(Position2D::new((x1, x2)), Position2D::new((x3, x4))).to_bbox()
    _ => raise @json.JsonDecodeError((path, "Invalid BBox"))
  }
}
