///|
test "Position3D to JSON" {
  let position3d = Position3D::new((0, 0, 1))
  @json.inspect(position3d, content=[0, 0, 1])
}

///|
test "Position3D from JSON" {
  let position3d : Position3D = @json.from_json([0, 0, 1])
  inspect(position3d, content="{x: 0, y: 0, z: 1}")
}
