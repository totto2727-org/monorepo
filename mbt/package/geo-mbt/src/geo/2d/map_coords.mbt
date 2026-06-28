// Per-coord transformation trait `MapCoords`.
//
// Mirrors upstream Rust `geo::algorithm::map_coords::MapCoords`. The trait
// takes a function `Coord -> Coord` and rebuilds a value of the same shape
// with every coordinate mapped through it. The structural skeleton (which
// polygons have which holes, which line strings live in which collection)
// is preserved exactly; only the coord values change.
//
// As with `LinesCarrier`, there is no per-type free helper here — the
// rebuild logic for each concrete type is short enough to inline inside
// the impl body.

///|
/// Anything whose coordinates can be transformed pointwise by a function
/// `Coord -> Coord`, returning a value of the same type.
pub(open) trait MapCoords {
  fn map_coords(Self, (@type.Coord) -> @type.Coord) -> Self
}

///|
pub impl MapCoords for @type.Point with fn map_coords(self, f) {
  @type.Point::from_coord(f(self.coord()))
}

///|
pub impl MapCoords for @type.Line with fn map_coords(self, f) {
  @type.Line::Line(f(self.start()), f(self.end()))
}

///|
pub impl MapCoords for @type.LineString with fn map_coords(self, f) {
  @type.LineString::LineString(self.coords().map(f))
}

///|
pub impl MapCoords for @type.MultiPoint with fn map_coords(self, f) {
  @type.MultiPoint::MultiPoint(
    self.points().map(fn(p) { MapCoords::map_coords(p, f) }),
  )
}

///|
pub impl MapCoords for @type.MultiLineString with fn map_coords(self, f) {
  @type.MultiLineString::MultiLineString(
    self.line_strings().map(fn(ls) { MapCoords::map_coords(ls, f) }),
  )
}

///|
pub impl MapCoords for @type.Polygon with fn map_coords(self, f) {
  @type.Polygon::Polygon(
    MapCoords::map_coords(self.exterior(), f),
    self.interiors().map(fn(ls) { MapCoords::map_coords(ls, f) }),
  )
}

///|
pub impl MapCoords for @type.MultiPolygon with fn map_coords(self, f) {
  @type.MultiPolygon::MultiPolygon(
    self.polygons().map(fn(p) { MapCoords::map_coords(p, f) }),
  )
}

///|
pub impl MapCoords for @type.Rect with fn map_coords(self, f) {
  @type.Rect::Rect(f(self.min()), f(self.max()))
}

///|
pub impl MapCoords for @type.Triangle with fn map_coords(self, f) {
  @type.Triangle::Triangle(f(self.v0()), f(self.v1()), f(self.v2()))
}

///|
pub impl MapCoords for @type.GeometryCollection with fn map_coords(self, f) {
  @type.GeometryCollection::GeometryCollection(
    self.geometries().map(fn(g) { MapCoords::map_coords(g, f) }),
  )
}

///|
pub impl MapCoords for @type.Geometry with fn map_coords(self, f) {
  match self {
    @type.Geometry::Point(p) =>
      @type.Geometry::Point(MapCoords::map_coords(p, f))
    @type.Geometry::Line(l) => @type.Geometry::Line(MapCoords::map_coords(l, f))
    @type.Geometry::LineString(ls) =>
      @type.Geometry::LineString(MapCoords::map_coords(ls, f))
    @type.Geometry::Polygon(p) =>
      @type.Geometry::Polygon(MapCoords::map_coords(p, f))
    @type.Geometry::MultiPoint(mp) =>
      @type.Geometry::MultiPoint(MapCoords::map_coords(mp, f))
    @type.Geometry::MultiLineString(mls) =>
      @type.Geometry::MultiLineString(MapCoords::map_coords(mls, f))
    @type.Geometry::MultiPolygon(mp) =>
      @type.Geometry::MultiPolygon(MapCoords::map_coords(mp, f))
    @type.Geometry::GeometryCollection(gc) =>
      @type.Geometry::GeometryCollection(MapCoords::map_coords(gc, f))
    @type.Geometry::Rect(r) => @type.Geometry::Rect(MapCoords::map_coords(r, f))
    @type.Geometry::Triangle(t) =>
      @type.Geometry::Triangle(MapCoords::map_coords(t, f))
  }
}
