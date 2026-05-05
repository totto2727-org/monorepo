// Ported from georust/geo
// https://github.com/georust/geo/blob/main/geo/src/algorithm/intersects/

///|
/// Returns whether two coordinates are equal.
pub fn intersects_coord_coord(a : @type.Coord, b : @type.Coord) -> Bool {
  a == b
}

///|
/// Returns whether `coord` lies on `line` (including endpoints).
pub fn intersects_coord_line(coord : @type.Coord, line : @type.Line) -> Bool {
  coord_on_line(coord, line)
}

///|
/// Returns whether two line segments intersect (including endpoints and
/// collinear overlaps).
pub fn intersects_line_line(a : @type.Line, b : @type.Line) -> Bool {
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
pub fn intersects_coord_line_string(
  coord : @type.Coord,
  ls : @type.LineString,
) -> Bool {
  for line in ls.lines() {
    if coord_on_line(coord, line) {
      return true
    }
  }
  false
}

///|
pub fn intersects_line_line_string(
  l : @type.Line,
  ls : @type.LineString,
) -> Bool {
  for segment in ls.lines() {
    if intersects_line_line(l, segment) {
      return true
    }
  }
  false
}

///|
pub fn intersects_line_string_line_string(
  a : @type.LineString,
  b : @type.LineString,
) -> Bool {
  for la in a.lines() {
    for lb in b.lines() {
      if intersects_line_line(la, lb) {
        return true
      }
    }
  }
  false
}

///|
pub fn intersects_coord_polygon(
  coord : @type.Coord,
  p : @type.Polygon,
) -> Bool {
  match coord_position_for_polygon(coord, p) {
    Outside => false
    _ => true
  }
}

///|
pub fn intersects_line_polygon(l : @type.Line, p : @type.Polygon) -> Bool {
  // Either endpoint inside or on boundary, or any segment intersects a ring edge
  if intersects_coord_polygon(l.start(), p) {
    return true
  }
  if intersects_coord_polygon(l.end(), p) {
    return true
  }
  for edge in p.exterior().lines() {
    if intersects_line_line(l, edge) {
      return true
    }
  }
  for interior in p.interiors() {
    for edge in interior.lines() {
      if intersects_line_line(l, edge) {
        return true
      }
    }
  }
  false
}

///|
pub fn intersects_polygon_polygon(
  a : @type.Polygon,
  b : @type.Polygon,
) -> Bool {
  // Check if any vertex of a is inside or on boundary of b, or vice versa
  for c in a.exterior().coords() {
    if intersects_coord_polygon(c, b) {
      return true
    }
  }
  for c in b.exterior().coords() {
    if intersects_coord_polygon(c, a) {
      return true
    }
  }
  // Check edge-edge intersection
  for ea in a.exterior().lines() {
    for eb in b.exterior().lines() {
      if intersects_line_line(ea, eb) {
        return true
      }
    }
  }
  false
}

///|
pub fn intersects_rect_coord(rect : @type.Rect, coord : @type.Coord) -> Bool {
  match coord_position_for_rect(coord, rect) {
    Outside => false
    _ => true
  }
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
    (@type.Geometry::Line(l1), @type.Geometry::Line(l2)) => intersects_line_line(l1, l2)
    (@type.Geometry::Line(l), @type.Geometry::LineString(ls)) =>
      intersects_line_line_string(l, ls)
    (@type.Geometry::LineString(ls), @type.Geometry::Line(l)) =>
      intersects_line_line_string(l, ls)
    (@type.Geometry::LineString(ls1), @type.Geometry::LineString(ls2)) =>
      intersects_line_string_line_string(ls1, ls2)
    (@type.Geometry::Line(l), @type.Geometry::Polygon(p)) => intersects_line_polygon(l, p)
    (@type.Geometry::Polygon(p), @type.Geometry::Line(l)) => intersects_line_polygon(l, p)
    (@type.Geometry::Polygon(p1), @type.Geometry::Polygon(p2)) =>
      intersects_polygon_polygon(p1, p2)
    (@type.Geometry::GeometryCollection(gc), other) => {
      for g in gc.geometries() {
        if intersects_geometry(g, other) {
          return true
        }
      }
      false
    }
    (other, @type.Geometry::GeometryCollection(gc)) => {
      for g in gc.geometries() {
        if intersects_geometry(other, g) {
          return true
        }
      }
      false
    }
    // Other combinations: bounding-rect approximation as a fallback.
    (g1, g2) =>
      match (bounding_rect_of_geometry(g1), bounding_rect_of_geometry(g2)) {
        (Some(r1), Some(r2)) =>
          // Rect intersection test
          !(
            r1.max().x() < r2.min().x() ||
            r2.max().x() < r1.min().x() ||
            r1.max().y() < r2.min().y() ||
            r2.max().y() < r1.min().y()
          )
        _ => false
      }
  }
}
