///|
test "Position(Position2D) from JSON" {
  let position2d : Position = @json.from_json([0, 0])
  inspect(position2d, content="Position2D({x: 0, y: 0})")
}

///|
test "Position(Position3D) from JSON" {
  let position3d : Position = @json.from_json([0, 0, 1])
  inspect(position3d, content="Position3D({x: 0, y: 0, z: 1})")
}

///|
test "Position from JSON with invalid data" {
  // length: 0
  inspect(
    try? (@json.from_json([]) : Position),
    content=(
      #|Err(JsonDecodeError((, "Invalid Position")))
    ),
  )
  // length: 1
  inspect(
    try? (@json.from_json([0]) : Position),
    content=(
      #|Err(JsonDecodeError((, "Invalid Position")))
    ),
  )
  // length: 4
  inspect(
    try? (@json.from_json([0, 1, 2, 3]) : Position),
    content=(
      #|Err(JsonDecodeError((, "Invalid Position")))
    ),
  )
}
