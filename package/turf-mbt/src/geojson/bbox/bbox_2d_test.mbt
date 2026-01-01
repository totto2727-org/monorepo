///|
test "BBox2D to JSON" {
  let min = @position.Position2D::new((0, 0))
  let max = @position.Position2D::new((1, 1))
  let bbox = BBox2D::new(min, max)
  @json.inspect(bbox, content=[0, 0, 1, 1])
}

///|
test "BBox2D from JSON" {
  let bbox : BBox2D = @json.from_json([0, 0, 1, 1])
  inspect(bbox, content="{min: {x: 0, y: 0}, max: {x: 1, y: 1}}")
}
