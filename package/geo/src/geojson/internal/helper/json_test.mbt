///|
test "json get_field - normal exists" {
  let json : Json = { "key": "value" }
  let result = get_field(json, "key")
  inspect(result, content="Some(String(\"value\"))")
}

///|
test "json get_field - error not exists" {
  let json : Json = { "other_key": "value" }
  let result = get_field(json, "key")
  inspect(result, content="None")
}

///|
struct TestCoordinates {
  coords : Json
} derive(Show)

///|
pub impl FromJson for TestCoordinates with from_json(json, path) {
  TestCoordinates::{ coords: get_coordinates_field(json, path) }
}

///|
test "json get_coordinates_field - normal" {
  let json : Json = { "coordinates": [0, 0] }
  let res : TestCoordinates = @json.from_json(json)
  inspect(res.coords, content="Array([Number(0), Number(0)])")
}

///|
test "json get_coordinates_field - error missing" {
  let json : Json = { "other": "value" }
  try {
    let _ : TestCoordinates = @json.from_json(json)
    fail("Should raise JsonDecodeError")
  } catch {
    @json.JsonDecodeError((path, msg)) =>
      inspect(
        (path.to_string(), msg),
        content=(
          #|("", "Invalid coordinates in json: Object({\"other\": String(\"value\")})")
        ),
      )
    _ => fail("Should raise JsonDecodeError")
  }
}

///|
struct TestGeometries {
  geoms : Json
} derive(Show)

///|
pub impl FromJson for TestGeometries with from_json(json, path) {
  TestGeometries::{ geoms: get_geometries_field(json, path) }
}

///|
test "json get_geometries_field - normal" {
  let json : Json = { "geometries": [{ "type": "Point" }] }
  let res : TestGeometries = @json.from_json(json)
  inspect(res.geoms, content="Array([Object({\"type\": String(\"Point\")})])")
}

///|
test "json get_geometries_field - error missing" {
  let json : Json = { "other": "value" }
  try {
    let _ : TestGeometries = @json.from_json(json)
    fail("Should raise JsonDecodeError")
  } catch {
    @json.JsonDecodeError((path, msg)) =>
      inspect(
        (path.to_string(), msg),
        content=(
          #|("", "Invalid geometries")
        ),
      )
    _ => fail("Should raise JsonDecodeError")
  }
}
