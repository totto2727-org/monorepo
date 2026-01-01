///|
pub type Position2D = (Double, Double)

///|
/// A Position is an tuple of coordinates.
/// https://tools.ietf.org/html/rfc7946#section-3.1.1
pub enum Position {
  Position2D(Position2D)
} derive(Show, Eq, Compare, Hash)

///|
pub fn Position::new2D(position2D : Position2D) -> Position {
  Position::Position2D(position2D)
}

///|
pub fn Position::to_2d(self : Position) -> Position2D {
  match self {
    Position::Position2D(position2D) => position2D
  }
}

///|
pub impl ToJson for Position with to_json(self : Position) -> Json {
  match self {
    Position::Position2D(position2D) => [position2D.0, position2D.1]
  }
}

///|
pub impl FromJson for Position with from_json(
  json : Json,
  path : @json.JsonPath,
) -> Position {
  match json {
    Array([Number(x1, ..), Number(x2, ..)]) => Position::Position2D((x1, x2))
    _ => raise @json.JsonDecodeError((path, "Invalid Position"))
  }
}
