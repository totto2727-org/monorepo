///|
pub struct BBox3D {
  min : Position3D
  max : Position3D
} derive(Show, Eq, Compare, Hash)

///|
pub fn BBox3D::new(min : Position3D, max : Position3D) -> BBox3D {
  BBox3D::{ min, max }
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
        Position3D::new((min_x, min_y, min_z)),
        Position3D::new((max_x, max_y, max_z)),
      )
    _ => raise @json.JsonDecodeError((path, "Invalid BBox"))
  }
}
