///|
pub(all) enum ID {
  String(String)
  Number(Double)
} derive(Eq, Show)

///|
pub impl ToJson for ID with to_json(self) {
  match self {
    String(string) => string.to_json()
    Number(number) => number.to_json()
  }
}

///|
pub impl FromJson for ID with from_json(json, path) {
  match json {
    Json::String(string) => ID::String(string)
    Json::Number(number, ..) => ID::Number(number)
    _ => raise geojson_decode_error(path, "Invalid ID", json)
  }
}
