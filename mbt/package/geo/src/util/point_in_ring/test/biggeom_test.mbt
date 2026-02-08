///|
test "point_in_ring - Switzerland inside" {
  let result = @point_in_ring.point_in_ring(
    @type.XY::new(8.0, 46.5),
    @fixture.switzerland,
  )
  inspect(result, content="Inside")
}

///|
test "point_in_ring - Switzerland outside" {
  let result = @point_in_ring.point_in_ring(
    @type.XY::new(8.0, 44.0),
    @fixture.switzerland,
  )
  inspect(result, content="Outside")
}

///|
test "point_in_ring - kinked Switzerland inside" {
  let result = @point_in_ring.point_in_ring(
    @type.XY::new(8.0, 46.5),
    @fixture.switzerlandKinked,
  )
  inspect(result, content="Inside")
}

///|
test "point_in_ring - kinked Switzerland outside" {
  let result = @point_in_ring.point_in_ring(
    @type.XY::new(8.0, 44.0),
    @fixture.switzerlandKinked,
  )
  inspect(result, content="Outside")
}
