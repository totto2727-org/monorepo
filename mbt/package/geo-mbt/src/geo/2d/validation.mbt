// Ported from georust/geo
// https://github.com/georust/geo/blob/main/geo/src/algorithm/validation/

// MARK: index types -----------------------------------------------------------

///|
/// Identifies which ring within a `Polygon` produced a validation problem.
pub(all) enum RingRole {
  Exterior
  Interior(Int) // 0-indexed interior ring number
} derive(Eq, Debug)

///|
/// Identifies which coordinate within a linear geometry produced a validation
/// problem. 0-indexed.
pub(all) struct CoordIndex(Int) derive(Eq, Debug)

///|
/// Identifies which sub-geometry within a `Multi*` or `GeometryCollection`
/// produced a validation problem. 0-indexed.
pub(all) struct GeometryIndex(Int) derive(Eq, Debug)

// MARK: ValidationProblem -----------------------------------------------------

///|
/// A specific validation issue detected on a geometry.
///
/// Variants that report ring-level problems carry a `RingRole` to identify
/// whether the problem occurred on the exterior ring or a specific interior
/// ring. Variants that report coordinate-level problems carry a `CoordIndex`.
/// Multi-geometry variants wrap child problems with a `GeometryIndex`.
///
/// # Checks deferred to later milestones
///
/// The following upstream checks depend on DE-9IM `relate` (ms-20) and/or
/// `PreparedGeometry` caching (ms-18) and are deferred:
/// - `InteriorRingNotContainedInExteriorRing`
/// - `IntersectingRingsOnALine` / `IntersectingRingsOnAnArea`
/// - MultiPolygon `ElementsOverlaps` / `ElementsTouchOnALine`
///
/// Their variant slots are reserved but they are not yet produced.
pub(all) enum ValidationProblem {
  /// A linestring has fewer than 2 distinct coordinates.
  TooFewPoints
  /// A polygon ring is not closed (first != last).
  RingNotClosed(RingRole)
  /// A polygon ring has fewer than 3 unique coords.
  RingTooFewPoints(RingRole)
  /// Self-intersection detected on a ring (excluding endpoint touches).
  SelfIntersection(RingRole)
  /// One or more components contain non-finite (NaN / infinite) coordinates.
  NonFiniteCoord(RingRole, CoordIndex)
  /// A linestring (non-ring) has a non-finite coordinate.
  NonFiniteLineStringCoord(CoordIndex)
  /// A Point has a non-finite coordinate.
  NonFinitePointCoord
  /// A Rect has a non-finite corner coordinate.
  NonFiniteRectCoord(CoordIndex)
  /// A Line has identical start and end coordinates.
  LineIdenticalCoords
  /// A Line has a non-finite start or end coordinate.
  LineNonFiniteCoord(CoordIndex)
  /// A Triangle has a non-finite coordinate.
  TriangleNonFiniteCoord(CoordIndex)
  /// A Triangle has two identical coordinates.
  TriangleIdenticalCoords(CoordIndex, CoordIndex)
  /// A Triangle has collinear coordinates.
  TriangleCollinearCoords
  /// A sub-geometry within a multi-geometry is invalid, identified by index.
  MultiGeometryProblem(GeometryIndex, ValidationProblem)
  /// A polygon's interior ring is not contained within the exterior ring.
  /// **Deferred** — depends on DE-9IM relate (ms-20).
  InteriorRingNotContained(RingRole)
  /// Two polygon rings intersect on a 1-dimensional line.
  /// **Deferred** — depends on DE-9IM relate (ms-20).
  IntersectingRingsOnLine(RingRole, RingRole)
  /// Two polygon rings intersect on a 2-dimensional area.
  /// **Deferred** — depends on DE-9IM relate (ms-20).
  IntersectingRingsOnArea(RingRole, RingRole)
  /// Two polygons in a multi-polygon overlap.
  /// **Deferred** — depends on DE-9IM relate (ms-20).
  ElementsOverlap(GeometryIndex, GeometryIndex)
  /// Two polygons in a multi-polygon touch on a line.
  /// **Deferred** — depends on DE-9IM relate (ms-20).
  ElementsTouchOnLine(GeometryIndex, GeometryIndex)
} derive(Eq, Debug)

// MARK: helpers ---------------------------------------------------------------

///|
fn problem_if(
  flag : Bool,
  problem : ValidationProblem,
) -> Array[ValidationProblem] {
  if flag {
    [problem]
  } else {
    []
  }
}

///|
fn is_finite_xy(c : @type.Coord) -> Bool {
  !c.x().is_inf() && !c.x().is_nan() && !c.y().is_inf() && !c.y().is_nan()
}

///|
fn ring_role_exterior() -> RingRole {
  Exterior
}

///|
fn ring_role_interior(idx : Int) -> RingRole {
  Interior(idx)
}

// MARK: self-intersection detection -------------------------------------------

///|
/// Returns whether `ring` has a self-intersection — i.e. any two non-adjacent
/// segments cross. Adjacent segments sharing an endpoint are NOT considered a
/// self-intersection.
fn ring_has_self_intersection(ring : @type.LineString) -> Bool {
  let lines = ring.lines()
  for i = 0; i < lines.length(); i = i + 1 {
    for j = i + 1; j < lines.length(); j = j + 1 {
      // Adjacent segments share an endpoint — skip (not a self-intersection)
      if j == i + 1 {
        continue
      }
      // Closed ring: first and last segments may share start==end — skip
      if i == 0 && j == lines.length() - 1 {
        continue
      }
      if intersects_line_line(lines[i], lines[j]) {
        return true
      }
    }
  }
  false
}

// MARK: per-ring validation ---------------------------------------------------

///|
fn validate_ring(
  ring : @type.LineString,
  role : RingRole,
) -> Array[ValidationProblem] {
  let coords = ring.coords()
  if coords.length() < 4 {
    return [RingTooFewPoints(role)]
  }
  let problems : Array[ValidationProblem] = []
  if coords[0] != coords[coords.length() - 1] {
    problems.push(RingNotClosed(role))
  }
  if ring_has_self_intersection(ring) {
    problems.push(SelfIntersection(role))
  }
  for idx = 0; idx < coords.length(); idx = idx + 1 {
    if !is_finite_xy(coords[idx]) {
      problems.push(NonFiniteCoord(role, CoordIndex(idx)))
    }
  }
  problems
}

///|
fn validate_line_string(ls : @type.LineString) -> Array[ValidationProblem] {
  let coords = ls.coords()
  let problems : Array[ValidationProblem] = []
  if coords.length() < 2 {
    problems.push(TooFewPoints)
  }
  for idx = 0; idx < coords.length(); idx = idx + 1 {
    if !is_finite_xy(coords[idx]) {
      problems.push(NonFiniteLineStringCoord(CoordIndex(idx)))
    }
  }
  problems
}

// MARK: public API ------------------------------------------------------------

///|
/// Returns the validation problems detected on a geometry. An empty array
/// indicates the geometry is valid.
///
/// Checks performed per geometry type:
/// - **Point**: non-finite coord
/// - **Line**: identical coords, non-finite coords (with index)
/// - **LineString**: too few points, non-finite coords (with index)
/// - **Polygon**: too few points in ring (with RingRole), ring not closed
///   (with RingRole), self-intersection (with RingRole), non-finite coords
///   (with RingRole + CoordIndex)
/// - **Triangle**: non-finite coords (with CoordIndex), identical coords,
///   collinear coords
/// - **Rect**: non-finite corners (with CoordIndex)
/// - **Multi*** / **GeometryCollection**: per-element validation (with
///   GeometryIndex wrapping)
///
/// Deferred checks (require ms-18 / ms-20):
/// - Polygon interior ring containment
/// - Polygon ring-ring intersection on line / area
/// - MultiPolygon element overlap / touch-on-line
pub fn validation_problems(g : @type.Geometry) -> Array[ValidationProblem] {
  match g {
    @type.Geometry::Point(p) =>
      problem_if(!is_finite_xy(p.coord()), NonFinitePointCoord)
    @type.Geometry::Line(l) => {
      let problems : Array[ValidationProblem] = []
      if !is_finite_xy(l.start()) {
        problems.push(LineNonFiniteCoord(CoordIndex(0)))
      }
      if !is_finite_xy(l.end()) {
        problems.push(LineNonFiniteCoord(CoordIndex(1)))
      }
      if l.start() == l.end() {
        problems.push(LineIdenticalCoords)
      }
      problems
    }
    @type.Geometry::LineString(ls) => validate_line_string(ls)
    @type.Geometry::Polygon(p) => {
      let problems = validate_ring(p.exterior(), ring_role_exterior())
      for i = 0; i < p.interiors().length(); i = i + 1 {
        let ip = validate_ring(p.interiors()[i], ring_role_interior(i))
        for k = 0; k < ip.length(); k = k + 1 {
          problems.push(ip[k])
        }
      }
      problems
    }
    @type.Geometry::MultiPoint(mp) => {
      let problems : Array[ValidationProblem] = []
      for i = 0; i < mp.points().length(); i = i + 1 {
        if !is_finite_xy(mp.points()[i].coord()) {
          problems.push(
            MultiGeometryProblem(GeometryIndex(i), NonFinitePointCoord),
          )
        }
      }
      problems
    }
    @type.Geometry::MultiLineString(mls) => {
      let problems : Array[ValidationProblem] = []
      for i = 0; i < mls.line_strings().length(); i = i + 1 {
        let child = validate_line_string(mls.line_strings()[i])
        for k = 0; k < child.length(); k = k + 1 {
          problems.push(MultiGeometryProblem(GeometryIndex(i), child[k]))
        }
      }
      problems
    }
    @type.Geometry::MultiPolygon(mp) => {
      let problems : Array[ValidationProblem] = []
      for i = 0; i < mp.polygons().length(); i = i + 1 {
        let child = validation_problems(
          @type.Geometry::Polygon(mp.polygons()[i]),
        )
        for k = 0; k < child.length(); k = k + 1 {
          problems.push(MultiGeometryProblem(GeometryIndex(i), child[k]))
        }
      }
      problems
    }
    @type.Geometry::Rect(r) => {
      let problems : Array[ValidationProblem] = []
      if !is_finite_xy(r.min()) {
        problems.push(NonFiniteRectCoord(CoordIndex(0)))
      }
      if !is_finite_xy(r.max()) {
        problems.push(NonFiniteRectCoord(CoordIndex(1)))
      }
      problems
    }
    @type.Geometry::Triangle(t) => {
      let problems : Array[ValidationProblem] = []
      if !is_finite_xy(t.v0()) {
        problems.push(TriangleNonFiniteCoord(CoordIndex(0)))
      }
      if !is_finite_xy(t.v1()) {
        problems.push(TriangleNonFiniteCoord(CoordIndex(1)))
      }
      if !is_finite_xy(t.v2()) {
        problems.push(TriangleNonFiniteCoord(CoordIndex(2)))
      }
      if t.v0() == t.v1() {
        problems.push(TriangleIdenticalCoords(CoordIndex(0), CoordIndex(1)))
      }
      if t.v0() == t.v2() {
        problems.push(TriangleIdenticalCoords(CoordIndex(0), CoordIndex(2)))
      }
      if t.v1() == t.v2() {
        problems.push(TriangleIdenticalCoords(CoordIndex(1), CoordIndex(2)))
      }
      // Collinearity check: use robust orient2d
      if @robust.orient2d(
          @type.Coord::Coord(t.v0().x(), t.v0().y()),
          @type.Coord::Coord(t.v1().x(), t.v1().y()),
          @type.Coord::Coord(t.v2().x(), t.v2().y()),
        ) ==
        0.0 {
        problems.push(TriangleCollinearCoords)
      }
      problems
    }
    @type.Geometry::GeometryCollection(gc) => {
      let problems : Array[ValidationProblem] = []
      for i = 0; i < gc.geometries().length(); i = i + 1 {
        let child = validation_problems(gc.geometries()[i])
        for k = 0; k < child.length(); k = k + 1 {
          problems.push(MultiGeometryProblem(GeometryIndex(i), child[k]))
        }
      }
      problems
    }
  }
}

///|
/// Returns whether `g` has no validation problems.
pub fn is_valid(g : @type.Geometry) -> Bool {
  validation_problems(g).length() == 0
}
