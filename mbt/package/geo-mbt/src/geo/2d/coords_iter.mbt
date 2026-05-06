// Ported from georust/geo
// https://github.com/georust/geo/blob/main/geo/src/algorithm/coords_iter.rs

///|
/// Returns an array containing all (exterior + interior) coordinates of a
/// geometry, in iteration order. The array form is preferred over a lazy
/// iterator since MoonBit's `Iter` does not retain ordering guarantees as
/// strongly as Rust's `Iterator` for these per-type recursive cases.
pub fn coords_of_point(p : @type.Point) -> Array[@type.Coord] {
  [p.coord()]
}

///|
pub fn coords_of_line(l : @type.Line) -> Array[@type.Coord] {
  [l.start(), l.end()]
}

///|
pub fn coords_of_line_string(ls : @type.LineString) -> Array[@type.Coord] {
  // Defensive copy so the caller cannot mutate the line string's backing
  // array via the returned reference.
  [..ls.coords()]
}

///|
pub fn coords_of_multi_point(mp : @type.MultiPoint) -> Array[@type.Coord] {
  mp.points().map(@type.Point::coord)
}

///|
pub fn coords_of_multi_line_string(
  mls : @type.MultiLineString,
) -> Array[@type.Coord] {
  mls.line_strings().iter().flat_map(fn(ls) { ls.coords().iter() }).collect()
}

///|
pub fn coords_of_polygon(p : @type.Polygon) -> Array[@type.Coord] {
  p.exterior()
  .coords()
  .iter()
  .concat(
    p.interiors().iter().flat_map(fn(interior) { interior.coords().iter() }),
  )
  .collect()
}

///|
pub fn coords_of_multi_polygon(mp : @type.MultiPolygon) -> Array[@type.Coord] {
  mp.polygons().iter().flat_map(fn(poly) { coords_of_polygon(poly).iter() }).collect()
}

///|
pub fn coords_of_rect(r : @type.Rect) -> Array[@type.Coord] {
  let min = r.min()
  let max = r.max()
  [
    @type.Coord(min.x(), min.y()),
    @type.Coord(min.x(), max.y()),
    @type.Coord(max.x(), max.y()),
    @type.Coord(max.x(), min.y()),
  ]
}

///|
pub fn coords_of_triangle(t : @type.Triangle) -> Array[@type.Coord] {
  [t.v0(), t.v1(), t.v2()]
}

///|
pub fn coords_of_geometry_collection(
  gc : @type.GeometryCollection,
) -> Array[@type.Coord] {
  gc.geometries().iter().flat_map(fn(g) { coords_of_geometry(g).iter() }).collect()
}

///|
/// Dispatches `coords_of_*` based on the `Geometry` variant.
pub fn coords_of_geometry(g : @type.Geometry) -> Array[@type.Coord] {
  match g {
    @type.Geometry::Point(p) => coords_of_point(p)
    @type.Geometry::Line(l) => coords_of_line(l)
    @type.Geometry::LineString(ls) => coords_of_line_string(ls)
    @type.Geometry::Polygon(poly) => coords_of_polygon(poly)
    @type.Geometry::MultiPoint(mp) => coords_of_multi_point(mp)
    @type.Geometry::MultiLineString(mls) => coords_of_multi_line_string(mls)
    @type.Geometry::MultiPolygon(mp) => coords_of_multi_polygon(mp)
    @type.Geometry::GeometryCollection(gc) => coords_of_geometry_collection(gc)
    @type.Geometry::Rect(r) => coords_of_rect(r)
    @type.Geometry::Triangle(t) => coords_of_triangle(t)
  }
}

///|
/// Returns the count of coordinates in the geometry (the length of the
/// array returned by `coords_of_geometry`).
pub fn coords_count(g : @type.Geometry) -> Int {
  coords_of_geometry(g).length()
}

///|
/// Returns only the exterior coordinates of the geometry. For `Polygon` /
/// `MultiPolygon` this excludes interior rings; for other geometries this
/// is identical to `coords_of_geometry`.
pub fn exterior_coords_of_polygon(p : @type.Polygon) -> Array[@type.Coord] {
  [..p.exterior().coords()]
}

///|
pub fn exterior_coords_of_multi_polygon(
  mp : @type.MultiPolygon,
) -> Array[@type.Coord] {
  mp.polygons()
  .iter()
  .flat_map(fn(poly) { exterior_coords_of_polygon(poly).iter() })
  .collect()
}

///|
pub fn exterior_coords_of_geometry(g : @type.Geometry) -> Array[@type.Coord] {
  match g {
    @type.Geometry::Polygon(p) => exterior_coords_of_polygon(p)
    @type.Geometry::MultiPolygon(mp) => exterior_coords_of_multi_polygon(mp)
    _ => coords_of_geometry(g)
  }
}
