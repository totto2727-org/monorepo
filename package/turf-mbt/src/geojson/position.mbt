///|
/// A Position is an tuple of coordinates.
/// https://tools.ietf.org/html/rfc7946#section-3.1.1
pub enum Position {
  Position2D(Position2D)
  Position3D(Position3D)
} derive(Show, Eq, Compare, Hash)

///|
pub(open) trait ToPosition {
  to_position(self : Self) -> Position
  to_position_2d(self : Self) -> Position2D = _
}

///|
impl ToPosition with to_position_2d(self) {
  self.to_position().to_position_2d()
}

///|
/// Identity Implementation
pub impl ToPosition for Position with to_position(self) {
  self
}

///|
pub impl ToPosition for Position with to_position_2d(self) {
  match self {
    Position::Position2D(position2D) => position2D
    Position::Position3D(position3D) => position3D.to_position_2d()
  }
}

///|
pub impl ToJson for Position with to_json(self : Position) -> Json {
  match self {
    Position::Position2D(position2D) => position2D.to_json()
    Position::Position3D(position3D) => position3D.to_json()
  }
}

///|
pub impl FromJson for Position with from_json(
  json : Json,
  path : @json.JsonPath,
) -> Position {
  match json {
    Array([Number(x1, ..), Number(x2, ..), Number(x3, ..)]) =>
      Position3D::new((x1, x2, x3)).to_position()
    Array([Number(x1, ..), Number(x2, ..)]) =>
      Position2D::new((x1, x2)).to_position()
    _ => raise @json.JsonDecodeError((path, "Invalid Position"))
  }
}
