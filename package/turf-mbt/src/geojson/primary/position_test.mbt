///|
test "Position2D to JSON" {
  let position2d = Position::new2D((0, 0))
  @json.inspect(position2d, content=[0, 0])
}

///|
test "Position2D from JSON" {
  let position2d : Position = @json.from_json([0, 0])
  inspect(position2d, content="Position2D(0, 0)")
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
  // length: 3
  inspect(
    try? (@json.from_json([0, 1, 2]) : Position),
    content=(
      #|Err(JsonDecodeError((, "Invalid Position")))
    ),
  )
}
