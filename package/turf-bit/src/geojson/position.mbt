///|
/// A Position is an tuple of coordinates.
/// https://tools.ietf.org/html/rfc7946#section-3.1.1
pub enum Position {
  Position2D(Double, Double)
  Position3D(Double, Double, Double)
} derive(Show, Eq, Compare, Hash)

///|
pub fn Position::new2D(x1 : Double, x2 : Double) -> Position {
  Position::Position2D(x1, x2)
}

///|
pub fn Position::new3D(x1 : Double, x2 : Double, x3 : Double) -> Position {
  Position::Position3D(x1, x2, x3)
}

///|
pub impl ToJson for Position with to_json(self : Position) -> Json {
  match self {
    Position::Position2D(x1, x2) => [x1, x2]
    Position::Position3D(x1, x2, x3) => [x1, x2, x3]
  }
}

///|
pub impl @json.FromJson for Position with from_json(
  json : Json,
  path : @json.JsonPath,
) -> Position {
  match json {
    Array([Number(x1, ..), Number(x2, ..), Number(x3, ..)]) =>
      Position::Position3D(x1, x2, x3)
    Array([Number(x1, ..), Number(x2, ..)]) => Position::Position2D(x1, x2)
    _ => raise @json.JsonDecodeError((path, "Invalid Position"))
  }
}
