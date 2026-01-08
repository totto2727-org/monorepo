///|
test "Position3D to_json - simple" {
  let position3d = Position3D::new((0, 0, 1))
  @json.inspect(position3d, content=[0, 0, 1])
}

///|
test "Position3D from_json - simple" {
  let position3d : Position3D = @json.from_json([0, 0, 1])
  inspect(position3d, content="{x: 0, y: 0, z: 1}")
}

///|
test "Position3D add - simple" {
  let position3d = Position3D::new((0, 0, 1))
  let position3d2 = Position3D::new((1, 1, 1))
  let result = position3d + position3d2
  inspect(result, content="{x: 1, y: 1, z: 2}")
}

///|
test "Position3D sub - simple" {
  let position3d = Position3D::new((0, 0, 1))
  let position3d2 = Position3D::new((1, 1, 1))
  let result = position3d - position3d2
  inspect(result, content="{x: -1, y: -1, z: 0}")
}
