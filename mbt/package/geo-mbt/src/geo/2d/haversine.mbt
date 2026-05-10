// Geographic (spherical) distance, bearing, destination, and length using
// the Haversine formula. Ported from georust/geo
// https://github.com/georust/geo/blob/main/geo/src/algorithm/line_measures/metric_spaces/haversine.rs

///|
/// A sphere parameterised by its radius (typically in meters). The standard
/// Earth radius is `grs80_mean_radius` (6371008.8 m, IUGG recommendation).
pub(all) struct HaversineMeasure {
  radius : Double
} derive(Eq)

///|
/// Standard Earth mean radius (GRS80 R₁ = 6,371,008.8 m).
pub fn haversine() -> HaversineMeasure {
  HaversineMeasure::{ radius: 6_371_008.8 }
}

///|
pub fn HaversineMeasure::new(radius : Double) -> HaversineMeasure {
  HaversineMeasure::{ radius }
}

///|
pub fn HaversineMeasure::radius(self : HaversineMeasure) -> Double {
  self.radius
}

///|
/// The haversine distance between two points on a sphere.
///
/// # Units
/// - `origin`, `destination`: Points where x=longitude, y=latitude in degrees
/// - returns: meters (same unit as the sphere radius)
///
/// ```check
/// test "haversine_distance - New York to London" {
///   let nyc = @type.Point::from_tuple((-74.006, 40.7128))
///   let london = @type.Point::from_tuple((-0.1278, 51.5074))
///   let m = haversine()
///   let d = m.distance(nyc, london)
///   assert_true((d - 5_570_230.0).abs() < 10.0)
/// }
/// ```
pub fn HaversineMeasure::distance(
  self : HaversineMeasure,
  origin : @type.Point,
  destination : @type.Point,
) -> Double {
  let to_rad = fn(x) { x * @math.PI / 180.0 }
  let theta1 = to_rad(origin.y())
  let theta2 = to_rad(destination.y())
  let delta_theta = to_rad(destination.y() - origin.y())
  let delta_lambda = to_rad(destination.x() - origin.x())
  let a =
    @math.sin(delta_theta / 2.0) * @math.sin(delta_theta / 2.0) +
    @math.cos(theta1) * @math.cos(theta2) *
    @math.sin(delta_lambda / 2.0) * @math.sin(delta_lambda / 2.0)
  let c = 2.0 * @math.asin(a.sqrt())
  self.radius * c
}

///|
/// Great-circle bearing from `origin` to `destination`.
///
/// # Units
/// - `origin`, `destination`: Points where x=longitude, y=latitude in degrees
/// - returns: degrees (North=0°, East=90°, South=180°, West=270°)
///
/// ```check
/// test "haversine_bearing - east is 90" {
///   let origin = @type.Point::from_tuple((0.0, 0.0))
///   let dest = @type.Point::from_tuple((1.0, 0.0))
///   let m = haversine()
///   let b = m.bearing(origin, dest)
///   assert_true((b - 90.0).abs() < 1.0e-6)
/// }
/// ```
pub fn HaversineMeasure::bearing(
  self : HaversineMeasure,
  origin : @type.Point,
  destination : @type.Point,
) -> Double {
  let to_rad = fn(x) { x * @math.PI / 180.0 }
  let lng_a = to_rad(origin.x())
  let lat_a = to_rad(origin.y())
  let lng_b = to_rad(destination.x())
  let lat_b = to_rad(destination.y())
  let delta_lng = lng_b - lng_a
  let s = @math.cos(lat_b) * @math.sin(delta_lng)
  let c = @math.cos(lat_a) * @math.sin(lat_b) -
    @math.sin(lat_a) * @math.cos(lat_b) * @math.cos(delta_lng)
  let degrees = @math.atan2(s, c) * 180.0 / @math.PI
  (degrees + 360.0) % 360.0
}

///|
/// Destination point after travelling `distance` meters from `origin`
/// along `bearing` degrees (North=0°, East=90°).
///
/// # Units
/// - `origin`: Point where x=longitude, y=latitude in degrees
/// - `bearing`: degrees
/// - `distance`: meters
/// - returns: Point where x=longitude, y=latitude in degrees
///
/// ```check
/// test "haversine_destination - north 100km from equator" {
///   let origin = @type.Point::from_tuple((0.0, 0.0))
///   let m = haversine()
///   let dest = m.destination(origin, 0.0, 100_000.0)
///   assert_true((dest.y() - 0.899320363724538).abs() < 1.0e-10)
/// }
/// ```
pub fn HaversineMeasure::destination(
  self : HaversineMeasure,
  origin : @type.Point,
  bearing : Double,
  distance : Double,
) -> @type.Point {
  let to_rad = fn(x) { x * @math.PI / 180.0 }
  let center_lng = to_rad(origin.x())
  let center_lat = to_rad(origin.y())
  let bearing_rad = to_rad(bearing)
  let rad = distance / self.radius
  let lat = @math.asin(
    @math.sin(center_lat) * @math.cos(rad) +
    @math.cos(center_lat) * @math.sin(rad) * @math.cos(bearing_rad)
  )
  let lng = center_lng +
    @math.atan2(
      @math.sin(bearing_rad) * @math.sin(rad) * @math.cos(center_lat),
      @math.cos(rad) - @math.sin(center_lat) * @math.sin(lat),
    )
  let to_deg = fn(x) { x * 180.0 / @math.PI }
  let lng_deg = (-180.0).max(180.0.min(to_deg(lng)))
  @type.Point::from_tuple((lng_deg, to_deg(lat)))
}

///|
/// Returns a Point along the great-circle arc between `start` and `end` at
/// fractional ratio `ratio_from_start` (0.0 = start, 1.0 = end).
pub fn point_at_ratio_between(
  start : @type.Point,
  end : @type.Point,
  ratio_from_start : Double,
) -> @type.Point {
  if start == end || ratio_from_start == 0.0 {
    return start
  }
  if ratio_from_start == 1.0 {
    return end
  }
  let to_rad = fn(x) { x * @math.PI / 180.0 }
  let lat1 = to_rad(start.y())
  let lon1 = to_rad(start.x())
  let lat2 = to_rad(end.y())
  let lon2 = to_rad(end.x())

  let (lat1_sin, lat1_cos) = (@math.sin(lat1), @math.cos(lat1))
  let (lat2_sin, lat2_cos) = (@math.sin(lat2), @math.cos(lat2))
  let (lon1_sin, lon1_cos) = (@math.sin(lon1), @math.cos(lon1))
  let (lon2_sin, lon2_cos) = (@math.sin(lon2), @math.cos(lon2))

  let m = lat1_cos * lat2_cos
  let n = lat1_cos * lon1_cos
  let o = lat2_cos * lon2_cos
  let p = lat1_cos * lon1_sin
  let q = lat2_cos * lon2_sin
  let k = (
    @math.sin((lat1 - lat2) / 2.0) * @math.sin((lat1 - lat2) / 2.0) +
    m * @math.sin((lon1 - lon2) / 2.0) * @math.sin((lon1 - lon2) / 2.0)
  ).sqrt()
  let d = 2.0 * @math.asin(k)

  let a = @math.sin((1.0 - ratio_from_start) * d) / @math.sin(d)
  let b = @math.sin(ratio_from_start * d) / @math.sin(d)

  let x = a * n + b * o
  let y = a * p + b * q
  let z = a * lat1_sin + b * lat2_sin

  let lat = @math.atan2(z, (x * x + y * y).sqrt())
  let lon = @math.atan2(y, x)

  let to_deg = fn(x) { x * 180.0 / @math.PI }
  @type.Point::from_tuple(((-180.0).max(180.0.min(to_deg(lon))), to_deg(lat)))
}

///|
/// Returns a Point along the great-circle arc between `start` and `end` at
/// the given distance `meters_from_start` from `start`.
pub fn point_at_distance_between(
  start : @type.Point,
  end : @type.Point,
  meters_from_start : Double,
) -> @type.Point {
  let m = haversine()
  let bearing = m.bearing(start, end)
  m.destination(start, bearing, meters_from_start)
}

///|
/// Great-circle (spherical) length of a line string. Sums the haversine
/// distances between consecutive coordinate pairs.
///
/// ```check
/// test "haversine_length - 1 degree at equator ~111km" {
///   let ls = @type.LineString::from_tuples([(0.0, 0.0), (1.0, 0.0)])
///   let len = haversine_length(ls)
///   assert_true((len - 111_319.49).abs() < 1.0)
/// }
/// ```
pub fn haversine_length(ls : @type.LineString) -> Double {
  let coords = ls.coords()
  if coords.length() < 2 {
    return 0.0
  }
  let m = haversine()
  let mut total = 0.0
  for i = 0; i < coords.length() - 1; i = i + 1 {
    let p1 = @type.Point::from_coord(coords[i])
    let p2 = @type.Point::from_coord(coords[i + 1])
    total = total + m.distance(p1, p2)
  }
  total
}
