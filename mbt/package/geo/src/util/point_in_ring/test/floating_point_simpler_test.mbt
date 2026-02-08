///|
test "point_in_ring - floating simple bottom edge" {
  let ring = @type.Ring::new([
    @type.XY::new(1.111111111111, 1.111111111111),
    @type.XY::new(1.111111111111, 2.111111111111),
    @type.XY::new(2.111111111111, 2.111111111111),
    @type.XY::new(2.111111111111, 1.111111111111),
    @type.XY::new(1.111111111111, 1.111111111111),
  ])
  let result = @point_in_ring.point_in_ring(
    @type.XY::new(1.511111111111, 1.111111111111),
    ring,
  )
  inspect(result, content="Boundary")
}

///|
test "point_in_ring - floating simple top edge" {
  let ring = @type.Ring::new([
    @type.XY::new(1.111111111111, 1.111111111111),
    @type.XY::new(1.111111111111, 2.111111111111),
    @type.XY::new(2.111111111111, 2.111111111111),
    @type.XY::new(2.111111111111, 1.111111111111),
    @type.XY::new(1.111111111111, 1.111111111111),
  ])
  let result = @point_in_ring.point_in_ring(
    @type.XY::new(1.511111111111, 2.111111111111),
    ring,
  )
  inspect(result, content="Boundary")
}

///|
test "point_in_ring - floating simple left edge" {
  let ring = @type.Ring::new([
    @type.XY::new(1.111111111111, 1.111111111111),
    @type.XY::new(1.111111111111, 2.111111111111),
    @type.XY::new(2.111111111111, 2.111111111111),
    @type.XY::new(2.111111111111, 1.111111111111),
    @type.XY::new(1.111111111111, 1.111111111111),
  ])
  let result = @point_in_ring.point_in_ring(
    @type.XY::new(1.111111111111, 1.511111111111),
    ring,
  )
  inspect(result, content="Boundary")
}

///|
test "point_in_ring - floating simple right edge" {
  let ring = @type.Ring::new([
    @type.XY::new(1.111111111111, 1.111111111111),
    @type.XY::new(1.111111111111, 2.111111111111),
    @type.XY::new(2.111111111111, 2.111111111111),
    @type.XY::new(2.111111111111, 1.111111111111),
    @type.XY::new(1.111111111111, 1.111111111111),
  ])
  let result = @point_in_ring.point_in_ring(
    @type.XY::new(2.111111111111, 1.511111111111),
    ring,
  )
  inspect(result, content="Boundary")
}

///|
test "point_in_ring - floating simple just inside left" {
  let ring = @type.Ring::new([
    @type.XY::new(1.111111111111, 1.111111111111),
    @type.XY::new(1.111111111111, 2.111111111111),
    @type.XY::new(2.111111111111, 2.111111111111),
    @type.XY::new(2.111111111111, 1.111111111111),
    @type.XY::new(1.111111111111, 1.111111111111),
  ])
  let result = @point_in_ring.point_in_ring(
    @type.XY::new(1.1111111111111, 1.511111111111),
    ring,
  )
  inspect(result, content="Inside")
}

///|
test "point_in_ring - floating simple just outside left" {
  let ring = @type.Ring::new([
    @type.XY::new(1.111111111111, 1.111111111111),
    @type.XY::new(1.111111111111, 2.111111111111),
    @type.XY::new(2.111111111111, 2.111111111111),
    @type.XY::new(2.111111111111, 1.111111111111),
    @type.XY::new(1.111111111111, 1.111111111111),
  ])
  let result = @point_in_ring.point_in_ring(
    @type.XY::new(1.111111111110, 1.511111111111),
    ring,
  )
  inspect(result, content="Outside")
}
