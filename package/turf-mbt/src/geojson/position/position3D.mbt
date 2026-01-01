///|
pub struct Position3D {
  x : Double
  y : Double
  z : Double
} derive(Show, Eq, Compare, Hash)

///|
pub fn Position3D::new(point_3d : (Double, Double, Double)) -> Position3D {
  Position3D::{ x: point_3d.0, y: point_3d.1, z: point_3d.2 }
}

///|
pub impl ToPosition2D for Position3D with to_2d(self : Position3D) -> Position2D {
  Position2D::new((self.x, self.y))
}

///|
pub impl ToPosition for Position3D with to_position(self : Position3D) -> Position {
  Position::Position3D(self)
}

///|
pub impl ToJson for Position3D with to_json(self : Position3D) -> Json {
  [self.x, self.y, self.z]
}

///|
pub impl FromJson for Position3D with from_json(
  json : Json,
  path : @json.JsonPath,
) -> Position3D {
  match json {
    Array([Number(x1, ..), Number(x2, ..), Number(x3, ..)]) =>
      Position3D::new((x1, x2, x3))
    _ => raise @json.JsonDecodeError((path, "Invalid Position3D"))
  }
}
