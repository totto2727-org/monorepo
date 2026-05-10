// Rhumb line (loxodrome) distance, bearing, destination, and length.
// Ported from georust/geo
// https://github.com/georust/geo/blob/main/geo/src/algorithm/rhumb/mod.rs

fn to_deg(x : Double) -> Double { x * 180.0 / @math.PI }

///|
/// Pre-calculated shared values for rhumb line operations between two points.
priv struct RhumbCalc {
  phi1 : Double
  delta_lambda : Double
  delta_phi : Double
  delta_psi : Double
}

fn rhumb_calc(origin : @type.Point, destination : @type.Point) -> RhumbCalc {
  let phi1 = to_rad(origin.y())
  let phi2 = to_rad(destination.y())
  let mut delta_lambda = to_rad(destination.x() - origin.x())
  if delta_lambda > @math.PI {
    delta_lambda = delta_lambda - 2.0 * @math.PI
  }
  if delta_lambda < -@math.PI {
    delta_lambda = delta_lambda + 2.0 * @math.PI
  }
  let delta_psi = @math.ln(
    @math.tan(phi2 / 2.0 + @math.PI / 4.0) /
    @math.tan(phi1 / 2.0 + @math.PI / 4.0)
  )
  let delta_phi = phi2 - phi1
  RhumbCalc::{ phi1, delta_lambda, delta_phi, delta_psi }
}

///|
/// A sphere parameterised by its radius for rhumb-line calculations.
pub(all) struct RhumbMeasure {
  radius : Double
} derive(Eq)

///|
/// Standard Earth mean radius for rhumb calculations.
pub fn rhumb() -> RhumbMeasure {
  RhumbMeasure::{ radius: 6_371_008.8 }
}

///|
pub fn RhumbMeasure::new(radius : Double) -> RhumbMeasure {
  RhumbMeasure::{ radius }
}

///|
/// Rhumb-line (loxodrome) distance between two points on a sphere.
///
/// # Units
/// - `origin`, `destination`: Points where x=longitude, y=latitude in degrees
/// - returns: meters
///
/// ```check
/// test "rhumb_distance - NY to London longer than great-circle" {
///   let nyc = @type.Point::from_tuple((-74.006, 40.7128))
///   let london = @type.Point::from_tuple((-0.1278, 51.5074))
///   let d = rhumb().distance(nyc, london)
///   assert_true(d > 5_790_000.0 && d < 5_800_000.0)
/// }
/// ```
pub fn RhumbMeasure::distance(
  self : RhumbMeasure,
  origin : @type.Point,
  destination : @type.Point,
) -> Double {
  let c = rhumb_calc(origin, destination)
  let q = if c.delta_psi.abs() > 10.0e-12 {
    c.delta_phi / c.delta_psi
  } else {
    @math.cos(c.phi1)
  }
  (c.delta_phi * c.delta_phi + q * q * c.delta_lambda * c.delta_lambda)
  .sqrt() * self.radius
}

///|
/// Returns the rhumb-line bearing (constant azimuth) from `origin` to
/// `destination`.
///
/// # Units
/// - `origin`, `destination`: Points where x=longitude, y=latitude
/// - returns: degrees (North=0°, East=90°)
pub fn RhumbMeasure::bearing(
  self : RhumbMeasure,
  origin : @type.Point,
  destination : @type.Point,
) -> Double {
  let c = rhumb_calc(origin, destination)
  let theta = @math.atan2(c.delta_lambda, c.delta_psi)
  (to_deg(theta) + 360.0) % 360.0
}

///|
/// Destination point after travelling `distance` meters from `origin`
/// along a constant `bearing` (rhumb line).
///
/// # Units
/// - `origin`: Point where x=longitude, y=latitude in degrees
/// - `bearing`: degrees (North=0°, East=90°)
/// - `distance`: meters
/// - returns: Point where x=longitude, y=latitude
pub fn RhumbMeasure::destination(
  self : RhumbMeasure,
  origin : @type.Point,
  bearing : Double,
  distance : Double,
) -> @type.Point {
  let delta = distance / self.radius
  let phi1 = to_rad(origin.y())
  let lambda1 = to_rad(origin.x())
  let theta = to_rad(bearing)
  let delta_phi = delta * @math.cos(theta)
  let mut phi2 = phi1 + delta_phi
  // normalise latitude if past the pole
  let half_pi = @math.PI / 2.0
  if phi2.abs() > half_pi {
    phi2 = if phi2 > 0.0 { @math.PI - phi2 } else { -@math.PI - phi2 }
  }
  let delta_psi = @math.ln(
    @math.tan(phi2 / 2.0 + @math.PI / 4.0) /
    @math.tan(phi1 / 2.0 + @math.PI / 4.0)
  )
  let q = if delta_phi.abs() > 10.0e-12 {
    delta_phi / delta_psi
  } else {
    @math.cos(phi1)
  }
  let delta_lambda = delta * @math.sin(theta) / q
  let lambda2 = lambda1 + delta_lambda
  @type.Point::from_tuple(
    ((-180.0).max(180.0.min(to_deg(lambda2))), (-90.0).max(90.0.min(to_deg(phi2)))),
  )
}

///|
/// Rhumb-line (loxodrome) length of a line string. Sums the rhumb distances
/// between consecutive coordinate pairs.
///
/// ```check
/// test "rhumb_length - simple 2-point line" {
///   let ls = @type.LineString::from_tuples([(0.0, 0.0), (1.0, 0.0)])
///   let len = rhumb_length(ls)
///   assert_true(len > 111_000.0)
/// }
/// ```
pub fn rhumb_length(ls : @type.LineString) -> Double {
  let coords = ls.coords()
  if coords.length() < 2 {
    return 0.0
  }
  let m = rhumb()
  let mut total = 0.0
  for i = 0; i < coords.length() - 1; i = i + 1 {
    let p1 = @type.Point::from_coord(coords[i])
    let p2 = @type.Point::from_coord(coords[i + 1])
    total = total + m.distance(p1, p2)
  }
  total
}
