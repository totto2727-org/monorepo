///|
test "BBox3D to_json - simple" {
  let min = @position.Position3D::new((0, 0, 1))
  let max = @position.Position3D::new((1, 2, 2))
  let bbox = BBox3D::new(min, max)
  @json.inspect(bbox, content=[0, 0, 1, 1, 2, 2])
}

///|
test "BBox3D from_json - simple" {
  let bbox : BBox3D = @json.from_json([0, 0, 1, 1, 2, 2])
  inspect(bbox, content="{min: {x: 0, y: 0, z: 1}, max: {x: 1, y: 2, z: 2}}")
}

///|
test "BBox3D to_bbox" {
  let bbox = BBox3D::new(
    @position.Position3D::new((0, 0, 1)),
    @position.Position3D::new((1, 2, 2)),
  ).to_bbox()
  inspect(
    bbox,
    content="BBox3D({min: {x: 0, y: 0, z: 1}, max: {x: 1, y: 2, z: 2}})",
  )
}
