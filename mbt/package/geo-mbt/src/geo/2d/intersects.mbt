// Ported from georust/geo
// https://github.com/georust/geo/blob/main/geo/src/algorithm/intersects/

///|
/// Returns whether `coord` lies on `line` (including endpoints).
fn intersects_coord_line(coord : @type.Coord, line : @type.Line) -> Bool {
  coord_on_line(coord, line)
}

///|
/// Returns whether two line segments intersect (including endpoints and
/// collinear overlaps).
fn intersects_line_line(a : @type.Line, b : @type.Line) -> Bool {
  // Endpoints touching count as intersection
  if a.start() == b.start() ||
    a.start() == b.end() ||
    a.end() == b.start() ||
    a.end() == b.end() {
    return true
  }
  let d1 = @robust.orient2d(a.start(), a.end(), b.start())
  let d2 = @robust.orient2d(a.start(), a.end(), b.end())
  let d3 = @robust.orient2d(b.start(), b.end(), a.start())
  let d4 = @robust.orient2d(b.start(), b.end(), a.end())
  // Standard segment-segment intersection test
  if ((d1 > 0.0 && d2 < 0.0) || (d1 < 0.0 && d2 > 0.0)) &&
    ((d3 > 0.0 && d4 < 0.0) || (d3 < 0.0 && d4 > 0.0)) {
    return true
  }
  // Collinear cases
  if d1 == 0.0 && coord_on_line(b.start(), a) {
    return true
  }
  if d2 == 0.0 && coord_on_line(b.end(), a) {
    return true
  }
  if d3 == 0.0 && coord_on_line(a.start(), b) {
    return true
  }
  if d4 == 0.0 && coord_on_line(a.end(), b) {
    return true
  }
  false
}

///|
fn intersects_coord_line_string(
  coord : @type.Coord,
  ls : @type.LineString,
) -> Bool {
  ls.lines_iter().any(fn(line) { coord_on_line(coord, line) })
}

///|
fn intersects_line_line_string(l : @type.Line, ls : @type.LineString) -> Bool {
  ls.lines_iter().any(fn(segment) { intersects_line_line(l, segment) })
}

///|
fn intersects_line_string_line_string(
  a : @type.LineString,
  b : @type.LineString,
) -> Bool {
  a
  .lines_iter()
  .any(fn(la) { b.lines_iter().any(fn(lb) { intersects_line_line(la, lb) }) })
}

///|
fn intersects_coord_polygon(coord : @type.Coord, p : @type.Polygon) -> Bool {
  match coord_position_for_polygon(coord, p) {
    Outside => false
    _ => true
  }
}

///|
fn intersects_line_polygon(l : @type.Line, p : @type.Polygon) -> Bool {
  // Either endpoint inside or on boundary, or any segment intersects a ring edge
  if intersects_coord_polygon(l.start(), p) {
    return true
  }
  if intersects_coord_polygon(l.end(), p) {
    return true
  }
  if p.exterior().lines_iter().any(fn(edge) { intersects_line_line(l, edge) }) {
    return true
  }
  p
  .interiors()
  .iter()
  .any(fn(interior) {
    interior.lines_iter().any(fn(edge) { intersects_line_line(l, edge) })
  })
}

///|
fn intersects_polygon_polygon(a : @type.Polygon, b : @type.Polygon) -> Bool {
  // Check if any vertex of a is inside or on boundary of b, or vice versa
  if a.exterior().coords().iter().any(fn(c) { intersects_coord_polygon(c, b) }) {
    return true
  }
  if b.exterior().coords().iter().any(fn(c) { intersects_coord_polygon(c, a) }) {
    return true
  }
  // Check edge-edge intersection
  a
  .exterior()
  .lines_iter()
  .any(fn(ea) {
    b.exterior().lines_iter().any(fn(eb) { intersects_line_line(ea, eb) })
  })
}

///|
/// Returns whether two `Geometry` values intersect. Currently dispatches the
/// most common pairs through the per-type functions above; uncommon pairs
/// (e.g. GeometryCollection vs GeometryCollection) recurse.
pub fn intersects_geometry(a : @type.Geometry, b : @type.Geometry) -> Bool {
  match (a, b) {
    (@type.Geometry::Point(p1), @type.Geometry::Point(p2)) => p1 == p2
    (@type.Geometry::Point(p), @type.Geometry::Line(l)) =>
      intersects_coord_line(p.coord(), l)
    (@type.Geometry::Line(l), @type.Geometry::Point(p)) =>
      intersects_coord_line(p.coord(), l)
    (@type.Geometry::Point(p), @type.Geometry::LineString(ls)) =>
      intersects_coord_line_string(p.coord(), ls)
    (@type.Geometry::LineString(ls), @type.Geometry::Point(p)) =>
      intersects_coord_line_string(p.coord(), ls)
    (@type.Geometry::Point(p), @type.Geometry::Polygon(poly)) =>
      intersects_coord_polygon(p.coord(), poly)
    (@type.Geometry::Polygon(poly), @type.Geometry::Point(p)) =>
      intersects_coord_polygon(p.coord(), poly)
    (@type.Geometry::Line(l1), @type.Geometry::Line(l2)) =>
      intersects_line_line(l1, l2)
    (@type.Geometry::Line(l), @type.Geometry::LineString(ls)) =>
      intersects_line_line_string(l, ls)
    (@type.Geometry::LineString(ls), @type.Geometry::Line(l)) =>
      intersects_line_line_string(l, ls)
    (@type.Geometry::LineString(ls1), @type.Geometry::LineString(ls2)) =>
      intersects_line_string_line_string(ls1, ls2)
    (@type.Geometry::Line(l), @type.Geometry::Polygon(p)) =>
      intersects_line_polygon(l, p)
    (@type.Geometry::Polygon(p), @type.Geometry::Line(l)) =>
      intersects_line_polygon(l, p)
    (@type.Geometry::Polygon(p1), @type.Geometry::Polygon(p2)) =>
      intersects_polygon_polygon(p1, p2)
    (@type.Geometry::GeometryCollection(gc), other) =>
      gc.geometries().iter().any(fn(g) { intersects_geometry(g, other) })
    (other, @type.Geometry::GeometryCollection(gc)) =>
      gc.geometries().iter().any(fn(g) { intersects_geometry(other, g) })
    // Other combinations: bounding-rect approximation as a fallback.
    (g1, g2) =>
      match (bounding_rect_of_geometry(g1), bounding_rect_of_geometry(g2)) {
        (Some(r1), Some(r2)) =>
          // Rect intersection test
          !(r1.max().x() < r2.min().x() ||
          r2.max().x() < r1.min().x() ||
          r1.max().y() < r2.min().y() ||
          r2.max().y() < r1.min().y())
        _ => false
      }
  }
}

// MARK: trait Intersects + impls ---------------------------------------------

///|
/// Predicate trait: `self.intersects(other)` returns true when `self` and
/// `other` share at least one point.
pub(open) trait Intersects {
  fn intersects(Self, @type.Geometry) -> Bool
}

///|
pub impl Intersects for @type.Geometry with fn intersects(self, other) {
  intersects_geometry(self, other)
}

///|
pub impl Intersects for @type.Polygon with fn intersects(self, other) {
  intersects_geometry(@type.Geometry::Polygon(self), other)
}

///|
pub impl Intersects for @type.MultiPolygon with fn intersects(self, other) {
  intersects_geometry(@type.Geometry::MultiPolygon(self), other)
}

///|
pub impl Intersects for @type.Rect with fn intersects(self, other) {
  intersects_geometry(@type.Geometry::Rect(self), other)
}

///|
pub impl Intersects for @type.Point with fn intersects(self, other) {
  intersects_geometry(@type.Geometry::Point(self), other)
}

///|
pub impl Intersects for @type.Line with fn intersects(self, other) {
  intersects_geometry(@type.Geometry::Line(self), other)
}

///|
pub impl Intersects for @type.LineString with fn intersects(self, other) {
  intersects_geometry(@type.Geometry::LineString(self), other)
}

///|
pub impl Intersects for @type.MultiLineString with fn intersects(self, other) {
  intersects_geometry(@type.Geometry::MultiLineString(self), other)
}

///|
pub impl Intersects for @type.MultiPoint with fn intersects(self, other) {
  intersects_geometry(@type.Geometry::MultiPoint(self), other)
}

///|
pub impl Intersects for @type.Triangle with fn intersects(self, other) {
  intersects_geometry(@type.Geometry::Triangle(self), other)
}

///|
pub impl Intersects for @type.GeometryCollection with fn intersects(self, other) {
  intersects_geometry(@type.Geometry::GeometryCollection(self), other)
}
