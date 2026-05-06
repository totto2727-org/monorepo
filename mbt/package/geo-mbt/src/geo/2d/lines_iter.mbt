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
  let result = []
  for ls in mls.line_strings() {
    for line in ls.lines() {
      result.push(line)
    }
  }
  result
}

///|
/// Returns the line segments of the polygon's exterior ring followed by
/// each interior ring's segments.
pub fn lines_of_polygon(p : @type.Polygon) -> Array[@type.Line] {
  let result = []
  for line in p.exterior().lines() {
    result.push(line)
  }
  for interior in p.interiors() {
    for line in interior.lines() {
      result.push(line)
    }
  }
  result
}

///|
pub fn lines_of_multi_polygon(mp : @type.MultiPolygon) -> Array[@type.Line] {
  let result = []
  for poly in mp.polygons() {
    for line in lines_of_polygon(poly) {
      result.push(line)
    }
  }
  result
}

///|
/// Returns the four edges of a `Rect`, going CCW starting from the
/// `min` corner.
pub fn lines_of_rect(r : @type.Rect) -> Array[@type.Line] {
  let min = r.min()
  let max = r.max()
  let bl = @type.Coord(min.x(), min.y())
  let br = @type.Coord(max.x(), min.y())
  let tr = @type.Coord(max.x(), max.y())
  let tl = @type.Coord(min.x(), max.y())
  [
    @type.Line::Line(bl, br),
    @type.Line::Line(br, tr),
    @type.Line::Line(tr, tl),
    @type.Line::Line(tl, bl),
  ]
}

///|
pub fn lines_of_triangle(t : @type.Triangle) -> Array[@type.Line] {
  t.to_lines()
}

///|
pub fn lines_of_geometry_collection(
  gc : @type.GeometryCollection,
) -> Array[@type.Line] {
  let result = []
  for g in gc.geometries() {
    for line in lines_of_geometry(g) {
      result.push(line)
    }
  }
  result
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
