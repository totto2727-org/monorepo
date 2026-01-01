///|
test "Position2D to JSON" {
  let position2d = Position2D::new((0, 0))
  @json.inspect(position2d, content=[0, 0])
}

///|
test "Position2D from JSON" {
  let position2d : Position2D = @json.from_json([0, 0])
  inspect(position2d, content="{x: 0, y: 0}")
}
