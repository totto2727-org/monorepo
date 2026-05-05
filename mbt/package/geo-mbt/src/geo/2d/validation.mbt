// Ported from georust/geo
// https://github.com/georust/geo/blob/main/geo/src/algorithm/validation/

///|
/// A specific validation issue detected on a geometry.
pub(all) enum ValidationProblem {
  /// A linestring has fewer than 2 distinct coordinates.
  TooFewPoints
  /// A polygon ring is not closed (first != last).
  RingNotClosed
  /// A polygon ring has fewer than 3 unique coords.
  RingTooFewPoints
  /// Self-intersection detected (excluding endpoint touches).
  SelfIntersection
  /// One or more components contain non-finite (NaN / infinite) coordinates.
  NonFiniteCoord
} derive(Eq, Debug)

///|
/// Returns whether all coords in the geometry are finite (no NaN / Inf).
fn all_finite(coords : Array[@type.Coord]) -> Bool {
  for c in coords {
    if !is_finite(c) {
      return false
    }
  }
  true
}

///|
fn validate_ring(ring : @type.LineString) -> Array[ValidationProblem] {
  let problems : Array[ValidationProblem] = []
  let coords = ring.coords()
  if coords.length() < 4 {
    // A valid ring needs at least 3 unique + 1 closing = 4 coords
    problems.push(RingTooFewPoints)
    return problems
  }
  if coords[0] != coords[coords.length() - 1] {
    problems.push(RingNotClosed)
  }
  if !all_finite(coords) {
    problems.push(NonFiniteCoord)
  }
  problems
}

///|
fn validate_line_string(ls : @type.LineString) -> Array[ValidationProblem] {
  let problems : Array[ValidationProblem] = []
  if ls.coords().length() < 2 {
    problems.push(TooFewPoints)
  }
  if !all_finite(ls.coords()) {
    problems.push(NonFiniteCoord)
  }
  problems
}

///|
/// Returns the validation problems detected on a geometry. An empty array
/// indicates the geometry is valid (within the simplified port's checks).
pub fn validation_problems(g : @type.Geometry) -> Array[ValidationProblem] {
  let problems : Array[ValidationProblem] = []
  match g {
    @type.Geometry::Point(p) =>
      if !is_finite(p.coord()) {
        problems.push(NonFiniteCoord)
      }
    @type.Geometry::Line(l) =>
      if !is_finite(l.start()) || !is_finite(l.end()) {
        problems.push(NonFiniteCoord)
      }
    @type.Geometry::LineString(ls) =>
      for problem in validate_line_string(ls) {
        problems.push(problem)
      }
    @type.Geometry::Polygon(p) => {
      for problem in validate_ring(p.exterior()) {
        problems.push(problem)
      }
      for interior in p.interiors() {
        for problem in validate_ring(interior) {
          problems.push(problem)
        }
      }
    }
    @type.Geometry::MultiPoint(mp) =>
      for pt in mp.points() {
        if !is_finite(pt.coord()) {
          problems.push(NonFiniteCoord)
          break
        }
      }
    @type.Geometry::MultiLineString(mls) =>
      for ls in mls.line_strings() {
        for problem in validate_line_string(ls) {
          problems.push(problem)
        }
      }
    @type.Geometry::MultiPolygon(mp) =>
      for poly in mp.polygons() {
        for problem in validation_problems(@type.Geometry::Polygon(poly)) {
          problems.push(problem)
        }
      }
    @type.Geometry::Rect(r) =>
      if !is_finite(r.min()) || !is_finite(r.max()) {
        problems.push(NonFiniteCoord)
      }
    @type.Geometry::Triangle(t) =>
      if !is_finite(t.v0()) || !is_finite(t.v1()) || !is_finite(t.v2()) {
        problems.push(NonFiniteCoord)
      }
    @type.Geometry::GeometryCollection(gc) =>
      for g2 in gc.geometries() {
        for problem in validation_problems(g2) {
          problems.push(problem)
        }
      }
  }
  problems
}

///|
/// Returns whether `g` has no validation problems.
pub fn is_valid(g : @type.Geometry) -> Bool {
  validation_problems(g).length() == 0
}
