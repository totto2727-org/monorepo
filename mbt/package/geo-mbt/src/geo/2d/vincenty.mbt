// Ellipsoidal distance using Vincenty's formulae.
// Ported from georust/geo
// https://github.com/georust/geo/blob/main/geo/src/algorithm/vincenty_distance.rs
//
// References:
//   http://www.movable-type.co.uk/scripts/latlong-vincenty.html
//   https://en.wikipedia.org/wiki/Vincenty%27s_formulae

///|
let equatorial_earth_radius : Double = 6_378_137.0

///|
let polar_earth_radius : Double = 6_356_752.314_245

///|
let earth_flattening : Double = (equatorial_earth_radius - polar_earth_radius) /
  equatorial_earth_radius

///|
fn to_rad(x : Double) -> Double {
  x * @math.PI / 180.0
}

///|
/// Returns the distance in meters between two points on the WGS84 ellipsoid
/// using Vincenty's iterative formula. Returns `None` if the algorithm fails
/// to converge (typically for nearly antipodal points).
///
/// # Units
/// - `a`, `b`: Points where x=longitude, y=latitude in degrees
/// - returns: `Some(distance_meters)` or `None`
///
/// ```check
/// test "vincenty_distance - coincident points" {
///   let p = @type.Point::from_tuple((12.3, 4.56))
///   match vincenty_distance(p, p) {
///     Some(d) => assert_true(d.abs() < 1.0e-3)
///     None => assert_true(false)
///   }
/// }
/// ```
pub fn vincenty_distance(a : @type.Point, b : @type.Point) -> Double? {
  let a_radius = equatorial_earth_radius
  let b_radius = polar_earth_radius
  let f = earth_flattening
  let l = to_rad(b.x() - a.x())
  let u1 = @math.atan((1.0 - f) * @math.tan(to_rad(a.y())))
  let u2 = @math.atan((1.0 - f) * @math.tan(to_rad(b.y())))
  let (sin_u1, cos_u1) = (@math.sin(u1), @math.cos(u1))
  let (sin_u2, cos_u2) = (@math.sin(u2), @math.cos(u2))
  let mut lambda = l
  let mut iter_limit = 100
  let mut cos_sq_alpha = 0.0
  let mut sin_sigma = 0.0
  let mut cos2_sigma_m = 0.0
  let mut cos_sigma = 0.0
  let mut sigma = 0.0

  while iter_limit > 0 {
    let (sin_lambda, cos_lambda) = (@math.sin(lambda), @math.cos(lambda))
    sin_sigma = (cos_u2 * sin_lambda * (cos_u2 * sin_lambda) +
    (cos_u1 * sin_u2 - sin_u1 * cos_u2 * cos_lambda) *
    (cos_u1 * sin_u2 - sin_u1 * cos_u2 * cos_lambda)).sqrt()

    if sin_sigma == 0.0 {
      return if a == b { Some(0.0) } else { None }
    }

    cos_sigma = sin_u1 * sin_u2 + cos_u1 * cos_u2 * cos_lambda
    sigma = @math.atan2(sin_sigma, cos_sigma)
    let sin_alpha = cos_u1 * cos_u2 * sin_lambda / sin_sigma
    cos_sq_alpha = 1.0 - sin_alpha * sin_alpha

    cos2_sigma_m = if cos_sq_alpha == 0.0 {
      0.0
    } else {
      cos_sigma - 2.0 * sin_u1 * sin_u2 / cos_sq_alpha
    }

    let c = f / 16.0 * cos_sq_alpha * (4.0 + f * (4.0 - 3.0 * cos_sq_alpha))
    let lambda_p = lambda
    lambda = l +
      (1.0 - c) *
      f *
      sin_alpha *
      (
        sigma +
        c *
        sin_sigma *
        (
          cos2_sigma_m +
          c * cos_sigma * (-1.0 + 2.0 * cos2_sigma_m * cos2_sigma_m)
        )
      )

    if (lambda - lambda_p).abs() <= 1.0e-12 {
      break
    }
    iter_limit = iter_limit - 1
  }

  if iter_limit == 0 {
    return None
  }

  let u_sq = cos_sq_alpha *
    (a_radius * a_radius - b_radius * b_radius) /
    (b_radius * b_radius)
  let aa = 1.0 +
    u_sq / 16384.0 * (4096.0 + u_sq * (-768.0 + u_sq * (320.0 - 175.0 * u_sq)))
  let bb = u_sq /
    1024.0 *
    (256.0 + u_sq * (-128.0 + u_sq * (74.0 - 47.0 * u_sq)))

  let delta_sigma = bb *
    sin_sigma *
    (
      cos2_sigma_m +
      bb /
      4.0 *
      (
        cos_sigma * (-1.0 + 2.0 * cos2_sigma_m * cos2_sigma_m) -
        bb /
        6.0 *
        cos2_sigma_m *
        (-3.0 + 4.0 * sin_sigma * sin_sigma) *
        (-3.0 + 4.0 * cos2_sigma_m * cos2_sigma_m)
      )
    )

  Some(b_radius * aa * (sigma - delta_sigma))
}

///|
/// Vincenty (ellipsoidal) length of a line string. Sums the vincenty
/// distances between consecutive coordinate pairs. Returns `None` if any
/// segment fails to converge.
///
/// ```check
/// test "vincenty_length - short segment" {
///   let ls = @type.LineString::from_tuples([(17.072561, 48.154563), (17.064064, 48.158800)])
///   match vincenty_length(ls) {
///     Some(d) => assert_true((d - 788.4148295236967).abs() < 0.01)
///     None => assert_true(false)
///   }
/// }
/// ```
pub fn vincenty_length(ls : @type.LineString) -> Double? {
  let coords = ls.coords()
  if coords.length() < 2 {
    return Some(0.0)
  }
  let mut total = 0.0
  for i = 0; i < coords.length() - 1; i = i + 1 {
    let p1 = @type.Point::from_coord(coords[i])
    let p2 = @type.Point::from_coord(coords[i + 1])
    match vincenty_distance(p1, p2) {
      Some(d) => total = total + d
      None => return None
    }
  }
  Some(total)
}
