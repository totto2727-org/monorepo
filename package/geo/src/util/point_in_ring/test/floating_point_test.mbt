///|
test "point_in_ring - floating point on edge" {
  let ring = @type.Ring::new([
    @type.XY::new(-115.1752628, 36.0873974),
    @type.XY::new(-115.1752969, 36.0873974),
    @type.XY::new(-115.1752969, 36.0874526),
    @type.XY::new(-115.1752628, 36.0874526),
    @type.XY::new(-115.1752628, 36.0873974),
  ])
  let result = @point_in_ring.point_in_ring(
    @type.XY::new(-115.1752799, 36.0874526),
    ring,
  )
  inspect(result, content="Boundary")
}

///|
test "point_in_ring - floating point on other edge" {
  let ring = @type.Ring::new([
    @type.XY::new(-115.1752628, 36.0873974),
    @type.XY::new(-115.1752969, 36.0873974),
    @type.XY::new(-115.1752969, 36.0874526),
    @type.XY::new(-115.1752628, 36.0874526),
    @type.XY::new(-115.1752628, 36.0873974),
  ])
  let result = @point_in_ring.point_in_ring(
    @type.XY::new(-115.1752799, 36.0873974),
    ring,
  )
  inspect(result, content="Boundary")
}

///|
test "point_in_ring - floating point on tweaked edge" {
  let ring = @type.Ring::new([
    @type.XY::new(-115.1752628, 36.0873974),
    @type.XY::new(-115.1752969, 36.0873974),
    @type.XY::new(-115.1752969, 36.0874528),
    @type.XY::new(-115.1752628, 36.0874528),
    @type.XY::new(-115.1752628, 36.0873974),
  ])
  let result = @point_in_ring.point_in_ring(
    @type.XY::new(-115.1752799, 36.0874528),
    ring,
  )
  inspect(result, content="Boundary")
}

///|
test "point_in_ring - floating point on other tweaked edge" {
  let ring = @type.Ring::new([
    @type.XY::new(-115.1752628, 36.0873974),
    @type.XY::new(-115.1752969, 36.0873974),
    @type.XY::new(-115.1752969, 36.0874528),
    @type.XY::new(-115.1752628, 36.0874528),
    @type.XY::new(-115.1752628, 36.0873974),
  ])
  let result = @point_in_ring.point_in_ring(
    @type.XY::new(-115.1752799, 36.0873974),
    ring,
  )
  inspect(result, content="Boundary")
}

///|
test "point_in_ring - complex case 1" {
  let ring = @type.Ring::new([
    @type.XY::new(0.9500000000001119, 0.9500000000001101),
    @type.XY::new(18.0, 18.0),
    @type.XY::new(18.0, 0.95),
    @type.XY::new(0.9500000000001119, 0.9500000000001101),
  ])
  let result = @point_in_ring.point_in_ring(@type.XY::new(16.8, 16.8), ring)
  inspect(result, content="Outside")
}

///|
test "point_in_ring - complex case 2" {
  let ring = @type.Ring::new([
    @type.XY::new(51.65906944711844, 32.644344469605144),
    @type.XY::new(51.643474062027934, 32.64597280574026),
    @type.XY::new(51.6602114368668, 32.658994206590506),
    @type.XY::new(51.64382208072604, 32.65965256535195),
    @type.XY::new(51.65906944711844, 32.644344469605144),
  ])
  let point = @type.XY::new(51.6476999685446, 32.65383784687809)
  let result = @point_in_ring.point_in_ring(point, ring)
  inspect(result, content="Outside")
}
