// Ported from georust/geo
// https://github.com/georust/geo/blob/main/geo/src/algorithm/coords_iter.rs

///|
/// Returns an array containing all (exterior + interior) coordinates of a
/// geometry, in iteration order. The array form is preferred over a lazy
/// iterator since MoonBit's `Iter` does not retain ordering guarantees as
/// strongly as Rust's `Iterator` for these per-type recursive cases.
fn coords_of_point(p : @type.Point) -> Array[@type.Coord] {
  [p.coord()]
}

///|
fn coords_of_line(l : @type.Line) -> Array[@type.Coord] {
  [l.start(), l.end()]
}

///|
fn coords_of_line_string(ls : @type.LineString) -> Array[@type.Coord] {
  // Defensive copy so the caller cannot mutate the line string's backing
  // array via the returned reference.
  [..ls.coords()]
}

///|
fn coords_of_multi_point(mp : @type.MultiPoint) -> Array[@type.Coord] {
  mp.points().map(@type.Point::coord)
}

///|
fn coords_of_multi_line_string(
  mls : @type.MultiLineString,
) -> Array[@type.Coord] {
  mls.line_strings().iter().flat_map(fn(ls) { ls.coords().iter() }).collect()
}

///|
fn coords_of_polygon(p : @type.Polygon) -> Array[@type.Coord] {
  p
  .exterior()
  .coords()
  .iter()
  .concat(
    p.interiors().iter().flat_map(fn(interior) { interior.coords().iter() }),
  )
  .collect()
}

///|
fn coords_of_multi_polygon(mp : @type.MultiPolygon) -> Array[@type.Coord] {
  mp
  .polygons()
  .iter()
  .flat_map(fn(poly) { coords_of_polygon(poly).iter() })
  .collect()
}

///|
fn coords_of_rect(r : @type.Rect) -> Array[@type.Coord] {
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
fn coords_of_triangle(t : @type.Triangle) -> Array[@type.Coord] {
  [t.v0(), t.v1(), t.v2()]
}

///|
fn coords_of_geometry_collection(
  gc : @type.GeometryCollection,
) -> Array[@type.Coord] {
  gc
  .geometries()
  .iter()
  .flat_map(fn(g) { coords_of_geometry(g).iter() })
  .collect()
}

///|
/// Dispatches `coords_of_*` based on the `Geometry` variant.
fn coords_of_geometry(g : @type.Geometry) -> Array[@type.Coord] {
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
fn exterior_coords_of_polygon(p : @type.Polygon) -> Array[@type.Coord] {
  [..p.exterior().coords()]
}

///|
fn exterior_coords_of_multi_polygon(
  mp : @type.MultiPolygon,
) -> Array[@type.Coord] {
  mp
  .polygons()
  .iter()
  .flat_map(fn(poly) { exterior_coords_of_polygon(poly).iter() })
  .collect()
}

///|
fn exterior_coords_of_geometry(g : @type.Geometry) -> Array[@type.Coord] {
  match g {
    @type.Geometry::Polygon(p) => exterior_coords_of_polygon(p)
    @type.Geometry::MultiPolygon(mp) => exterior_coords_of_multi_polygon(mp)
    _ => coords_of_geometry(g)
  }
}

// MARK: trait CoordsCarrier + impls -----------------------------------------

///|
/// Anything that produces a sequence of `Coord`s (lossless representation
/// of all the geometry's coordinates, including interior rings).
pub(open) trait CoordsCarrier {
  coords(Self) -> Array[@type.Coord]
}

///|
pub impl CoordsCarrier for @type.Point with coords(self) {
  coords_of_point(self)
}

///|
pub impl CoordsCarrier for @type.MultiPoint with coords(self) {
  coords_of_multi_point(self)
}

///|
pub impl CoordsCarrier for @type.Line with coords(self) {
  coords_of_line(self)
}

///|
pub impl CoordsCarrier for @type.LineString with coords(self) {
  coords_of_line_string(self)
}

///|
pub impl CoordsCarrier for @type.MultiLineString with coords(self) {
  coords_of_multi_line_string(self)
}

///|
pub impl CoordsCarrier for @type.Polygon with coords(self) {
  coords_of_polygon(self)
}

///|
pub impl CoordsCarrier for @type.MultiPolygon with coords(self) {
  coords_of_multi_polygon(self)
}

///|
pub impl CoordsCarrier for @type.Rect with coords(self) {
  coords_of_rect(self)
}

///|
pub impl CoordsCarrier for @type.Triangle with coords(self) {
  coords_of_triangle(self)
}

///|
pub impl CoordsCarrier for @type.GeometryCollection with coords(self) {
  coords_of_geometry_collection(self)
}

///|
pub impl CoordsCarrier for @type.Geometry with coords(self) {
  coords_of_geometry(self)
}

// MARK: trait ExteriorCoordsCarrier + impls ---------------------------------

///|
/// Anything whose **exterior** coordinates can be enumerated. For shapes
/// without interior rings this is identical to `CoordsCarrier::coords`; for
/// `Polygon` / `MultiPolygon` / `Geometry` it excludes interior rings.
pub(open) trait ExteriorCoordsCarrier {
  exterior_coords(Self) -> Array[@type.Coord]
}

///|
pub impl ExteriorCoordsCarrier for @type.Polygon with exterior_coords(self) {
  exterior_coords_of_polygon(self)
}

///|
pub impl ExteriorCoordsCarrier for @type.MultiPolygon with exterior_coords(self) {
  exterior_coords_of_multi_polygon(self)
}

///|
pub impl ExteriorCoordsCarrier for @type.Geometry with exterior_coords(self) {
  exterior_coords_of_geometry(self)
}
