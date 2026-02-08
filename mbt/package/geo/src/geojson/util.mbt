///|
fn geojson_decode_error(
  path : @json.JsonPath,
  msg : String,
  geojson : Json,
) -> @json.JsonDecodeError {
  @json.JsonDecodeError((path, "GeoJSON error: \{msg}\n\{geojson}"))
}

///|
pub suberror InvalidGeoJSONError {
  InvalidGeoJSONError(String)
}

///|
pub fn InvalidGeoJSONError::new(msg : String) -> InvalidGeoJSONError {
  InvalidGeoJSONError(msg)
}

///|
fn set_geojson_type(
  map : Map[String, Json],
  geojson_type : GeoJSONType,
) -> Unit {
  map.set("type", geojson_type.to_json())
}

///|
fn[T : BBoxTrait] set_bbox(map : Map[String, Json], bbox : T) -> Unit {
  try bbox.bbox() catch {
    _ => ()
  } noraise {
    bbox => map.set("bbox", bbox.to_json())
  }
}

///|
fn set_geometry_type(
  map : Map[String, Json],
  geometry_type : GeometryType,
) -> Unit {
  map.set("type", geometry_type.to_json())
}

///|
fn set_coordinates(map : Map[String, Json], coordinates : Json) -> Unit {
  map.set("coordinates", coordinates)
}

///|
fn[T : FromJson] get_coordinates(
  json : Json,
  path : @json.JsonPath,
) -> T raise @json.JsonDecodeError {
  @json_helper.from_json_property_or_throw("coordinates", json, path)
}
