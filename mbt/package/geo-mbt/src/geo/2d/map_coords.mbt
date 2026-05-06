// Ported from georust/geo
// https://github.com/georust/geo/blob/main/geo/src/algorithm/map_coords.rs

///|
pub fn map_coords_in_point(
  p : @type.Point,
  f : (@type.Coord) -> @type.Coord,
) -> @type.Point {
  @type.Point::from_coord(f(p.coord()))
}

///|
pub fn map_coords_in_line(
  l : @type.Line,
  f : (@type.Coord) -> @type.Coord,
) -> @type.Line {
  @type.Line::Line(f(l.start()), f(l.end()))
}

///|
pub fn map_coords_in_line_string(
  ls : @type.LineString,
  f : (@type.Coord) -> @type.Coord,
) -> @type.LineString {
  @type.LineString::LineString(ls.coords().map(f))
}

///|
pub fn map_coords_in_multi_point(
  mp : @type.MultiPoint,
  f : (@type.Coord) -> @type.Coord,
) -> @type.MultiPoint {
  let pts = mp.points().map(fn(p) { map_coords_in_point(p, f) })
  @type.MultiPoint::MultiPoint(pts)
}

///|
pub fn map_coords_in_multi_line_string(
  mls : @type.MultiLineString,
  f : (@type.Coord) -> @type.Coord,
) -> @type.MultiLineString {
  let lss = mls.line_strings().map(fn(ls) { map_coords_in_line_string(ls, f) })
  @type.MultiLineString::MultiLineString(lss)
}

///|
pub fn map_coords_in_polygon(
  p : @type.Polygon,
  f : (@type.Coord) -> @type.Coord,
) -> @type.Polygon {
  let exterior = map_coords_in_line_string(p.exterior(), f)
  let interiors = p.interiors().map(fn(ls) { map_coords_in_line_string(ls, f) })
  @type.Polygon::Polygon(exterior, interiors)
}

///|
pub fn map_coords_in_multi_polygon(
  mp : @type.MultiPolygon,
  f : (@type.Coord) -> @type.Coord,
) -> @type.MultiPolygon {
  let polys = mp.polygons().map(fn(p) { map_coords_in_polygon(p, f) })
  @type.MultiPolygon::MultiPolygon(polys)
}

///|
pub fn map_coords_in_rect(
  r : @type.Rect,
  f : (@type.Coord) -> @type.Coord,
) -> @type.Rect {
  @type.Rect::Rect(f(r.min()), f(r.max()))
}

///|
pub fn map_coords_in_triangle(
  t : @type.Triangle,
  f : (@type.Coord) -> @type.Coord,
) -> @type.Triangle {
  @type.Triangle::Triangle(f(t.v0()), f(t.v1()), f(t.v2()))
}

///|
pub fn map_coords_in_geometry_collection(
  gc : @type.GeometryCollection,
  f : (@type.Coord) -> @type.Coord,
) -> @type.GeometryCollection {
  let mapped = gc.geometries().map(fn(g) { map_coords_in_geometry(g, f) })
  @type.GeometryCollection::GeometryCollection(mapped)
}

///|
/// Applies the function `f` to every coordinate of the geometry, returning a
/// new geometry with the transformed coordinates. The input is **not**
/// mutated.
pub fn map_coords_in_geometry(
  g : @type.Geometry,
  f : (@type.Coord) -> @type.Coord,
) -> @type.Geometry {
  match g {
    @type.Geometry::Point(p) => @type.Geometry::Point(map_coords_in_point(p, f))
    @type.Geometry::Line(l) => @type.Geometry::Line(map_coords_in_line(l, f))
    @type.Geometry::LineString(ls) =>
      @type.Geometry::LineString(map_coords_in_line_string(ls, f))
    @type.Geometry::Polygon(p) =>
      @type.Geometry::Polygon(map_coords_in_polygon(p, f))
    @type.Geometry::MultiPoint(mp) =>
      @type.Geometry::MultiPoint(map_coords_in_multi_point(mp, f))
    @type.Geometry::MultiLineString(mls) =>
      @type.Geometry::MultiLineString(map_coords_in_multi_line_string(mls, f))
    @type.Geometry::MultiPolygon(mp) =>
      @type.Geometry::MultiPolygon(map_coords_in_multi_polygon(mp, f))
    @type.Geometry::GeometryCollection(gc) =>
      @type.Geometry::GeometryCollection(
        map_coords_in_geometry_collection(gc, f),
      )
    @type.Geometry::Rect(r) => @type.Geometry::Rect(map_coords_in_rect(r, f))
    @type.Geometry::Triangle(t) =>
      @type.Geometry::Triangle(map_coords_in_triangle(t, f))
  }
}
