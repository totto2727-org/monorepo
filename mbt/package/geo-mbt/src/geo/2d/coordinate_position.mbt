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
  if ls.lines_iter().any(fn(line) { coord_on_line(coord, line) }) {
    Inside
  } else {
    Outside
  }
}

///|
/// Returns whether `coord` lies inside, on boundary of, or outside the
/// polygon defined by a single closed ring.
fn coord_position_in_ring(
  coord : @type.Coord,
  ring : @type.LineString,
) -> CoordPos {
  // First, check if the coord lies on any edge of the ring.
  if ring.lines_iter().any(fn(line) { coord_on_line(coord, line) }) {
    return OnBoundary
  }
  // Ray-casting test for interior. Each edge `(coords[j], coords[i])` toggles
  // `inside` if the horizontal ray from `coord` crosses it. `j` is `i - 1`
  // wrapped around to the last index for the closing edge.
  let coords = ring.coords()
  let n = coords.length()
  let inside = (0)
    .until(n)
    .fold(init=false, fn(acc, i) {
      let j = if i == 0 { n - 1 } else { i - 1 }
      let xi = coords[i].x()
      let yi = coords[i].y()
      let xj = coords[j].x()
      let yj = coords[j].y()
      let intersect = (yi > coord.y()) != (yj > coord.y()) &&
        coord.x() < (xj - xi) * (coord.y() - yi) / (yj - yi) + xi
      if intersect {
        !acc
      } else {
        acc
      }
    })
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
    Inside =>
      // Reduce over the holes: hole-boundary wins, hole-interior demotes to
      // Outside, otherwise the running `Inside` survives. `find_first` does
      // not short-circuit eagerly enough to be worth the extra wrapping —
      // fold matches the imperative early-return semantics.
      polygon
      .interiors()
      .iter()
      .fold(init=CoordPos::Inside, fn(acc, interior) {
        match acc {
          OnBoundary => acc
          Outside => acc
          _ =>
            match coord_position_in_ring(coord, interior) {
              OnBoundary => OnBoundary
              Inside => Outside
              _ => acc
            }
        }
      })
  }
}

///|
pub fn coord_position_for_multi_polygon(
  coord : @type.Coord,
  mp : @type.MultiPolygon,
) -> CoordPos {
  // Inside any polygon dominates; otherwise OnBoundary if any polygon's
  // boundary is touched; otherwise Outside.
  mp
  .polygons()
  .iter()
  .fold(init=CoordPos::Outside, fn(acc, poly) {
    match acc {
      Inside => acc
      _ =>
        match coord_position_for_polygon(coord, poly) {
          Inside => Inside
          OnBoundary => OnBoundary
          Outside => acc
        }
    }
  })
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
    @type.Geometry::MultiPoint(mp) =>
      if mp.points().iter().any(fn(p) { p.coord() == coord }) {
        Inside
      } else {
        Outside
      }
    @type.Geometry::MultiLineString(mls) => {
      // Track (locked_inside, boundary_count_parity). Once `Inside` is
      // observed it locks (Inside dominates);
      // otherwise OnBoundary if odd boundary count, else Outside.
      let acc = mls
        .line_strings()
        .iter()
        .fold(init=(false, false), fn(acc, ls) {
          let (locked, parity) = acc
          if locked {
            acc
          } else {
            match coord_position_for_line_string(coord, ls) {
              Inside => (true, parity)
              OnBoundary => (false, !parity)
              Outside => acc
            }
          }
        })
      let (locked, parity) = acc
      if locked {
        Inside
      } else if parity {
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
      let acc = gc
        .geometries()
        .iter()
        .fold(init=(false, 0), fn(acc, g2) {
          let (is_inside, boundary_count) = acc
          match coord_position_for_geometry(coord, g2) {
            Inside => (true, boundary_count)
            OnBoundary => (is_inside, boundary_count + 1)
            Outside => acc
          }
        })
      let (is_inside, boundary_count) = acc
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
