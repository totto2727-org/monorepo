// Tests for boolean operations (Sutherland-Hodgman initial implementation).

///|
test "intersection_polygon_rect: subject fully inside clip" {
  let subject_ext = @type.LineString::from_tuples([
    (2.0, 2.0),
    (4.0, 2.0),
    (4.0, 4.0),
    (2.0, 4.0),
  ])
  let subject = @type.Polygon::Polygon(subject_ext, [])
  let clip = @type.Rect::Rect(@type.Coord(0.0, 0.0), @type.Coord(10.0, 10.0))
  let result = intersection_polygon_rect(subject, clip)
  // Subject is entirely inside the clip → result equals subject area.
  assert_eq(unsigned_area_of_polygon(result), 4.0)
}

///|
test "intersection_polygon_rect: clip entirely inside subject" {
  let subject_ext = @type.LineString::from_tuples([
    (0.0, 0.0),
    (10.0, 0.0),
    (10.0, 10.0),
    (0.0, 10.0),
  ])
  let subject = @type.Polygon::Polygon(subject_ext, [])
  let clip = @type.Rect::Rect(@type.Coord(2.0, 2.0), @type.Coord(4.0, 4.0))
  let result = intersection_polygon_rect(subject, clip)
  // Clip is inside the subject — result should have area = clip area = 4.
  assert_eq(unsigned_area_of_polygon(result), 4.0)
}

///|
test "intersection_polygon_rect: half overlap" {
  let subject_ext = @type.LineString::from_tuples([
    (0.0, 0.0),
    (10.0, 0.0),
    (10.0, 10.0),
    (0.0, 10.0),
  ])
  let subject = @type.Polygon::Polygon(subject_ext, [])
  let clip = @type.Rect::Rect(@type.Coord(5.0, -5.0), @type.Coord(15.0, 15.0))
  let result = intersection_polygon_rect(subject, clip)
  // Right half of the subject square: 5 wide × 10 tall = 50
  assert_eq(unsigned_area_of_polygon(result), 50.0)
}

///|
test "intersection_polygon_rect: disjoint" {
  let subject_ext = @type.LineString::from_tuples([
    (0.0, 0.0),
    (1.0, 0.0),
    (1.0, 1.0),
    (0.0, 1.0),
  ])
  let subject = @type.Polygon::Polygon(subject_ext, [])
  let clip = @type.Rect::Rect(@type.Coord(10.0, 10.0), @type.Coord(20.0, 20.0))
  let result = intersection_polygon_rect(subject, clip)
  // Disjoint: result has empty exterior or zero area
  assert_eq(unsigned_area_of_polygon(result), 0.0)
}

///|
test "intersection_sutherland_hodgman: triangle clipped by triangle" {
  let subject_ext = @type.LineString::from_tuples([
    (0.0, 0.0),
    (10.0, 0.0),
    (5.0, 10.0),
  ])
  let subject = @type.Polygon::Polygon(subject_ext, [])
  let clip_ext = @type.LineString::from_tuples([
    (2.0, 2.0),
    (8.0, 2.0),
    (5.0, 8.0),
  ])
  let clip = @type.Polygon::Polygon(clip_ext, [])
  let result = intersection_sutherland_hodgman(subject, clip)
  // The clip triangle is entirely inside the subject — result equals clip
  // (area = 0.5 * 6 * 6 = 18).
  let area = unsigned_area_of_polygon(result)
  assert_true((area - 18.0).abs() < 1.0e-9)
}
