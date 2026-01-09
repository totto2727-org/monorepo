///|
test "point_in_ring - inside" {
  let ring = @type.Ring::new([
    @type.XY::new(1.0, 1.0),
    @type.XY::new(1.0, 2.0),
    @type.XY::new(2.0, 2.0),
    @type.XY::new(2.0, 1.0),
    @type.XY::new(1.0, 1.0),
  ])
  let result = point_in_ring(@type.XY::new(1.5, 1.5), ring)
  inspect(result, content="Inside")
}

///|
test "point_in_ring - boundary" {
  let ring = @type.Ring::new([
    @type.XY::new(1.0, 1.0),
    @type.XY::new(1.0, 2.0),
    @type.XY::new(2.0, 2.0),
    @type.XY::new(2.0, 1.0),
    @type.XY::new(1.0, 1.0),
  ])
  let result = point_in_ring(@type.XY::new(1.0, 1.5), ring)
  inspect(result, content="Boundary")
}

///|
test "point_in_ring - outside" {
  let ring = @type.Ring::new([
    @type.XY::new(1.0, 1.0),
    @type.XY::new(1.0, 2.0),
    @type.XY::new(2.0, 2.0),
    @type.XY::new(2.0, 1.0),
    @type.XY::new(1.0, 1.0),
  ])
  let result = point_in_ring(@type.XY::new(3.0, 3.0), ring)
  inspect(result, content="Outside")
}

///|
test "point_in_ring - integer coords boundary" {
  let ring = @type.Ring::new([
    @type.XY::new(1.0, 1.0),
    @type.XY::new(1.0, 2.0),
    @type.XY::new(2.0, 2.0),
    @type.XY::new(2.0, 1.0),
    @type.XY::new(1.0, 1.0),
  ])
  let result = point_in_ring(@type.XY::new(1.0, 1.0), ring)
  inspect(result, content="Boundary")
}

///|
test "point_in_ring - integer coords outside 1" {
  let ring = @type.Ring::new([
    @type.XY::new(1.0, 1.0),
    @type.XY::new(1.0, 2.0),
    @type.XY::new(2.0, 2.0),
    @type.XY::new(2.0, 1.0),
    @type.XY::new(1.0, 1.0),
  ])
  let result = point_in_ring(@type.XY::new(1.0, 0.0), ring)
  inspect(result, content="Outside")
}

///|
test "point_in_ring - integer coords outside 2" {
  let ring = @type.Ring::new([
    @type.XY::new(1.0, 1.0),
    @type.XY::new(1.0, 2.0),
    @type.XY::new(2.0, 2.0),
    @type.XY::new(2.0, 1.0),
    @type.XY::new(1.0, 1.0),
  ])
  let result = point_in_ring(@type.XY::new(0.0, 1.0), ring)
  inspect(result, content="Outside")
}

///|
test "point_in_ring - integer coords outside 3" {
  let ring = @type.Ring::new([
    @type.XY::new(1.0, 1.0),
    @type.XY::new(1.0, 2.0),
    @type.XY::new(2.0, 2.0),
    @type.XY::new(2.0, 1.0),
    @type.XY::new(1.0, 1.0),
  ])
  let result = point_in_ring(@type.XY::new(-0.5, -0.5), ring)
  inspect(result, content="Outside")
}

///|
test "point_in_ring - integer coords outside 4" {
  let ring = @type.Ring::new([
    @type.XY::new(1.0, 1.0),
    @type.XY::new(1.0, 2.0),
    @type.XY::new(2.0, 2.0),
    @type.XY::new(2.0, 1.0),
    @type.XY::new(1.0, 1.0),
  ])
  let result = point_in_ring(@type.XY::new(0.5, -0.5), ring)
  inspect(result, content="Outside")
}

///|
test "point_in_ring - wrapped around" {
  let ring = @type.Ring::new([
    @type.XY::new(-180.0, -90.0),
    @type.XY::new(-180.0, 90.0),
    @type.XY::new(180.0, 90.0),
    @type.XY::new(180.0, -90.0),
    @type.XY::new(-180.0, -90.0),
  ])
  let result = point_in_ring(@type.XY::new(140.43, 70.43), ring)
  inspect(result, content="Inside")
}
