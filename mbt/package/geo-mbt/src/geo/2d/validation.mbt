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
  coords.iter().all(is_finite)
}

///|
/// Helper: optional-singleton — returns `[problem]` when `flag` holds, `[]`
/// otherwise. Used to express a per-rule contribution without mutation.
fn problem_if(flag : Bool, problem : ValidationProblem) -> Array[ValidationProblem] {
  if flag {
    [problem]
  } else {
    []
  }
}

///|
fn validate_ring(ring : @type.LineString) -> Array[ValidationProblem] {
  let coords = ring.coords()
  if coords.length() < 4 {
    // A valid ring needs at least 3 unique + 1 closing = 4 coords; once
    // that fails, the other ring checks are not meaningful.
    return [RingTooFewPoints]
  }
  let not_closed = problem_if(
    coords[0] != coords[coords.length() - 1],
    RingNotClosed,
  )
  let non_finite = problem_if(!all_finite(coords), NonFiniteCoord)
  [..not_closed, ..non_finite]
}

///|
fn validate_line_string(
  ls : @type.LineString,
) -> Array[ValidationProblem] {
  let coords = ls.coords()
  let too_few = problem_if(coords.length() < 2, TooFewPoints)
  let non_finite = problem_if(!all_finite(coords), NonFiniteCoord)
  [..too_few, ..non_finite]
}

///|
/// Returns the validation problems detected on a geometry. An empty array
/// indicates the geometry is valid (within the simplified port's checks).
pub fn validation_problems(g : @type.Geometry) -> Array[ValidationProblem] {
  match g {
    @type.Geometry::Point(p) => problem_if(!is_finite(p.coord()), NonFiniteCoord)
    @type.Geometry::Line(l) =>
      problem_if(
        !is_finite(l.start()) || !is_finite(l.end()),
        NonFiniteCoord,
      )
    @type.Geometry::LineString(ls) => validate_line_string(ls)
    @type.Geometry::Polygon(p) => {
      let exterior_problems = validate_ring(p.exterior())
      let interior_problems = p
        .interiors()
        .iter()
        .flat_map(fn(r) { validate_ring(r).iter() })
        .collect()
      [..exterior_problems, ..interior_problems]
    }
    @type.Geometry::MultiPoint(mp) =>
      problem_if(
        !mp.points().iter().all(fn(pt) { is_finite(pt.coord()) }),
        NonFiniteCoord,
      )
    @type.Geometry::MultiLineString(mls) =>
      mls
      .line_strings()
      .iter()
      .flat_map(fn(ls) { validate_line_string(ls).iter() })
      .collect()
    @type.Geometry::MultiPolygon(mp) =>
      mp
      .polygons()
      .iter()
      .flat_map(fn(poly) {
        validation_problems(@type.Geometry::Polygon(poly)).iter()
      })
      .collect()
    @type.Geometry::Rect(r) =>
      problem_if(
        !is_finite(r.min()) || !is_finite(r.max()),
        NonFiniteCoord,
      )
    @type.Geometry::Triangle(t) =>
      problem_if(
        !is_finite(t.v0()) || !is_finite(t.v1()) || !is_finite(t.v2()),
        NonFiniteCoord,
      )
    @type.Geometry::GeometryCollection(gc) =>
      gc
      .geometries()
      .iter()
      .flat_map(fn(g2) { validation_problems(g2).iter() })
      .collect()
  }
}

///|
/// Returns whether `g` has no validation problems.
pub fn is_valid(g : @type.Geometry) -> Bool {
  validation_problems(g).length() == 0
}
