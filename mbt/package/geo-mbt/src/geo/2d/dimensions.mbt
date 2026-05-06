// Ported from georust/geo
// https://github.com/georust/geo/blob/main/geo/src/algorithm/dimensions.rs

///|
/// Geometries can have 0, 1, or 2 dimensions, plus a special `Empty`
/// dimensionality (for empty collections / linestrings).
pub(all) enum Dimensions {
  Empty
  ZeroDimensional
  OneDimensional
  TwoDimensional
} derive(Eq, Debug)

///|
/// Compares dimensions in the natural ordering Empty < ZeroDimensional <
/// OneDimensional < TwoDimensional. Returns the integer rank.
pub fn Dimensions::rank(self : Dimensions) -> Int {
  match self {
    Empty => 0
    ZeroDimensional => 1
    OneDimensional => 2
    TwoDimensional => 3
  }
}

///|
/// Returns whether `a` has strictly less dimensionality than `b`.
pub fn dimensions_less(a : Dimensions, b : Dimensions) -> Bool {
  a.rank() < b.rank()
}

///|
/// Returns the dimension with the higher rank. Used as a fold combinator
/// when computing the max dimensionality across a collection of components.
fn max_dimension(a : Dimensions, b : Dimensions) -> Dimensions {
  if a.rank() >= b.rank() {
    a
  } else {
    b
  }
}

///|
/// Returns whether the geometry has no coordinates.
pub fn is_empty_of_geometry(g : @type.Geometry) -> Bool {
  match g {
    @type.Geometry::Point(_) => false
    @type.Geometry::Rect(_) => false
    @type.Geometry::Triangle(_) => false
    @type.Geometry::Line(_) => false
    @type.Geometry::LineString(ls) => ls.is_empty()
    @type.Geometry::MultiPoint(mp) => mp.is_empty()
    @type.Geometry::MultiLineString(mls) =>
      mls.line_strings().iter().all(@type.LineString::is_empty)
    @type.Geometry::Polygon(p) => p.exterior().is_empty()
    @type.Geometry::MultiPolygon(mp) =>
      mp.polygons().iter().all(fn(p) { p.exterior().is_empty() })
    @type.Geometry::GeometryCollection(gc) =>
      gc.geometries().iter().all(is_empty_of_geometry)
  }
}

///|
/// Returns the dimensionality of a `Rect`. A degenerate rectangle of zero
/// width and zero height collapses to `ZeroDimensional`; one of zero width
/// or zero height (but not both) is `OneDimensional`.
pub fn dimensions_of_rect(r : @type.Rect) -> Dimensions {
  let zero_w = r.width() == 0.0
  let zero_h = r.height() == 0.0
  match (zero_w, zero_h) {
    (true, true) => ZeroDimensional
    (true, false) | (false, true) => OneDimensional
    _ => TwoDimensional
  }
}

///|
/// Returns the dimensionality of a `LineString`. Empty / single-coord
/// linestrings are `Empty`. A linestring whose coords are all identical is
/// `ZeroDimensional`; otherwise `OneDimensional`.
pub fn dimensions_of_line_string(ls : @type.LineString) -> Dimensions {
  let coords = ls.coords()
  if coords.length() == 0 {
    return Empty
  }
  let first = coords[0]
  if coords.iter().any(fn(c) { c != first }) {
    OneDimensional
  } else {
    ZeroDimensional
  }
}

///|
/// Returns the dimensionality of any geometry.
///
/// `Polygon` is `TwoDimensional` unless its exterior is empty (`Empty`) or all
/// of its exterior coordinates collapse to a single coordinate
/// (`ZeroDimensional`).
pub fn dimensions_of_geometry(g : @type.Geometry) -> Dimensions {
  match g {
    @type.Geometry::Point(_) => ZeroDimensional
    @type.Geometry::Line(l) =>
      if l.start() == l.end() {
        ZeroDimensional
      } else {
        OneDimensional
      }
    @type.Geometry::LineString(ls) => dimensions_of_line_string(ls)
    @type.Geometry::Polygon(p) => {
      let ext = p.exterior()
      match dimensions_of_line_string(ext) {
        Empty => Empty
        ZeroDimensional => ZeroDimensional
        _ => TwoDimensional
      }
    }
    @type.Geometry::MultiPoint(mp) =>
      if mp.is_empty() {
        Empty
      } else {
        ZeroDimensional
      }
    @type.Geometry::MultiLineString(mls) =>
      mls
      .line_strings()
      .iter()
      .map(dimensions_of_line_string)
      .fold(init=Dimensions::Empty, max_dimension)
    @type.Geometry::MultiPolygon(mp) =>
      mp
      .polygons()
      .iter()
      .map(fn(p) { dimensions_of_geometry(@type.Geometry::Polygon(p)) })
      .fold(init=Dimensions::Empty, max_dimension)
    @type.Geometry::Rect(r) => dimensions_of_rect(r)
    @type.Geometry::Triangle(_) => TwoDimensional
    @type.Geometry::GeometryCollection(gc) =>
      gc
      .geometries()
      .iter()
      .map(dimensions_of_geometry)
      .fold(init=Dimensions::Empty, max_dimension)
  }
}
