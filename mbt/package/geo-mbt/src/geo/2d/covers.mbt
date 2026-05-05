// Ported from georust/geo
// https://github.com/georust/geo/blob/main/geo/src/algorithm/covers/

///|
/// `Covers` is like `Contains` but accepts boundary points.
///
/// `covers(a, b)` returns true if every point of `b` lies in `a` (interior
/// **or** boundary).
pub fn covers_polygon_coord(
  polygon : @type.Polygon,
  coord : @type.Coord,
) -> Bool {
  match coord_position_for_polygon(coord, polygon) {
    Outside => false
    _ => true
  }
}

///|
pub fn covers_polygon_point(
  polygon : @type.Polygon,
  point : @type.Point,
) -> Bool {
  covers_polygon_coord(polygon, point.coord())
}

///|
pub fn covers_polygon_line_string(
  polygon : @type.Polygon,
  ls : @type.LineString,
) -> Bool {
  for c in ls.coords() {
    if !covers_polygon_coord(polygon, c) {
      return false
    }
  }
  true
}

///|
pub fn covers_polygon_polygon(
  outer : @type.Polygon,
  inner : @type.Polygon,
) -> Bool {
  for c in inner.exterior().coords() {
    if !covers_polygon_coord(outer, c) {
      return false
    }
  }
  true
}

///|
pub fn covers_rect_coord(rect : @type.Rect, coord : @type.Coord) -> Bool {
  match coord_position_for_rect(coord, rect) {
    Outside => false
    _ => true
  }
}

///|
/// Generic geometry-based covers.
pub fn covers_geometry(a : @type.Geometry, b : @type.Geometry) -> Bool {
  match (a, b) {
    (@type.Geometry::Polygon(p), @type.Geometry::Point(pt)) =>
      covers_polygon_point(p, pt)
    (@type.Geometry::Polygon(p), @type.Geometry::LineString(ls)) =>
      covers_polygon_line_string(p, ls)
    (@type.Geometry::Polygon(o), @type.Geometry::Polygon(i)) =>
      covers_polygon_polygon(o, i)
    (@type.Geometry::Rect(r), @type.Geometry::Point(pt)) =>
      covers_rect_coord(r, pt.coord())
    (@type.Geometry::MultiPolygon(mp), @type.Geometry::Point(pt)) => {
      for p in mp.polygons() {
        if covers_polygon_point(p, pt) {
          return true
        }
      }
      false
    }
    _ => contains_geometry(a, b)
  }
}
