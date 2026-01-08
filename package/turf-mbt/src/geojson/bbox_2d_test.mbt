///|
test "BBox2D from_positions - multiple points" {
  let positions = [
    Position2D::new((0, 0)),
    Position2D::new((10, 10)),
    Position2D::new((-5, -5)),
  ]
  let bbox = BBox2D::from_positions(positions)
  inspect(bbox, content="{min: {x: -5, y: -5}, max: {x: 10, y: 10}}")
}

///|
test "BBox2D from_positions - single point" {
  let positions = [Position2D::new((0, 0))]
  let bbox = BBox2D::from_positions(positions)
  inspect(bbox, content="{min: {x: 0, y: 0}, max: {x: 0, y: 0}}")
}

///|
test "BBox2D from_positions - empty" {
  try BBox2D::from_positions([]) |> ignore catch {
    EmptyPositionsError(msg) => inspect(msg, content="Positions array is empty")
  }
}

///|
test "BBox2D to_json - simple" {
  let min = Position2D::new((0, 0))
  let max = Position2D::new((1, 1))
  let bbox = BBox2D::new(min, max)
  @json.inspect(bbox, content=[0, 0, 1, 1])
}

///|
test "BBox2D from_json - simple" {
  let bbox : BBox2D = @json.from_json([0, 0, 1, 1])
  inspect(bbox, content="{min: {x: 0, y: 0}, max: {x: 1, y: 1}}")
}

///|
test "BBox2D to_bbox" {
  let min = Position2D::new((0, 0))
  let max = Position2D::new((1, 1))
  let bbox = BBox2D::new(min, max)
  inspect(
    bbox.to_bbox(),
    content="BBox2D({min: {x: 0, y: 0}, max: {x: 1, y: 1}})",
  )
}
