///|
/// Bounding box
/// https://tools.ietf.org/html/rfc7946#section-5
pub enum BBox {
  BBox2D(Double, Double, Double, Double)
  BBox3D(Double, Double, Double, Double, Double, Double)
} derive(Show, Eq, Compare, Hash)

///|
pub impl ToJson for BBox with to_json(self) {
  match self {
    BBox::BBox2D(x1, x2, x3, x4) => [x1, x2, x3, x4]
    BBox::BBox3D(x1, x2, x3, x4, x5, x6) => [x1, x2, x3, x4, x5, x6]
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
    ) => BBox::new3D((x1, x2, x3, x4, x5, x6))
    Array([Number(x1, ..), Number(x2, ..), Number(x3, ..), Number(x4, ..)]) =>
      BBox::new2D((x1, x2, x3, x4))
    _ => raise @json.JsonDecodeError((path, "Invalid BBox"))
  }
}

///|
pub fn BBox::new2D(bbox2D : (Double, Double, Double, Double)) -> BBox {
  BBox::BBox2D(bbox2D.0, bbox2D.1, bbox2D.2, bbox2D.3)
}

///|
pub fn BBox::new3D(
  bbox3D : (Double, Double, Double, Double, Double, Double),
) -> BBox {
  BBox::BBox3D(bbox3D.0, bbox3D.1, bbox3D.2, bbox3D.3, bbox3D.4, bbox3D.5)
}
