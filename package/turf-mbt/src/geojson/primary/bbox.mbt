///|
pub type BBox2D = (Double, Double, Double, Double)

///|
/// Bounding box
/// https://tools.ietf.org/html/rfc7946#section-5
pub enum BBox {
  BBox2D(BBox2D)
} derive(Show, Eq, Compare, Hash)

///|
pub fn BBox::new2D(bbox2D : BBox2D) -> BBox {
  BBox::BBox2D(bbox2D)
}

///|
pub fn BBox::to_2d(self : BBox) -> BBox2D {
  match self {
    BBox::BBox2D(bbox2D) => bbox2D
  }
}

///|
pub impl ToJson for BBox with to_json(self) {
  match self {
    BBox::BBox2D(bbox2D) => [bbox2D.0, bbox2D.1, bbox2D.2, bbox2D.3]
  }
}

///|
pub impl FromJson for BBox with from_json(json, path) {
  match json {
    Array([Number(x1, ..), Number(x2, ..), Number(x3, ..), Number(x4, ..)]) =>
      BBox::new2D((x1, x2, x3, x4))
    _ => raise @json.JsonDecodeError((path, "Invalid BBox"))
  }
}
