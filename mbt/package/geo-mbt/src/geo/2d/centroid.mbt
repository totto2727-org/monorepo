// Ported from georust/geo
// https://github.com/georust/geo/blob/main/geo/src/algorithm/centroid.rs

///|
/// Centroid (geometric average) of a non-empty array of coordinates.
fn centroid_of_coords(coords : Array[@type.Coord]) -> @type.Coord? {
  if coords.length() == 0 {
    return None
  }
  let mut sum_x = 0.0
  let mut sum_y = 0.0
  for c in coords {
    sum_x = sum_x + c.x()
    sum_y = sum_y + c.y()
  }
  let n = coords.length().to_double()
  Some(@type.Coord(sum_x / n, sum_y / n))
}

///|
/// Centroid of a `LineString` weighted by segment length. Returns `None` for
/// empty linestrings.
pub fn centroid_line_string(ls : @type.LineString) -> @type.Point? {
  let segments = ls.lines()
  if segments.length() == 0 {
    if ls.coords().length() == 1 {
      return Some(@type.Point::from_coord(ls.coords()[0]))
    }
    return None
  }
  let mut total_length = 0.0
  let mut sum_x = 0.0
  let mut sum_y = 0.0
  for line in segments {
    let len = euclidean_length_line(line)
    let mid_x = (line.start().x() + line.end().x()) / 2.0
    let mid_y = (line.start().y() + line.end().y()) / 2.0
    sum_x = sum_x + len * mid_x
    sum_y = sum_y + len * mid_y
    total_length = total_length + len
  }
  if total_length == 0.0 {
    return centroid_of_coords(ls.coords()).map(@type.Point::from_coord)
  }
  Some(@type.Point::Point(sum_x / total_length, sum_y / total_length))
}

///|
/// Accumulator for a single ring's contribution: returns
/// `(weighted_sum_x, weighted_sum_y, twice_signed_area)` (all summed using
/// the shoelace formula).
fn ring_centroid_accumulator(
  ring : @type.LineString,
  sign : Double,
) -> (Double, Double, Double) {
  let coords = ring.coords()
  let n = coords.length()
  if n < 3 {
    return (0.0, 0.0, 0.0)
  }
  let mut sum_x = 0.0
  let mut sum_y = 0.0
  let mut total_area = 0.0
  for i = 0; i < n - 1; i = i + 1 {
    let c1 = coords[i]
    let c2 = coords[i + 1]
    let cross = c1.x() * c2.y() - c2.x() * c1.y()
    sum_x = sum_x + sign * (c1.x() + c2.x()) * cross
    sum_y = sum_y + sign * (c1.y() + c2.y()) * cross
    total_area = total_area + sign * cross
  }
  (sum_x, sum_y, total_area)
}

///|
/// Centroid of a polygon (the centre of mass). Holes contribute negatively
/// to the weighted sum.
pub fn centroid_polygon(p : @type.Polygon) -> @type.Point? {
  let exterior = p.exterior()
  let exterior_coords = exterior.coords()
  if exterior_coords.length() < 3 {
    return centroid_line_string(exterior)
  }
  let mut sum_x = 0.0
  let mut sum_y = 0.0
  let mut total_area = 0.0
  let (sx, sy, sa) = ring_centroid_accumulator(exterior, 1.0)
  sum_x = sum_x + sx
  sum_y = sum_y + sy
  total_area = total_area + sa
  for interior in p.interiors() {
    let (ix, iy, ia) = ring_centroid_accumulator(interior, -1.0)
    sum_x = sum_x + ix
    sum_y = sum_y + iy
    total_area = total_area + ia
  }
  let area = total_area / 2.0
  if area == 0.0 {
    return centroid_of_coords(exterior_coords).map(@type.Point::from_coord)
  }
  Some(@type.Point::Point(sum_x / (6.0 * area), sum_y / (6.0 * area)))
}

///|
/// Centroid of a multi polygon weighted by polygon area.
pub fn centroid_multi_polygon(mp : @type.MultiPolygon) -> @type.Point? {
  if mp.is_empty() {
    return None
  }
  let mut sum_x = 0.0
  let mut sum_y = 0.0
  let mut total_area = 0.0
  for p in mp.polygons() {
    match centroid_polygon(p) {
      Some(c) => {
        let a = unsigned_area_of_polygon(p)
        sum_x = sum_x + c.x() * a
        sum_y = sum_y + c.y() * a
        total_area = total_area + a
      }
      None => continue
    }
  }
  if total_area == 0.0 {
    None
  } else {
    Some(@type.Point::Point(sum_x / total_area, sum_y / total_area))
  }
}

///|
pub fn centroid_geometry(g : @type.Geometry) -> @type.Point? {
  match g {
    @type.Geometry::Point(p) => Some(p)
    @type.Geometry::Line(l) =>
      Some(
        @type.Point::Point(
          (l.start().x() + l.end().x()) / 2.0,
          (l.start().y() + l.end().y()) / 2.0,
        ),
      )
    @type.Geometry::LineString(ls) => centroid_line_string(ls)
    @type.Geometry::Polygon(p) => centroid_polygon(p)
    @type.Geometry::MultiPoint(mp) =>
      centroid_of_coords(mp.points().map(fn(p) { p.coord() })).map(
        @type.Point::from_coord,
      )
    @type.Geometry::MultiLineString(mls) => {
      let mut sum_x = 0.0
      let mut sum_y = 0.0
      let mut total_length = 0.0
      for ls in mls.line_strings() {
        match centroid_line_string(ls) {
          Some(c) => {
            let len = euclidean_length_line_string(ls)
            sum_x = sum_x + c.x() * len
            sum_y = sum_y + c.y() * len
            total_length = total_length + len
          }
          None => continue
        }
      }
      if total_length == 0.0 {
        None
      } else {
        Some(@type.Point::Point(sum_x / total_length, sum_y / total_length))
      }
    }
    @type.Geometry::MultiPolygon(mp) => centroid_multi_polygon(mp)
    @type.Geometry::Rect(r) => Some(@type.Point::from_coord(r.center()))
    @type.Geometry::Triangle(t) =>
      Some(
        @type.Point::Point(
          (t.v0().x() + t.v1().x() + t.v2().x()) / 3.0,
          (t.v0().y() + t.v1().y() + t.v2().y()) / 3.0,
        ),
      )
    @type.Geometry::GeometryCollection(gc) => {
      let mut sum_x = 0.0
      let mut sum_y = 0.0
      let mut count = 0
      for g2 in gc.geometries() {
        match centroid_geometry(g2) {
          Some(c) => {
            sum_x = sum_x + c.x()
            sum_y = sum_y + c.y()
            count = count + 1
          }
          None => continue
        }
      }
      if count == 0 {
        None
      } else {
        let n = count.to_double()
        Some(@type.Point::Point(sum_x / n, sum_y / n))
      }
    }
  }
}
