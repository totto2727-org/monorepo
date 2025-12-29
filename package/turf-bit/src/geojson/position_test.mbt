///|
test "Position2D to JSON" {
  let position2d = Position::new2D(0, 0)
  @json.inspect(position2d, content=[0, 0])
}

///|
test "Position3D to JSON" {
  let position3d = Position::new3D(0, 0, 1)
  @json.inspect(position3d, content=[0, 0, 1])
}

///|
test "Position2D from JSON" {
  let position2d : Position = @json.from_json([0, 0])
  inspect(position2d, content="Position2D(0, 0)")
}

///|
test "Position3D from JSON" {
  let position3d : Position = @json.from_json([0, 0, 1])
  inspect(position3d, content="Position3D(0, 0, 1)")
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
