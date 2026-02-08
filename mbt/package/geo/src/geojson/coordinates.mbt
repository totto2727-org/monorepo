///|
pub(all) enum Coordinates {
  XY(Double, Double)
  XYZ_OR_XYM(Double, Double, Double)
  XYZM(Double, Double, Double, Double)
} derive(Eq, Show)

///|
pub impl ToJson for Coordinates with to_json(self) {
  match self {
    XY(x, y) => [x, y]
    XYZ_OR_XYM(x, y, z) => [x, y, z]
    XYZM(x, y, z, m) => [x, y, z, m]
  }
}

///|
pub impl FromJson for Coordinates with from_json(json, path) {
  match json {
    Json::Array([Json::Number(x, ..), Json::Number(y, ..)]) =>
      Coordinates::XY(x, y)
    Json::Array([Json::Number(x, ..), Json::Number(y, ..), Json::Number(z, ..)]) =>
      Coordinates::XYZ_OR_XYM(x, y, z)
    Json::Array(
      [
        Json::Number(x, ..),
        Json::Number(y, ..),
        Json::Number(z, ..),
        Json::Number(m, ..),
      ]
    ) => Coordinates::XYZM(x, y, z, m)
    _ => raise geojson_decode_error(path, "Invalid Coordinates", json)
  }
}

///|
pub fn Coordinates::dimension(self : Coordinates) -> Int {
  match self {
    XY(_, _) => 2
    XYZ_OR_XYM(_, _, _) => 3
    XYZM(_, _, _, _) => 4
  }
}

///|
pub fn Coordinates::x(self : Coordinates) -> Double {
  match self {
    XY(x, _) => x
    XYZ_OR_XYM(x, _, _) => x
    XYZM(x, _, _, _) => x
  }
}

///|
pub fn Coordinates::y(self : Coordinates) -> Double {
  match self {
    XY(_, y) => y
    XYZ_OR_XYM(_, y, _) => y
    XYZM(_, y, _, _) => y
  }
}

///|
pub fn Coordinates::z(self : Coordinates) -> Double raise InvalidGeoJSONError {
  match self {
    XY(_, _) =>
      raise InvalidGeoJSONError("Coordinates::z called on 2D coordinates")
    XYZ_OR_XYM(_, _, z) => z
    XYZM(_, _, z, _) => z
  }
}
