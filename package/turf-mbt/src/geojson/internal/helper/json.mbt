///|
pub fn get_field(json : Json, name : String) -> Json? {
  match json {
    Object(map) => map.get(name)
    _ => None
  }
}

///|
pub fn get_coordinates_field(
  json : Json,
  path : @json.JsonPath,
) -> Json raise @json.JsonDecodeError {
  match get_field(json, "coordinates") {
    Some(coordinates) => coordinates
    _ =>
      raise @json.JsonDecodeError(
        (path, "Invalid coordinates in json: \{json}"),
      )
  }
}

///|
pub fn get_geometries_field(
  json : Json,
  path : @json.JsonPath,
) -> Json raise @json.JsonDecodeError {
  match get_field(json, "geometries") {
    Some(geometries) => geometries
    _ => raise @json.JsonDecodeError((path, "Invalid geometries"))
  }
}
