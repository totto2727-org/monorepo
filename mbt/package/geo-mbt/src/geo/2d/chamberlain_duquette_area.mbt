// Ported from georust/geo
// https://github.com/georust/geo/blob/main/geo/src/algorithm/chamberlain_duquette_area.rs
//
// References:
//   Robert G. Chamberlain and William H. Duquette,
//   "Some Algorithms for Polygons on a Sphere",
//   JPL Publication 07-03, June 2007.
//
// The signed area of a spherical polygon expressed in meters², approximated
// using a sphere of radius `EQUATORIAL_EARTH_RADIUS` (WGS84). Result is
// signed: positive for CCW (counter-clockwise) outer boundaries on the
// surface, negative for CW.
//
// Caller note (matches upstream): the sign convention here is *opposite*
// to the planar `Area` trait's `signed_area`. CCW lng/lat polygons that
// look "normal" on a Mercator map will yield a positive signed area here.

///|
/// WGS84 equatorial radius in meters. Mirrors `geo`'s `EQUATORIAL_EARTH_RADIUS`.
const CHAMBERLAIN_EARTH_RADIUS : Double = 6_378_137.0

///|
/// Signed approximate spherical area of a single ring (`LineString` with
/// first == last). Returns 0 for rings with fewer than 3 points.
fn ring_chamberlain_duquette_signed_area(ring : @type.LineString) -> Double {
  let coords = ring.coords()
  let n = coords.length()
  if n <= 2 {
    return 0.0
  }
  let mut total = 0.0
  for i in 0..<n {
    let (lower_index, middle_index, upper_index) = if i == n - 2 {
      (n - 2, n - 1, 0)
    } else if i == n - 1 {
      (n - 1, 0, 1)
    } else {
      (i, i + 1, i + 2)
    }
    let p1 = coords[lower_index]
    let p2 = coords[middle_index]
    let p3 = coords[upper_index]
    let to_rad = fn(x : Double) -> Double { x * @math.PI / 180.0 }
    total = total +
      (to_rad(p3.x()) - to_rad(p1.x())) * @math.sin(to_rad(p2.y()))
  }
  total * CHAMBERLAIN_EARTH_RADIUS * CHAMBERLAIN_EARTH_RADIUS / -2.0
}

///|
/// Signed Chamberlain-Duquette spherical area of a polygon (meters²).
fn chamberlain_duquette_signed_area_polygon(
  polygon : @type.Polygon,
) -> Double {
  polygon
  .interiors()
  .iter()
  .fold(init=ring_chamberlain_duquette_signed_area(polygon.exterior()), fn(
    total,
    next,
  ) {
    total - ring_chamberlain_duquette_signed_area(next)
  })
}

///|
/// Unsigned (absolute) Chamberlain-Duquette spherical area of a polygon
/// (meters²).
fn chamberlain_duquette_unsigned_area_polygon(
  polygon : @type.Polygon,
) -> Double {
  chamberlain_duquette_signed_area_polygon(polygon).abs()
}

///|
/// Signed Chamberlain-Duquette spherical area of a `MultiPolygon` (sum of
/// per-component signed areas; meters²).
fn chamberlain_duquette_signed_area_multi_polygon(
  mp : @type.MultiPolygon,
) -> Double {
  mp
  .polygons()
  .iter()
  .fold(init=0.0, fn(total, p) {
    total + chamberlain_duquette_signed_area_polygon(p)
  })
}

///|
/// Unsigned Chamberlain-Duquette spherical area of a `MultiPolygon`
/// (meters²).
fn chamberlain_duquette_unsigned_area_multi_polygon(
  mp : @type.MultiPolygon,
) -> Double {
  mp
  .polygons()
  .iter()
  .fold(init=0.0, fn(total, p) {
    total + chamberlain_duquette_unsigned_area_polygon(p)
  })
}

///|
/// Signed Chamberlain-Duquette spherical area of a `Geometry`. Per upstream:
/// non-area geometries (Point/Line/LineString/MultiPoint/MultiLineString)
/// return 0. `Rect` and `Triangle` delegate to their `to_polygon()`.
/// `GeometryCollection` sums per-component signed areas.
pub fn chamberlain_duquette_signed_area_geometry(g : @type.Geometry) -> Double {
  match g {
    @type.Geometry::Point(_) => 0.0
    @type.Geometry::Line(_) => 0.0
    @type.Geometry::LineString(_) => 0.0
    @type.Geometry::MultiPoint(_) => 0.0
    @type.Geometry::MultiLineString(_) => 0.0
    @type.Geometry::Polygon(p) => chamberlain_duquette_signed_area_polygon(p)
    @type.Geometry::MultiPolygon(mp) =>
      chamberlain_duquette_signed_area_multi_polygon(mp)
    @type.Geometry::Rect(r) =>
      chamberlain_duquette_signed_area_polygon(r.to_polygon())
    @type.Geometry::Triangle(t) =>
      chamberlain_duquette_signed_area_polygon(t.to_polygon())
    @type.Geometry::GeometryCollection(gc) =>
      gc
      .geometries()
      .iter()
      .fold(init=0.0, fn(total, child) {
        total + chamberlain_duquette_signed_area_geometry(child)
      })
  }
}

///|
/// Unsigned (absolute) Chamberlain-Duquette spherical area of a `Geometry`
/// (meters²).
pub fn chamberlain_duquette_unsigned_area_geometry(
  g : @type.Geometry,
) -> Double {
  match g {
    @type.Geometry::Polygon(p) => chamberlain_duquette_unsigned_area_polygon(p)
    @type.Geometry::MultiPolygon(mp) =>
      chamberlain_duquette_unsigned_area_multi_polygon(mp)
    _ => chamberlain_duquette_signed_area_geometry(g).abs()
  }
}
