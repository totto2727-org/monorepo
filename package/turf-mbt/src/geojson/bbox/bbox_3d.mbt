///|
pub struct BBox3D {
  min : @position.Position3D
  max : @position.Position3D
} derive(Show, Eq, Compare, Hash)

///|
pub fn BBox3D::new(
  min : @position.Position3D,
  max : @position.Position3D,
) -> BBox3D {
  BBox3D::{ min, max }
}

///|
pub impl ToBBox2D for BBox3D with to_2d(self) {
  BBox2D::new(self.min.to_2d(), self.max.to_2d())
}

///|
pub impl ToBBox for BBox3D with to_bbox(self) {
  BBox::BBox3D(self)
}

///|
pub impl ToJson for BBox3D with to_json(self) {
  [self.min.x, self.min.y, self.min.z, self.max.x, self.max.y, self.max.z]
}

///|
pub impl FromJson for BBox3D with from_json(json, path) {
  match json {
    Array(
      [
        Number(min_x, ..),
        Number(min_y, ..),
        Number(min_z, ..),
        Number(max_x, ..),
        Number(max_y, ..),
        Number(max_z, ..),
      ]
    ) =>
      BBox3D::new(
        @position.Position3D::new((min_x, min_y, min_z)),
        @position.Position3D::new((max_x, max_y, max_z)),
      )
    _ => raise @json.JsonDecodeError((path, "Invalid BBox"))
  }
}
