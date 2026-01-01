///|
pub struct Position2D {
  x : Double
  y : Double
} derive(Show, Eq, Compare, Hash)

///|
pub trait ToPosition2D {
  to_2d(self : Self) -> Position2D
}

///|
pub fn Position2D::new(point_2d : (Double, Double)) -> Position2D {
  Position2D::{ x: point_2d.0, y: point_2d.1 }
}

///|
/// インターフェイスを揃えるため
/// 自身をそのまま返す
pub impl ToPosition2D for Position2D with to_2d(self) -> Position2D {
  self
}

///|
pub impl ToPosition for Position2D with to_position(self) -> Position {
  Position::Position2D(self)
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
