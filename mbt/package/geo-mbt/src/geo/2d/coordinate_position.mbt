// Ported from georust/geo
// https://github.com/georust/geo/blob/main/geo/src/algorithm/coordinate_position.rs

///|
/// The position of a `Coord` relative to a geometry.
pub(all) enum CoordPos {
  OnBoundary
  Inside
  Outside
} derive(Eq, Debug)

///|
/// Returns whether `value` lies between `bound_a` and `bound_b` (inclusive).
fn value_in_between(value : Double, bound_a : Double, bound_b : Double) -> Bool {
  let (lo, hi) = if bound_a <= bound_b {
    (bound_a, bound_b)
  } else {
    (bound_b, bound_a)
  }
  value >= lo && value <= hi
}

///|
/// Returns whether `coord` lies inside (strictly) `rect`. Boundary returns
/// false.
fn point_strictly_in_rect(coord : @type.Coord, rect : @type.Rect) -> Bool {
  coord.x() > rect.min().x() &&
  coord.x() < rect.max().x() &&
  coord.y() > rect.min().y() &&
  coord.y() < rect.max().y()
}

///|
/// Returns whether `coord` lies on the segment `line` (including endpoints).
pub fn coord_on_line(coord : @type.Coord, line : @type.Line) -> Bool {
  let det = @robust.orient2d(line.start(), line.end(), coord)
  if det != 0.0 {
    return false
  }
  // Collinear - check it's within the segment's bounding box
  value_in_between(coord.x(), line.start().x(), line.end().x()) &&
  value_in_between(coord.y(), line.start().y(), line.end().y())
}

///|
/// Returns the position of `coord` relative to `line`. Endpoints are
/// `OnBoundary`; strict interior of the segment is `Inside`.
pub fn coord_position_for_line(
  coord : @type.Coord,
  line : @type.Line,
) -> CoordPos {
  if line.start() == line.end() {
    return if coord == line.start() { Inside } else { Outside }
  }
  if coord == line.start() || coord == line.end() {
    return OnBoundary
  }
  if coord_on_line(coord, line) {
    Inside
  } else {
    Outside
  }
}

///|
/// Returns the position of `coord` relative to a `LineString`. Endpoints (for
/// open line strings) are `OnBoundary`; closed line strings have no boundary.
pub fn coord_position_for_line_string(
  coord : @type.Coord,
  ls : @type.LineString,
) -> CoordPos {
  let coords = ls.coords()
  let n = coords.length()
  if n < 2 {
    return Outside
  }
  // The endpoint logic: open line string has start/end as boundary; closed
  // line string treats both as Inside (the boundary set is empty per OGC).
  let is_closed = coords[0] == coords[n - 1]
  if !is_closed && (coord == coords[0] || coord == coords[n - 1]) {
    return OnBoundary
  }
  for line in ls.lines() {
    if coord_on_line(coord, line) {
      return Inside
    }
  }
  Outside
}

///|
/// Returns whether `coord` lies inside, on boundary of, or outside the
/// polygon defined by a single closed ring.
fn coord_position_in_ring(
  coord : @type.Coord,
  ring : @type.LineString,
) -> CoordPos {
  // First, check if the coord lies on any edge of the ring.
  for line in ring.lines() {
    if coord_on_line(coord, line) {
      return OnBoundary
    }
  }
  // Then, ray-casting test for interior.
  let coords = ring.coords()
  let mut inside = false
  let mut j = coords.length() - 1
  for i = 0; i < coords.length(); i = i + 1 {
    let xi = coords[i].x()
    let yi = coords[i].y()
    let xj = coords[j].x()
    let yj = coords[j].y()
    let intersect = (yi > coord.y()) != (yj > coord.y()) &&
      coord.x() < (xj - xi) * (coord.y() - yi) / (yj - yi) + xi
    if intersect {
      inside = !inside
    }
    j = i
  }
  if inside {
    Inside
  } else {
    Outside
  }
}

///|
/// Returns the position of `coord` relative to a `Polygon`. Walks the
/// exterior ring (Inside, OnBoundary, Outside), then for points classified
/// `Inside` checks whether they fall on or inside any interior ring.
pub fn coord_position_for_polygon(
  coord : @type.Coord,
  polygon : @type.Polygon,
) -> CoordPos {
  match coord_position_in_ring(coord, polygon.exterior()) {
    Outside => Outside
    OnBoundary => OnBoundary
    Inside => {
      for interior in polygon.interiors() {
        match coord_position_in_ring(coord, interior) {
          OnBoundary => return OnBoundary
          Inside => return Outside // hole interior is exterior of the polygon
          _ => continue
        }
      }
      Inside
    }
  }
}

///|
pub fn coord_position_for_multi_polygon(
  coord : @type.Coord,
  mp : @type.MultiPolygon,
) -> CoordPos {
  let mut on_boundary = false
  for poly in mp.polygons() {
    match coord_position_for_polygon(coord, poly) {
      Inside => return Inside
      OnBoundary => on_boundary = true
      _ => continue
    }
  }
  if on_boundary {
    OnBoundary
  } else {
    Outside
  }
}

///|
pub fn coord_position_for_rect(
  coord : @type.Coord,
  rect : @type.Rect,
) -> CoordPos {
  if point_strictly_in_rect(coord, rect) {
    return Inside
  }
  // Check boundary
  let on_x = coord.x() == rect.min().x() || coord.x() == rect.max().x()
  let on_y = coord.y() == rect.min().y() || coord.y() == rect.max().y()
  let in_x_range = value_in_between(coord.x(), rect.min().x(), rect.max().x())
  let in_y_range = value_in_between(coord.y(), rect.min().y(), rect.max().y())
  if (on_x && in_y_range) || (on_y && in_x_range) {
    OnBoundary
  } else {
    Outside
  }
}

///|
pub fn coord_position_for_triangle(
  coord : @type.Coord,
  t : @type.Triangle,
) -> CoordPos {
  coord_position_for_polygon(coord, t.to_polygon())
}

///|
/// Returns the position of `coord` relative to a `Geometry`. For Point and
/// MultiPoint, `Inside` means equal-to-some-point.
pub fn coord_position_for_geometry(
  coord : @type.Coord,
  g : @type.Geometry,
) -> CoordPos {
  match g {
    @type.Geometry::Point(p) =>
      if p.coord() == coord {
        Inside
      } else {
        Outside
      }
    @type.Geometry::Line(l) => coord_position_for_line(coord, l)
    @type.Geometry::LineString(ls) => coord_position_for_line_string(coord, ls)
    @type.Geometry::Polygon(p) => coord_position_for_polygon(coord, p)
    @type.Geometry::MultiPoint(mp) => {
      for p in mp.points() {
        if p.coord() == coord {
          return Inside
        }
      }
      Outside
    }
    @type.Geometry::MultiLineString(mls) => {
      let mut on_boundary = false
      for ls in mls.line_strings() {
        match coord_position_for_line_string(coord, ls) {
          Inside => return Inside
          OnBoundary => on_boundary = !on_boundary
          _ => continue
        }
      }
      if on_boundary {
        OnBoundary
      } else {
        Outside
      }
    }
    @type.Geometry::MultiPolygon(mp) =>
      coord_position_for_multi_polygon(coord, mp)
    @type.Geometry::Rect(r) => coord_position_for_rect(coord, r)
    @type.Geometry::Triangle(t) => coord_position_for_triangle(coord, t)
    @type.Geometry::GeometryCollection(gc) => {
      let mut is_inside = false
      let mut boundary_count = 0
      for g2 in gc.geometries() {
        match coord_position_for_geometry(coord, g2) {
          Inside => is_inside = true
          OnBoundary => boundary_count = boundary_count + 1
          _ => continue
        }
      }
      if boundary_count % 2 == 1 {
        OnBoundary
      } else if is_inside {
        Inside
      } else {
        Outside
      }
    }
  }
}
