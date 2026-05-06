// Tests for Geometry::try_into_*. Mirrors the upstream Rust
// `TryFrom<Geometry<T>>` impls (which themselves replaced the now-deprecated
// `Geometry::into_*` Option-returning methods).

///|
test "try_into_point: happy path" {
  let g = @type.Geometry::Point(@type.Point::Point(1.0, 2.0))
  let p = g.try_into_point()
  assert_true(p == @type.Point::Point(1.0, 2.0))
}

///|
test "try_into_point: mismatch raises with expected/found" {
  let g = @type.Geometry::Line(@type.Line::from_tuples((0.0, 0.0), (1.0, 1.0)))
  match (try? g.try_into_point()) {
    Err(@type.MismatchedGeometry(expected~, found~)) => {
      assert_eq(expected, "Point")
      assert_eq(found, "Line")
    }
    Ok(_) => abort("expected mismatch error")
  }
}

///|
test "try_into_line / line_string / polygon: happy paths" {
  let line = @type.Line::from_tuples((0.0, 0.0), (1.0, 1.0))
  assert_true(@type.Geometry::Line(line).try_into_line() == line)
  let ls = @type.LineString::from_tuples([(0.0, 0.0), (1.0, 1.0)])
  assert_true(@type.Geometry::LineString(ls).try_into_line_string() == ls)
  let exterior = @type.LineString::from_tuples([
    (0.0, 0.0),
    (1.0, 0.0),
    (1.0, 1.0),
    (0.0, 1.0),
  ])
  let polygon = @type.Polygon::Polygon(exterior, [])
  assert_true(@type.Geometry::Polygon(polygon).try_into_polygon() == polygon)
}

///|
test "try_into_multi_*: happy paths" {
  let mp = @type.MultiPoint::from_tuples([(0.0, 0.0), (1.0, 1.0)])
  assert_true(@type.Geometry::MultiPoint(mp).try_into_multi_point() == mp)
  let mls = @type.MultiLineString::MultiLineString([
    @type.LineString::from_tuples([(0.0, 0.0), (1.0, 1.0)]),
  ])
  assert_true(
    @type.Geometry::MultiLineString(mls).try_into_multi_line_string() == mls,
  )
  let exterior = @type.LineString::from_tuples([
    (0.0, 0.0),
    (1.0, 0.0),
    (1.0, 1.0),
  ])
  let mpoly = @type.MultiPolygon::MultiPolygon([
    @type.Polygon::Polygon(exterior, []),
  ])
  assert_true(
    @type.Geometry::MultiPolygon(mpoly).try_into_multi_polygon() == mpoly,
  )
}

///|
test "try_into_geometry_collection: happy path" {
  let gc = @type.GeometryCollection::GeometryCollection([
    @type.Geometry::Point(@type.Point::Point(1.0, 2.0)),
  ])
  assert_true(
    @type.Geometry::GeometryCollection(gc).try_into_geometry_collection() == gc,
  )
}

///|
test "try_into_rect / try_into_triangle: happy paths" {
  let r = @type.Rect::Rect(@type.Coord(0.0, 0.0), @type.Coord(1.0, 1.0))
  assert_true(@type.Geometry::Rect(r).try_into_rect() == r)
  let t = @type.Triangle::Triangle(
    @type.Coord(0.0, 0.0),
    @type.Coord(1.0, 0.0),
    @type.Coord(0.0, 1.0),
  )
  assert_true(@type.Geometry::Triangle(t).try_into_triangle() == t)
}

///|
test "try_into_*: every other variant -> mismatch with correct found name" {
  // Use a Polygon as the actual variant; verify each non-Polygon try_into
  // raises with `found = \"Polygon\"`.
  let exterior = @type.LineString::from_tuples([
    (0.0, 0.0),
    (1.0, 0.0),
    (1.0, 1.0),
    (0.0, 1.0),
  ])
  let g = @type.Geometry::Polygon(@type.Polygon::Polygon(exterior, []))
  let extracted_found = match (try? g.try_into_point()) {
    Err(@type.MismatchedGeometry(found~, ..)) => found
    _ => abort("expected mismatch")
  }
  assert_eq(extracted_found, "Polygon")
  let extracted_found_2 = match (try? g.try_into_line()) {
    Err(@type.MismatchedGeometry(found~, ..)) => found
    _ => abort("expected mismatch")
  }
  assert_eq(extracted_found_2, "Polygon")
  let extracted_found_3 = match (try? g.try_into_rect()) {
    Err(@type.MismatchedGeometry(found~, ..)) => found
    _ => abort("expected mismatch")
  }
  assert_eq(extracted_found_3, "Polygon")
}
