// Ported from georust/geo-types
// https://github.com/georust/geo/blob/main/geo-types/src/geometry/mod.rs (the
// `Geometry` enum) and adapted to MoonBit's enum syntax.

///|
/// An enumeration of all geometry types except `Coord` (which is not itself a
/// "geometry" in the OGC sense).
pub(all) enum Geometry {
  Point(Point)
  Line(Line)
  LineString(LineString)
  Polygon(Polygon)
  MultiPoint(MultiPoint)
  MultiLineString(MultiLineString)
  MultiPolygon(MultiPolygon)
  GeometryCollection(GeometryCollection)
  Rect(Rect)
  Triangle(Triangle)
} derive(Eq, Debug)
