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
/// Anything that has a planar Euclidean length (the physical "how long is
/// this thing in coordinate units"): segment length, line string length,
/// multi line string total length. Distinct from `HasLength`, which is the
/// **collection cardinality** (how many components / coords).
pub(open) trait HasEuclideanLength {
  euclidean_length(Self) -> Double
}

///|
/// Anything that produces the line segments composing the geometry. Mirrors
/// upstream Rust `geo::algorithm::lines_iter::LinesIter` (eager form).
pub(open) trait LinesCarrier {
  lines(Self) -> Array[@type.Line]
}

///|
/// Anything whose dimensionality (Empty / 0D / 1D / 2D) can be computed.
pub(open) trait HasDimensions {
  dimensions(Self) -> Dimensions
}

///|
/// Anything whose convex hull can be taken. The result is always a `Polygon`.
pub(open) trait HasConvexHull {
  convex_hull(Self) -> @type.Polygon
}

///|
/// Computes the closest point on `self` to a target coordinate.
pub(open) trait ClosestPoint {
  closest_point(Self, @type.Coord) -> Closest
}

///|
/// Determines whether a coord is inside / on boundary / outside a geometry.
pub(open) trait CoordPositionFor {
  coord_position(Self, @type.Coord) -> CoordPos
}

///|
/// RDP simplification with `epsilon`. Returns a value of the same type with
/// near-collinear coords removed.
pub(open) trait Simplify {
  simplify(Self, Double) -> Self
}

///|
/// Densification with a maximum segment length. Returns a value of the same
/// type with extra coords inserted along long segments.
pub(open) trait Densify {
  densify(Self, Double) -> Self
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
pub impl HasEuclideanLength for @type.Line with euclidean_length(self) {
  euclidean_length_line(self)
}

///|
pub impl HasEuclideanLength for @type.LineString with euclidean_length(self) {
  euclidean_length_line_string(self)
}

///|
pub impl HasEuclideanLength for @type.MultiLineString with euclidean_length(
  self,
) {
  euclidean_length_multi_line_string(self)
}

///|
pub impl LinesCarrier for @type.Line with lines(self) {
  [self]
}

///|
pub impl LinesCarrier for @type.LineString with lines(self) {
  self.lines()
}

///|
pub impl LinesCarrier for @type.MultiLineString with lines(self) {
  self.line_strings().iter().flat_map(fn(ls) { ls.lines().iter() }).collect()
}

///|
pub impl LinesCarrier for @type.Polygon with lines(self) {
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
pub impl LinesCarrier for @type.MultiPolygon with lines(self) {
  self
  .polygons()
  .iter()
  .flat_map(fn(p) { LinesCarrier::lines(p).iter() })
  .collect()
}

///|
pub impl LinesCarrier for @type.Rect with lines(self) {
  self.to_lines()
}

///|
pub impl LinesCarrier for @type.Triangle with lines(self) {
  self.to_lines()
}

///|
pub impl LinesCarrier for @type.GeometryCollection with lines(self) {
  self
  .geometries()
  .iter()
  .flat_map(fn(g) { LinesCarrier::lines(g).iter() })
  .collect()
}

///|
pub impl LinesCarrier for @type.Geometry with lines(self) {
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

///|
/// A degenerate rectangle of zero width and zero height collapses to
/// `ZeroDimensional`; one of zero width or zero height (but not both) is
/// `OneDimensional`.
pub impl HasDimensions for @type.Rect with dimensions(self) {
  let zero_w = self.width() == 0.0
  let zero_h = self.height() == 0.0
  match (zero_w, zero_h) {
    (true, true) => ZeroDimensional
    (true, false) | (false, true) => OneDimensional
    _ => TwoDimensional
  }
}

///|
/// Empty / single-coord linestrings are `Empty`. A linestring whose coords
/// are all identical is `ZeroDimensional`; otherwise `OneDimensional`.
pub impl HasDimensions for @type.LineString with dimensions(self) {
  let coords = self.coords()
  if coords.length() == 0 {
    return Empty
  }
  let first = coords[0]
  if coords.iter().any(fn(c) { c != first }) {
    OneDimensional
  } else {
    ZeroDimensional
  }
}

///|
/// `Polygon` is `TwoDimensional` unless its exterior is empty (`Empty`) or
/// all of its exterior coordinates collapse to a single coordinate
/// (`ZeroDimensional`).
pub impl HasDimensions for @type.Geometry with dimensions(self) {
  match self {
    @type.Geometry::Point(_) => ZeroDimensional
    @type.Geometry::Line(l) =>
      if l.start() == l.end() {
        ZeroDimensional
      } else {
        OneDimensional
      }
    @type.Geometry::LineString(ls) => HasDimensions::dimensions(ls)
    @type.Geometry::Polygon(p) =>
      match HasDimensions::dimensions(p.exterior()) {
        Empty => Empty
        ZeroDimensional => ZeroDimensional
        _ => TwoDimensional
      }
    @type.Geometry::MultiPoint(mp) =>
      if mp.is_empty() {
        Empty
      } else {
        ZeroDimensional
      }
    @type.Geometry::MultiLineString(mls) =>
      mls
      .line_strings()
      .iter()
      .map(HasDimensions::dimensions)
      .fold(init=Dimensions::Empty, max_dimension)
    @type.Geometry::MultiPolygon(mp) =>
      mp
      .polygons()
      .iter()
      .map(fn(p) { HasDimensions::dimensions(@type.Geometry::Polygon(p)) })
      .fold(init=Dimensions::Empty, max_dimension)
    @type.Geometry::Rect(r) => HasDimensions::dimensions(r)
    @type.Geometry::Triangle(_) => TwoDimensional
    @type.Geometry::GeometryCollection(gc) =>
      gc
      .geometries()
      .iter()
      .map(HasDimensions::dimensions)
      .fold(init=Dimensions::Empty, max_dimension)
  }
}

///|
pub impl HasConvexHull for @type.MultiPoint with convex_hull(self) {
  convex_hull_of_multi_point(self)
}

///|
pub impl HasConvexHull for @type.LineString with convex_hull(self) {
  convex_hull_of_line_string(self)
}

///|
pub impl HasConvexHull for @type.Polygon with convex_hull(self) {
  convex_hull_of_polygon(self)
}

///|
pub impl HasConvexHull for @type.Geometry with convex_hull(self) {
  convex_hull_of_geometry(self)
}

///|
pub impl ClosestPoint for @type.Line with closest_point(self, target) {
  let v = self.delta()
  let w = target - self.start()
  let v_dot_v = v.dot(v)
  if v_dot_v == 0.0 {
    return if self.start() == target {
      Intersection(self.start())
    } else {
      SinglePoint(self.start())
    }
  }
  let t = w.dot(v) / v_dot_v
  let clamped = if t < 0.0 { 0.0 } else if t > 1.0 { 1.0 } else { t }
  let proj = self.start() + v.mul(clamped)
  if proj == target {
    Intersection(proj)
  } else {
    SinglePoint(proj)
  }
}

///|
pub impl ClosestPoint for @type.LineString with closest_point(self, target) {
  let segments = self.lines()
  if segments.length() == 0 {
    return Indeterminate
  }
  // Fold tracks the best candidate so far. Once an `Intersection` is seen
  // the result is locked in and remains stable across the rest of the fold.
  segments
  .iter()
  .fold(init=Closest::Indeterminate, fn(acc, seg) {
    match acc {
      Intersection(_) => acc
      _ =>
        match ClosestPoint::closest_point(seg, target) {
          Intersection(c) => Intersection(c)
          SinglePoint(c) =>
            match acc {
              SinglePoint(prev) => {
                let d_new = euclidean_distance_squared_coords(c, target)
                let d_prev = euclidean_distance_squared_coords(prev, target)
                if d_new < d_prev {
                  SinglePoint(c)
                } else {
                  acc
                }
              }
              _ => SinglePoint(c)
            }
          Indeterminate => acc
        }
    }
  })
}

///|
pub impl CoordPositionFor for @type.Line with coord_position(self, coord) {
  coord_position_for_line(coord, self)
}

///|
pub impl CoordPositionFor for @type.LineString with coord_position(self, coord) {
  coord_position_for_line_string(coord, self)
}

///|
pub impl CoordPositionFor for @type.Polygon with coord_position(self, coord) {
  coord_position_for_polygon(coord, self)
}

///|
pub impl CoordPositionFor for @type.MultiPolygon with coord_position(
  self,
  coord,
) {
  coord_position_for_multi_polygon(coord, self)
}

///|
pub impl CoordPositionFor for @type.Rect with coord_position(self, coord) {
  coord_position_for_rect(coord, self)
}

///|
pub impl CoordPositionFor for @type.Triangle with coord_position(self, coord) {
  coord_position_for_triangle(coord, self)
}

///|
pub impl CoordPositionFor for @type.Geometry with coord_position(self, coord) {
  coord_position_for_geometry(coord, self)
}

///|
pub impl Simplify for @type.LineString with simplify(self, epsilon) {
  simplify_line_string(self, epsilon)
}

///|
pub impl Simplify for @type.Polygon with simplify(self, epsilon) {
  simplify_polygon(self, epsilon)
}

///|
pub impl Densify for @type.LineString with densify(self, max_segment_length) {
  densify_line_string(self, max_segment_length)
}

///|
pub impl Densify for @type.Polygon with densify(self, max_segment_length) {
  densify_polygon(self, max_segment_length)
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
