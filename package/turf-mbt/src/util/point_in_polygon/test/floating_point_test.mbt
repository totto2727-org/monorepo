///|
test "is on edge poly" {
  let polygon = [
    [
      (-115.1752628, 36.0873974),
      (-115.1752969, 36.0873974),
      (-115.1752969, 36.0874526),
      (-115.1752628, 36.0874526),
      (-115.1752628, 36.0873974),
    ],
  ]
  let result = @point_in_polygon.point_in_polygon(
    -115.1752799, 36.0874526, polygon,
  )
  inspect(result, content="Boundary")
}

///|
test "is on other edge poly" {
  let polygon = [
    [
      (-115.1752628, 36.0873974),
      (-115.1752969, 36.0873974),
      (-115.1752969, 36.0874526),
      (-115.1752628, 36.0874526),
      (-115.1752628, 36.0873974),
    ],
  ]
  let result = @point_in_polygon.point_in_polygon(
    -115.1752799, 36.0873974, polygon,
  )
  inspect(result, content="Boundary")
}

///|
test "is on edge slightly tweaked poly" {
  let shiftedPoly = [
    [
      (-115.1752628, 36.0873974),
      (-115.1752969, 36.0873974),
      (-115.1752969, 36.0874528),
      (-115.1752628, 36.0874528),
      (-115.1752628, 36.0873974),
    ],
  ]
  let result = @point_in_polygon.point_in_polygon(
    -115.1752799, 36.0874528, shiftedPoly,
  )
  inspect(result, content="Boundary")
}

///|
test "is on other edge slightly tweaked poly" {
  let shiftedPoly = [
    [
      (-115.1752628, 36.0873974),
      (-115.1752969, 36.0873974),
      (-115.1752969, 36.0874528),
      (-115.1752628, 36.0874528),
      (-115.1752628, 36.0873974),
    ],
  ]
  let result = @point_in_polygon.point_in_polygon(
    -115.1752799, 36.0873974, shiftedPoly,
  )
  inspect(result, content="Boundary")
}

///|
test "complex case" {
  let polygon = [
    [
      (0.9500000000001119, 0.9500000000001101),
      (18.0, 18.0),
      (18.0, 0.95),
      (0.9500000000001119, 0.9500000000001101),
    ],
  ]
  let result = @point_in_polygon.point_in_polygon(16.8, 16.8, polygon)
  inspect(result, content="Outside")
}

///|
test "complex case #2" {
  let polygon = [
    [
      (51.65906944711844, 32.644344469605144),
      (51.643474062027934, 32.64597280574026),
      (51.6602114368668, 32.658994206590506),
      (51.64382208072604, 32.65965256535195),
      (51.65906944711844, 32.644344469605144),
    ],
  ]
  let point = (51.6476999685446, 32.65383784687809)
  let result = @point_in_polygon.point_in_polygon(point.0, point.1, polygon)
  inspect(result, content="Outside")
}
