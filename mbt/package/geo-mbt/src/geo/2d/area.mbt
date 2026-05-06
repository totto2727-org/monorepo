// Ported from georust/geo
// https://github.com/georust/geo/blob/main/geo/src/algorithm/area.rs

///|
/// Adds up the determinants of the lines between consecutive `points`,
/// shifted so the first coordinate is the origin (numerical stability).
/// The first and last segment have determinant zero after shifting and are
/// skipped.
fn sum_line_determinants(points : Array[@type.Coord]) -> Double {
  if points.length() <= 2 {
    return 0.0
  }
  let mut sum = 0.0
  let shift = points[0]
  let mut prev = points[1] - shift
  for i = 2; i < points.length(); i = i + 1 {
    let shifted = points[i] - shift
    let line = @type.Line::Line(prev, shifted)
    sum = sum + line.determinant()
    prev = shifted
  }
  sum
}

///|
/// Twice the signed area of a closed ring (`twice_signed_ring_area` in geo).
/// Returns `0.0` if the ring is open or has fewer than 3 coordinates.
pub fn twice_signed_ring_area(ls : @type.LineString) -> Double {
  let coords = ls.coords()
  if coords.length() < 3 {
    return 0.0
  }
  if coords[0] != coords[coords.length() - 1] {
    return 0.0
  }
  sum_line_determinants(coords)
}

///|
/// Signed area of a single linestring ring (the shoelace formula divided by 2).
fn linestring_signed_area(ls : @type.LineString) -> Double {
  twice_signed_ring_area(ls) / 2.0
}

///|
/// Signed planar area of a `Polygon`. The interior rings reduce the area in
/// magnitude; the sign matches the orientation of the exterior ring.
pub fn signed_area_of_polygon(p : @type.Polygon) -> Double {
  let exterior_area = linestring_signed_area(p.exterior())
  let is_negative = exterior_area < 0.0
  let mut area = exterior_area.abs()
  for interior in p.interiors() {
    area = area - linestring_signed_area(interior).abs()
  }
  if is_negative {
    -area
  } else {
    area
  }
}

///|
pub fn unsigned_area_of_polygon(p : @type.Polygon) -> Double {
  signed_area_of_polygon(p).abs()
}

///|
pub fn signed_area_of_multi_polygon(mp : @type.MultiPolygon) -> Double {
  let mut total = 0.0
  for p in mp.polygons() {
    total = total + signed_area_of_polygon(p)
  }
  total
}

///|
pub fn unsigned_area_of_multi_polygon(mp : @type.MultiPolygon) -> Double {
  let mut total = 0.0
  for p in mp.polygons() {
    total = total + unsigned_area_of_polygon(p)
  }
  total
}

///|
pub fn signed_area_of_rect(r : @type.Rect) -> Double {
  r.width() * r.height()
}

///|
pub fn unsigned_area_of_rect(r : @type.Rect) -> Double {
  r.width() * r.height()
}

///|
pub fn signed_area_of_triangle(t : @type.Triangle) -> Double {
  sum_line_determinants(t.to_array()) / 2.0
}

///|
pub fn unsigned_area_of_triangle(t : @type.Triangle) -> Double {
  signed_area_of_triangle(t).abs()
}

///|
/// Signed planar area of a `Geometry`. Zero-dimensional and one-dimensional
/// geometries (Point, MultiPoint, Line, LineString, MultiLineString) have area
/// zero.
pub fn signed_area_of_geometry(g : @type.Geometry) -> Double {
  match g {
    @type.Geometry::Polygon(p) => signed_area_of_polygon(p)
    @type.Geometry::MultiPolygon(mp) => signed_area_of_multi_polygon(mp)
    @type.Geometry::Rect(r) => signed_area_of_rect(r)
    @type.Geometry::Triangle(t) => signed_area_of_triangle(t)
    @type.Geometry::GeometryCollection(gc) => {
      let mut total = 0.0
      for g2 in gc.geometries() {
        total = total + signed_area_of_geometry(g2)
      }
      total
    }
    _ => 0.0
  }
}

///|
/// Unsigned planar area = `signed_area_of_geometry(g).abs()` for individual
/// geometries; for `GeometryCollection` it sums the unsigned areas of the
/// components.
pub fn unsigned_area_of_geometry(g : @type.Geometry) -> Double {
  match g {
    @type.Geometry::Polygon(p) => unsigned_area_of_polygon(p)
    @type.Geometry::MultiPolygon(mp) => unsigned_area_of_multi_polygon(mp)
    @type.Geometry::Rect(r) => unsigned_area_of_rect(r)
    @type.Geometry::Triangle(t) => unsigned_area_of_triangle(t)
    @type.Geometry::GeometryCollection(gc) => {
      let mut total = 0.0
      for g2 in gc.geometries() {
        total = total + unsigned_area_of_geometry(g2)
      }
      total
    }
    _ => 0.0
  }
}
