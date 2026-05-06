// Ported from georust/geo
// https://github.com/georust/geo/blob/main/geo/src/algorithm/centroid.rs

///|
/// Centroid (geometric average) of a non-empty array of coordinates.
fn centroid_of_coords(coords : Array[@type.Coord]) -> @type.Coord? {
  if coords.length() == 0 {
    return None
  }
  let acc = coords
    .iter()
    .fold(init=(0.0, 0.0), fn(acc, c) { (acc.0 + c.x(), acc.1 + c.y()) })
  let (sum_x, sum_y) = acc
  let n = coords.length().to_double()
  Some(@type.Coord(sum_x / n, sum_y / n))
}

///|
/// Centroid of a `LineString` weighted by segment length. Returns `None` for
/// empty linestrings.
fn centroid_line_string(ls : @type.LineString) -> @type.Point? {
  let segments = ls.lines()
  if segments.length() == 0 {
    if ls.coords().length() == 1 {
      return Some(@type.Point::from_coord(ls.coords()[0]))
    }
    return None
  }
  let acc = segments
    .iter()
    .fold(init=(0.0, 0.0, 0.0), fn(acc, line) {
      let len = euclidean_length_line(line)
      let mid_x = (line.start().x() + line.end().x()) / 2.0
      let mid_y = (line.start().y() + line.end().y()) / 2.0
      (acc.0 + len * mid_x, acc.1 + len * mid_y, acc.2 + len)
    })
  let (sum_x, sum_y, total_length) = acc
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
  (0)
  .until(n - 1)
  .fold(init=(0.0, 0.0, 0.0), fn(acc, i) {
    let c1 = coords[i]
    let c2 = coords[i + 1]
    let cross = c1.x() * c2.y() - c2.x() * c1.y()
    (
      acc.0 + sign * (c1.x() + c2.x()) * cross,
      acc.1 + sign * (c1.y() + c2.y()) * cross,
      acc.2 + sign * cross,
    )
  })
}

///|
/// Centroid of a polygon (the centre of mass). Holes contribute negatively
/// to the weighted sum.
fn centroid_polygon(p : @type.Polygon) -> @type.Point? {
  let exterior = p.exterior()
  let exterior_coords = exterior.coords()
  if exterior_coords.length() < 3 {
    return centroid_line_string(exterior)
  }
  let exterior_acc = ring_centroid_accumulator(exterior, 1.0)
  let acc = p
    .interiors()
    .iter()
    .fold(init=exterior_acc, fn(acc, interior) {
      let i = ring_centroid_accumulator(interior, -1.0)
      (acc.0 + i.0, acc.1 + i.1, acc.2 + i.2)
    })
  let (sum_x, sum_y, total_area) = acc
  let area = total_area / 2.0
  if area == 0.0 {
    return centroid_of_coords(exterior_coords).map(@type.Point::from_coord)
  }
  Some(@type.Point::Point(sum_x / (6.0 * area), sum_y / (6.0 * area)))
}

///|
/// Centroid of a multi polygon weighted by polygon area.
fn centroid_multi_polygon(mp : @type.MultiPolygon) -> @type.Point? {
  if mp.is_empty() {
    return None
  }
  let acc = mp
    .polygons()
    .iter()
    .filter_map(fn(p) {
      centroid_polygon(p).map(fn(c) { (c, unsigned_area_of_polygon(p)) })
    })
    .fold(init=(0.0, 0.0, 0.0), fn(acc, ca) {
      let (c, a) = ca
      (acc.0 + c.x() * a, acc.1 + c.y() * a, acc.2 + a)
    })
  let (sum_x, sum_y, total_area) = acc
  if total_area == 0.0 {
    None
  } else {
    Some(@type.Point::Point(sum_x / total_area, sum_y / total_area))
  }
}

///|
fn centroid_geometry(g : @type.Geometry) -> @type.Point? {
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
      let acc = mls
        .line_strings()
        .iter()
        .filter_map(fn(ls) {
          centroid_line_string(ls).map(fn(c) {
            (c, euclidean_length_line_string(ls))
          })
        })
        .fold(init=(0.0, 0.0, 0.0), fn(acc, cl) {
          let (c, len) = cl
          (acc.0 + c.x() * len, acc.1 + c.y() * len, acc.2 + len)
        })
      let (sum_x, sum_y, total_length) = acc
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
      let acc = gc
        .geometries()
        .iter()
        .filter_map(centroid_geometry)
        .fold(init=(0.0, 0.0, 0), fn(acc, c) {
          (acc.0 + c.x(), acc.1 + c.y(), acc.2 + 1)
        })
      let (sum_x, sum_y, count) = acc
      if count == 0 {
        None
      } else {
        let n = count.to_double()
        Some(@type.Point::Point(sum_x / n, sum_y / n))
      }
    }
  }
}
