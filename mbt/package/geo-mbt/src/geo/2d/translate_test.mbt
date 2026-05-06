// Tests for translate.mbt.

///|
test "translate_polygon shifts all coords" {
  let exterior = @type.LineString::from_tuples([
    (0.0, 0.0),
    (1.0, 0.0),
    (1.0, 1.0),
    (0.0, 1.0),
  ])
  let polygon = @type.Polygon::Polygon(exterior, [])
  let translated = translate_polygon(polygon, 10.0, 20.0)
  let coords = translated.exterior().coords()
  assert_true(coords[0] == @type.Coord(10.0, 20.0))
  assert_true(coords[1] == @type.Coord(11.0, 20.0))
  assert_true(coords[2] == @type.Coord(11.0, 21.0))
}
