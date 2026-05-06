// Constraint-only traits for the 2D geometry layer.
//
// These traits aggregate the existing per-type functions into reusable
// behavioural contracts. They are deliberately **constraint-only**:
//
// - No generics over numeric types (the `Coord` is always (Double, Double)).
// - No 3D variants — this is a 2D-only library by design.
// - No default method bodies that would force a particular implementation
//   strategy on later additions.
//
// Use cases:
//   1. Algorithms that want to accept any geometry-shaped value can take a
//      `&Bounded` or `&CoordsCarrier` parameter instead of the explicit
//      `Geometry` enum.
//   2. Future user-defined types (e.g. a custom indexed Polygon variant)
//      can implement these traits to plug into the existing algorithm
//      surface.
//
// **Note**: Each trait already has a corresponding implementation for the
// concrete `@type.*` types via the per-type helpers in this package. The
// trait `impl` blocks below wire those up.

///|
/// Anything that produces a sequence of `Coord`s (lossless representation
/// of all the geometry's coordinates, including interior rings).
pub(open) trait CoordsCarrier {
  coords(Self) -> Array[@type.Coord]
}

///|
/// Anything that has a bounding rectangle. Geometries which can be empty
/// return `None`.
pub(open) trait Bounded {
  bbox(Self) -> @type.Rect?
}

///|
/// Anything that has a planar area (including signed area for orientation).
pub(open) trait HasArea {
  signed_area(Self) -> Double
  unsigned_area(Self) -> Double
}

///|
/// Anything that has a centroid (geometric centre of mass).
pub(open) trait HasCentroid {
  centroid(Self) -> @type.Point?
}

///|
/// Anything that has a Euclidean length (segments, line strings, etc.).
pub(open) trait HasLength {
  euclidean_length(Self) -> Double
}

///|
/// Anything whose coordinates can be transformed pointwise by a function
/// `Coord -> Coord`, returning a value of the same type. Mirrors upstream
/// Rust `geo::algorithm::map_coords::MapCoords`.
pub(open) trait MapCoords {
  map_coords(Self, (@type.Coord) -> @type.Coord) -> Self
}

// MARK: trait implementations for concrete @type.* values --------------------

///|
pub impl CoordsCarrier for @type.Point with coords(self) {
  coords_of_point(self)
}

///|
pub impl CoordsCarrier for @type.MultiPoint with coords(self) {
  coords_of_multi_point(self)
}

///|
pub impl CoordsCarrier for @type.Line with coords(self) {
  coords_of_line(self)
}

///|
pub impl CoordsCarrier for @type.LineString with coords(self) {
  coords_of_line_string(self)
}

///|
pub impl CoordsCarrier for @type.MultiLineString with coords(self) {
  coords_of_multi_line_string(self)
}

///|
pub impl CoordsCarrier for @type.Polygon with coords(self) {
  coords_of_polygon(self)
}

///|
pub impl CoordsCarrier for @type.MultiPolygon with coords(self) {
  coords_of_multi_polygon(self)
}

///|
pub impl CoordsCarrier for @type.Rect with coords(self) {
  coords_of_rect(self)
}

///|
pub impl CoordsCarrier for @type.Triangle with coords(self) {
  coords_of_triangle(self)
}

///|
pub impl CoordsCarrier for @type.GeometryCollection with coords(self) {
  coords_of_geometry_collection(self)
}

///|
pub impl CoordsCarrier for @type.Geometry with coords(self) {
  coords_of_geometry(self)
}

///|
pub impl Bounded for @type.Point with bbox(self) {
  Some(bounding_rect_of_point(self))
}

///|
pub impl Bounded for @type.Line with bbox(self) {
  Some(bounding_rect_of_line(self))
}

///|
pub impl Bounded for @type.LineString with bbox(self) {
  bounding_rect_of_line_string(self)
}

///|
pub impl Bounded for @type.MultiPoint with bbox(self) {
  bounding_rect_of_multi_point(self)
}

///|
pub impl Bounded for @type.MultiLineString with bbox(self) {
  bounding_rect_of_multi_line_string(self)
}

///|
pub impl Bounded for @type.Polygon with bbox(self) {
  bounding_rect_of_polygon(self)
}

///|
pub impl Bounded for @type.MultiPolygon with bbox(self) {
  bounding_rect_of_multi_polygon(self)
}

///|
pub impl Bounded for @type.Rect with bbox(self) {
  Some(self)
}

///|
pub impl Bounded for @type.Triangle with bbox(self) {
  Some(bounding_rect_of_triangle(self))
}

///|
pub impl Bounded for @type.GeometryCollection with bbox(self) {
  bounding_rect_of_geometry_collection(self)
}

///|
pub impl Bounded for @type.Geometry with bbox(self) {
  bounding_rect_of_geometry(self)
}

///|
pub impl HasArea for @type.Polygon with signed_area(self) {
  signed_area_of_polygon(self)
}

///|
pub impl HasArea for @type.Polygon with unsigned_area(self) {
  unsigned_area_of_polygon(self)
}

///|
pub impl HasArea for @type.MultiPolygon with signed_area(self) {
  signed_area_of_multi_polygon(self)
}

///|
pub impl HasArea for @type.MultiPolygon with unsigned_area(self) {
  unsigned_area_of_multi_polygon(self)
}

///|
pub impl HasArea for @type.Rect with signed_area(self) {
  signed_area_of_rect(self)
}

///|
pub impl HasArea for @type.Rect with unsigned_area(self) {
  unsigned_area_of_rect(self)
}

///|
pub impl HasArea for @type.Triangle with signed_area(self) {
  signed_area_of_triangle(self)
}

///|
pub impl HasArea for @type.Triangle with unsigned_area(self) {
  unsigned_area_of_triangle(self)
}

///|
pub impl HasArea for @type.Geometry with signed_area(self) {
  signed_area_of_geometry(self)
}

///|
pub impl HasArea for @type.Geometry with unsigned_area(self) {
  unsigned_area_of_geometry(self)
}

///|
pub impl HasCentroid for @type.Polygon with centroid(self) {
  centroid_polygon(self)
}

///|
pub impl HasCentroid for @type.MultiPolygon with centroid(self) {
  centroid_multi_polygon(self)
}

///|
pub impl HasCentroid for @type.LineString with centroid(self) {
  centroid_line_string(self)
}

///|
pub impl HasCentroid for @type.Geometry with centroid(self) {
  centroid_geometry(self)
}

///|
pub impl HasLength for @type.Line with euclidean_length(self) {
  euclidean_length_line(self)
}

///|
pub impl HasLength for @type.LineString with euclidean_length(self) {
  euclidean_length_line_string(self)
}

///|
pub impl HasLength for @type.MultiLineString with euclidean_length(self) {
  euclidean_length_multi_line_string(self)
}

///|
pub impl MapCoords for @type.Point with map_coords(self, f) {
  @type.Point::from_coord(f(self.coord()))
}

///|
pub impl MapCoords for @type.Line with map_coords(self, f) {
  @type.Line::Line(f(self.start()), f(self.end()))
}

///|
pub impl MapCoords for @type.LineString with map_coords(self, f) {
  @type.LineString::LineString(self.coords().map(f))
}

///|
pub impl MapCoords for @type.MultiPoint with map_coords(self, f) {
  @type.MultiPoint::MultiPoint(
    self.points().map(fn(p) { MapCoords::map_coords(p, f) }),
  )
}

///|
pub impl MapCoords for @type.MultiLineString with map_coords(self, f) {
  @type.MultiLineString::MultiLineString(
    self.line_strings().map(fn(ls) { MapCoords::map_coords(ls, f) }),
  )
}

///|
pub impl MapCoords for @type.Polygon with map_coords(self, f) {
  @type.Polygon::Polygon(
    MapCoords::map_coords(self.exterior(), f),
    self.interiors().map(fn(ls) { MapCoords::map_coords(ls, f) }),
  )
}

///|
pub impl MapCoords for @type.MultiPolygon with map_coords(self, f) {
  @type.MultiPolygon::MultiPolygon(
    self.polygons().map(fn(p) { MapCoords::map_coords(p, f) }),
  )
}

///|
pub impl MapCoords for @type.Rect with map_coords(self, f) {
  @type.Rect::Rect(f(self.min()), f(self.max()))
}

///|
pub impl MapCoords for @type.Triangle with map_coords(self, f) {
  @type.Triangle::Triangle(f(self.v0()), f(self.v1()), f(self.v2()))
}

///|
pub impl MapCoords for @type.GeometryCollection with map_coords(self, f) {
  @type.GeometryCollection::GeometryCollection(
    self.geometries().map(fn(g) { MapCoords::map_coords(g, f) }),
  )
}

///|
pub impl MapCoords for @type.Geometry with map_coords(self, f) {
  match self {
    @type.Geometry::Point(p) =>
      @type.Geometry::Point(MapCoords::map_coords(p, f))
    @type.Geometry::Line(l) =>
      @type.Geometry::Line(MapCoords::map_coords(l, f))
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
    @type.Geometry::Rect(r) =>
      @type.Geometry::Rect(MapCoords::map_coords(r, f))
    @type.Geometry::Triangle(t) =>
      @type.Geometry::Triangle(MapCoords::map_coords(t, f))
  }
}
