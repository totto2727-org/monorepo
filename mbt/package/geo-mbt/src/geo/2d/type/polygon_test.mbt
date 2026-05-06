// Tests ported from georust/geo-types geometry/polygon.rs doctests.

///|
test "Polygon closes exterior ring" {
  let exterior = @type.LineString::from_tuples([
    (0.0, 0.0),
    (1.0, 0.0),
    (1.0, 1.0),
    (0.0, 1.0),
  ])
  let polygon = @type.Polygon::Polygon(exterior, [])
  // The exterior should now be closed
  assert_true(polygon.exterior().is_closed())
  assert_eq(polygon.exterior().length(), 5)
  assert_eq(polygon.num_interiors(), 0)
}

///|
test "Polygon closes interior rings" {
  let exterior = @type.LineString::from_tuples([
    (0.0, 0.0),
    (10.0, 0.0),
    (10.0, 10.0),
    (0.0, 10.0),
  ])
  let interior = @type.LineString::from_tuples([
    (3.0, 3.0),
    (7.0, 3.0),
    (7.0, 7.0),
    (3.0, 7.0),
  ])
  let polygon = @type.Polygon::Polygon(exterior, [interior])
  assert_eq(polygon.num_interiors(), 1)
  assert_true(polygon.interiors()[0].is_closed())
}

///|
test "Polygon already-closed exterior is preserved" {
  let exterior = @type.LineString::from_tuples([
    (0.0, 0.0),
    (1.0, 0.0),
    (1.0, 1.0),
    (0.0, 1.0),
    (0.0, 0.0),
  ])
  let polygon = @type.Polygon::Polygon(exterior, [])
  assert_eq(polygon.exterior().length(), 5)
}

///|
test "Polygon constructor does not mutate input LineStrings" {
  let user_exterior = @type.LineString::from_tuples([
    (0.0, 0.0),
    (1.0, 0.0),
    (1.0, 1.0),
    (0.0, 1.0),
  ])
  let user_interior = @type.LineString::from_tuples([
    (0.3, 0.3),
    (0.7, 0.3),
    (0.7, 0.7),
    (0.3, 0.7),
  ])
  let exterior_len_before = user_exterior.length()
  let interior_len_before = user_interior.length()
  let _ = @type.Polygon::Polygon(user_exterior, [user_interior])
  // Caller's references remain unmutated even though the canonical
  // constructor closes both rings inside the resulting Polygon.
  assert_eq(user_exterior.length(), exterior_len_before)
  assert_eq(user_interior.length(), interior_len_before)
  assert_true(!user_exterior.is_closed())
  assert_true(!user_interior.is_closed())
}

///|
test "Polygon::num_rings = num_interiors + 1" {
  let exterior = @type.LineString::from_tuples([
    (0.0, 0.0),
    (10.0, 0.0),
    (10.0, 10.0),
    (0.0, 10.0),
  ])
  let solo = @type.Polygon::Polygon(exterior, [])
  assert_eq(solo.num_interiors(), 0)
  assert_eq(solo.num_rings(), 1)
  let interior = @type.LineString::from_tuples([
    (3.0, 3.0),
    (7.0, 3.0),
    (7.0, 7.0),
    (3.0, 7.0),
  ])
  let with_hole = solo.pushed_interior(interior)
  assert_eq(with_hole.num_interiors(), 1)
  assert_eq(with_hole.num_rings(), 2)
}

///|
test "Polygon::is_empty: false for any polygon with non-empty exterior" {
  let exterior = @type.LineString::from_tuples([
    (0.0, 0.0),
    (1.0, 0.0),
    (1.0, 1.0),
    (0.0, 1.0),
  ])
  let polygon = @type.Polygon::Polygon(exterior, [])
  assert_true(!polygon.is_empty())
}

///|
test "Polygon::is_empty: true when exterior is empty" {
  let polygon = @type.Polygon::Polygon(@type.LineString::empty(), [])
  assert_true(polygon.is_empty())
}

///|
test "pushed_interior: appends and auto-closes the new interior" {
  let exterior = @type.LineString::from_tuples([
    (0.0, 0.0),
    (10.0, 0.0),
    (10.0, 10.0),
    (0.0, 10.0),
  ])
  let original = @type.Polygon::Polygon(exterior, [])
  let new_interior = @type.LineString::from_tuples([
    (3.0, 3.0),
    (7.0, 3.0),
    (7.0, 7.0),
    (3.0, 7.0),
  ])
  let updated = original.pushed_interior(new_interior)
  assert_eq(updated.num_interiors(), 1)
  // The appended ring is auto-closed (5 coords = 4 unique + closing).
  assert_true(updated.interiors()[0].is_closed())
  assert_eq(updated.interiors()[0].length(), 5)
}

///|
test "pushed_interior: original polygon is not modified" {
  let exterior = @type.LineString::from_tuples([
    (0.0, 0.0),
    (10.0, 0.0),
    (10.0, 10.0),
    (0.0, 10.0),
  ])
  let original = @type.Polygon::Polygon(exterior, [])
  let _ = original.pushed_interior(
    @type.LineString::from_tuples([
      (3.0, 3.0),
      (7.0, 3.0),
      (7.0, 7.0),
      (3.0, 7.0),
    ]),
  )
  // Original still has 0 interiors.
  assert_eq(original.num_interiors(), 0)
}

///|
test "pushed_interior: input LineString is not mutated" {
  let exterior = @type.LineString::from_tuples([
    (0.0, 0.0),
    (10.0, 0.0),
    (10.0, 10.0),
    (0.0, 10.0),
  ])
  let polygon = @type.Polygon::Polygon(exterior, [])
  let user_interior = @type.LineString::from_tuples([
    (3.0, 3.0),
    (7.0, 3.0),
    (7.0, 7.0),
    (3.0, 7.0),
  ])
  let len_before = user_interior.length()
  let was_closed_before = user_interior.is_closed()
  let _ = polygon.pushed_interior(user_interior)
  // Caller's reference must remain in its original (open, unclosed) state.
  assert_eq(user_interior.length(), len_before)
  assert_eq(user_interior.is_closed(), was_closed_before)
}

///|
test "pushed_interior: existing interiors are preserved in order" {
  let exterior = @type.LineString::from_tuples([
    (0.0, 0.0),
    (20.0, 0.0),
    (20.0, 20.0),
    (0.0, 20.0),
  ])
  let interior_a = @type.LineString::from_tuples([
    (3.0, 3.0),
    (5.0, 3.0),
    (5.0, 5.0),
    (3.0, 5.0),
  ])
  let interior_b = @type.LineString::from_tuples([
    (10.0, 10.0),
    (12.0, 10.0),
    (12.0, 12.0),
    (10.0, 12.0),
  ])
  let polygon = @type.Polygon::Polygon(exterior, [interior_a, interior_b])
  let extra = @type.LineString::from_tuples([
    (15.0, 15.0),
    (17.0, 15.0),
    (17.0, 17.0),
    (15.0, 17.0),
  ])
  let extended = polygon.pushed_interior(extra)
  assert_eq(extended.num_interiors(), 3)
  // Existing interiors keep their order; new one is at index = old_n.
  assert_true(extended.interiors()[0] == polygon.interiors()[0])
  assert_true(extended.interiors()[1] == polygon.interiors()[1])
  // The appended ring (index 2) is auto-closed.
  assert_true(extended.interiors()[2].is_closed())
}
