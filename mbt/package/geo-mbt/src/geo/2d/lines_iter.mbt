// Ported from georust/geo
// https://github.com/georust/geo/blob/main/geo/src/algorithm/lines_iter.rs

///|
/// Returns the line segments of a `Line` (just itself).
pub fn lines_of_line(l : @type.Line) -> Array[@type.Line] {
  [l]
}

///|
/// Returns the line segments connecting consecutive coordinates of a
/// `LineString`. Empty for line strings with fewer than 2 coordinates.
pub fn lines_of_line_string(ls : @type.LineString) -> Array[@type.Line] {
  ls.lines()
}

///|
/// Returns all line segments composing a `MultiLineString`.
pub fn lines_of_multi_line_string(
  mls : @type.MultiLineString,
) -> Array[@type.Line] {
  mls.line_strings().iter().flat_map(fn(ls) { ls.lines().iter() }).collect()
}

///|
/// Returns the line segments of the polygon's exterior ring followed by
/// each interior ring's segments.
pub fn lines_of_polygon(p : @type.Polygon) -> Array[@type.Line] {
  p
  .exterior()
  .lines()
  .iter()
  .concat(
    p.interiors().iter().flat_map(fn(interior) { interior.lines().iter() }),
  )
  .collect()
}

///|
pub fn lines_of_multi_polygon(mp : @type.MultiPolygon) -> Array[@type.Line] {
  mp
  .polygons()
  .iter()
  .flat_map(fn(poly) { lines_of_polygon(poly).iter() })
  .collect()
}

///|
/// Returns the four edges of a `Rect`, going CCW starting from the
/// `min` corner. Thin wrapper around `Rect::to_lines` for parity with
/// the other `lines_of_*` dispatch entries.
pub fn lines_of_rect(r : @type.Rect) -> Array[@type.Line] {
  r.to_lines()
}

///|
pub fn lines_of_triangle(t : @type.Triangle) -> Array[@type.Line] {
  t.to_lines()
}

///|
pub fn lines_of_geometry_collection(
  gc : @type.GeometryCollection,
) -> Array[@type.Line] {
  gc
  .geometries()
  .iter()
  .flat_map(fn(g) { lines_of_geometry(g).iter() })
  .collect()
}

///|
/// Dispatches to the per-type `lines_of_*` function. For `Point` and
/// `MultiPoint` (which have no segments) returns an empty array.
pub fn lines_of_geometry(g : @type.Geometry) -> Array[@type.Line] {
  match g {
    @type.Geometry::Point(_) => []
    @type.Geometry::MultiPoint(_) => []
    @type.Geometry::Line(l) => lines_of_line(l)
    @type.Geometry::LineString(ls) => lines_of_line_string(ls)
    @type.Geometry::MultiLineString(mls) => lines_of_multi_line_string(mls)
    @type.Geometry::Polygon(p) => lines_of_polygon(p)
    @type.Geometry::MultiPolygon(mp) => lines_of_multi_polygon(mp)
    @type.Geometry::Rect(r) => lines_of_rect(r)
    @type.Geometry::Triangle(t) => lines_of_triangle(t)
    @type.Geometry::GeometryCollection(gc) => lines_of_geometry_collection(gc)
  }
}
