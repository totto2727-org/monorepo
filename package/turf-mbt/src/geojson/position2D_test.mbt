///|
test "Position2D to_json - simple" {
  let position2d = Position2D::new((0, 0))
  @json.inspect(position2d, content=[0, 0])
}

///|
test "Position2D from_json - simple" {
  let position2d : Position2D = @json.from_json([0, 0])
  inspect(position2d, content="{x: 0, y: 0}")
}

///|
test "Position2D add - simple" {
  let position2d = Position2D::new((2, 1))
  let position2d2 = Position2D::new((1, 2))
  let result = position2d + position2d2
  inspect(result, content="{x: 3, y: 3}")
}

///|
test "Position2D sub - simple" {
  let position2d = Position2D::new((3, 3))
  let position2d2 = Position2D::new((1, 1))
  let result = position2d - position2d2
  inspect(result, content="{x: 2, y: 2}")
}
