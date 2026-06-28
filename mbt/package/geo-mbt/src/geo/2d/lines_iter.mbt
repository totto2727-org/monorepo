// Edge / segment iteration trait `LinesCarrier`.
//
// Mirrors upstream Rust `geo::algorithm::lines_iter::LinesIter` (eager form).
// The per-type impls delegate to the methods already defined on each
// concrete `@type.*` value. There is no per-type free function in this
// algorithm-layer file because the construction of the segment array is
// straightforward enough to inline inside each impl body.

///|
/// Anything that produces the line segments composing the geometry.
pub(open) trait LinesCarrier {
  fn lines(Self) -> Array[@type.Line]
}

///|
pub impl LinesCarrier for @type.Line with fn lines(self) {
  [self]
}

///|
pub impl LinesCarrier for @type.LineString with fn lines(self) {
  self.lines()
}

///|
pub impl LinesCarrier for @type.MultiLineString with fn lines(self) {
  self.line_strings().iter().flat_map(fn(ls) { ls.lines().iter() }).collect()
}

///|
pub impl LinesCarrier for @type.Polygon with fn lines(self) {
  self
  .exterior()
  .lines()
  .iter()
  .concat(
    self.interiors().iter().flat_map(fn(interior) { interior.lines().iter() }),
  )
  .collect()
}

///|
pub impl LinesCarrier for @type.MultiPolygon with fn lines(self) {
  self
  .polygons()
  .iter()
  .flat_map(fn(p) { LinesCarrier::lines(p).iter() })
  .collect()
}

///|
pub impl LinesCarrier for @type.Rect with fn lines(self) {
  self.to_lines()
}

///|
pub impl LinesCarrier for @type.Triangle with fn lines(self) {
  self.to_lines()
}

///|
pub impl LinesCarrier for @type.GeometryCollection with fn lines(self) {
  self
  .geometries()
  .iter()
  .flat_map(fn(g) { LinesCarrier::lines(g).iter() })
  .collect()
}

///|
pub impl LinesCarrier for @type.Geometry with fn lines(self) {
  match self {
    @type.Geometry::Point(_) => []
    @type.Geometry::MultiPoint(_) => []
    @type.Geometry::Line(l) => LinesCarrier::lines(l)
    @type.Geometry::LineString(ls) => LinesCarrier::lines(ls)
    @type.Geometry::MultiLineString(mls) => LinesCarrier::lines(mls)
    @type.Geometry::Polygon(p) => LinesCarrier::lines(p)
    @type.Geometry::MultiPolygon(mp) => LinesCarrier::lines(mp)
    @type.Geometry::Rect(r) => LinesCarrier::lines(r)
    @type.Geometry::Triangle(t) => LinesCarrier::lines(t)
    @type.Geometry::GeometryCollection(gc) => LinesCarrier::lines(gc)
  }
}
