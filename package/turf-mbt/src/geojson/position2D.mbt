///|
pub struct Position2D {
  x : Double
  y : Double
} derive(Show, Eq)

///|
pub fn Position2D::new(point_2d : (Double, Double)) -> Position2D {
  Position2D::{ x: point_2d.0, y: point_2d.1 }
}

///|
pub impl ToPosition for Position2D with to_position(self) -> Position {
  Position::Position2D(self)
}

///|
/// Identity Implementation
pub impl ToPosition for Position2D with to_position_2d(self) -> Position2D {
  self
}

///|
pub impl ToJson for Position2D with to_json(self) -> Json {
  [self.x, self.y]
}

///|
pub impl FromJson for Position2D with from_json(json, path) {
  match json {
    Array([Number(x1, ..), Number(x2, ..)]) => Position2D::new((x1, x2))
    _ => raise @json.JsonDecodeError((path, "Invalid Position2D"))
  }
}

///|
pub impl Add for Position2D with add(self, other) {
  Position2D::new((self.x + other.x, self.y + other.y))
}

///|
pub impl Sub for Position2D with sub(self, other) {
  Position2D::new((self.x - other.x, self.y - other.y))
}
