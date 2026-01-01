///|
test "BBox(BBox2D) from JSON" {
  let bbox : BBox = @json.from_json([0, 0, 1, 1])
  inspect(bbox, content="BBox2D({min: {x: 0, y: 0}, max: {x: 1, y: 1}})")
}

///|
test "BBox(BBox3D) from JSON" {
  let bbox : BBox = @json.from_json([0, 0, 1, 1, 2, 2])
  inspect(
    bbox,
    content="BBox3D({min: {x: 0, y: 0, z: 1}, max: {x: 1, y: 2, z: 2}})",
  )
}

///|
test "BBox from JSON with invalid data" {
  // length: 0
  inspect(
    try? (@json.from_json([]) : BBox),
    content=(
      #|Err(JsonDecodeError((, "Invalid BBox")))
    ),
  )
  // length: 1
  inspect(
    try? (@json.from_json([0]) : BBox),
    content=(
      #|Err(JsonDecodeError((, "Invalid BBox")))
    ),
  )
  // length: 2
  inspect(
    try? (@json.from_json([0, 1]) : BBox),
    content=(
      #|Err(JsonDecodeError((, "Invalid BBox")))
    ),
  )
  // length: 3
  inspect(
    try? (@json.from_json([0, 1, 2]) : BBox),
    content=(
      #|Err(JsonDecodeError((, "Invalid BBox")))
    ),
  )
  // length: 5
  inspect(
    try? (@json.from_json([0, 1, 2, 3, 4]) : BBox),
    content=(
      #|Err(JsonDecodeError((, "Invalid BBox")))
    ),
  )
  // length: 7
  inspect(
    try? (@json.from_json([0, 1, 2, 3, 4, 5, 6]) : BBox),
    content=(
      #|Err(JsonDecodeError((, "Invalid BBox")))
    ),
  )
}
