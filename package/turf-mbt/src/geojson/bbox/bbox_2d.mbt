///|
pub struct BBox2D {
  min : @position.Position2D
  max : @position.Position2D
} derive(Show, Eq, Compare, Hash)

///|
pub trait ToBBox2D {
  to_2d(Self) -> BBox2D
}

///|
pub fn BBox2D::new(
  min : @position.Position2D,
  max : @position.Position2D,
) -> BBox2D {
  BBox2D::{ min, max }
}

///|
/// インターフェイスを揃えるため
/// BBox2D 自身を返す
pub impl ToBBox2D for BBox2D with to_2d(self) {
  self
}

///|
pub impl ToBBox for BBox2D with to_bbox(self) {
  BBox::BBox2D(self)
}

///|
pub impl ToJson for BBox2D with to_json(self) {
  [self.min.x, self.min.y, self.max.x, self.max.y]
}

///|
pub impl FromJson for BBox2D with from_json(json, path) {
  match json {
    Array(
      [
        Number(min_x, ..),
        Number(min_y, ..),
        Number(max_x, ..),
        Number(max_y, ..),
      ]
    ) =>
      BBox2D::new(
        @position.Position2D::new((min_x, min_y)),
        @position.Position2D::new((max_x, max_y)),
      )
    _ => raise @json.JsonDecodeError((path, "Invalid BBox"))
  }
}
