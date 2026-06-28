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

// MARK: trait HasDimensions + impls -----------------------------------------

///|
/// Anything whose dimensionality (Empty / 0D / 1D / 2D) can be computed.
pub(open) trait HasDimensions {
  fn dimensions(Self) -> Dimensions
}

///|
/// A degenerate rectangle of zero width and zero height collapses to
/// `ZeroDimensional`; one of zero width or zero height (but not both) is
/// `OneDimensional`.
pub impl HasDimensions for @type.Rect with fn dimensions(self) {
  let zero_w = self.width() == 0.0
  let zero_h = self.height() == 0.0
  match (zero_w, zero_h) {
    (true, true) => ZeroDimensional
    (true, false) | (false, true) => OneDimensional
    _ => TwoDimensional
  }
}

///|
/// Empty / single-coord linestrings are `Empty`. A linestring whose coords
/// are all identical is `ZeroDimensional`; otherwise `OneDimensional`.
pub impl HasDimensions for @type.LineString with fn dimensions(self) {
  let coords = self.coords()
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
/// `Polygon` is `TwoDimensional` unless its exterior is empty (`Empty`) or
/// all of its exterior coordinates collapse to a single coordinate
/// (`ZeroDimensional`).
pub impl HasDimensions for @type.Geometry with fn dimensions(self) {
  match self {
    @type.Geometry::Point(_) => ZeroDimensional
    @type.Geometry::Line(l) =>
      if l.start() == l.end() {
        ZeroDimensional
      } else {
        OneDimensional
      }
    @type.Geometry::LineString(ls) => HasDimensions::dimensions(ls)
    @type.Geometry::Polygon(p) =>
      match HasDimensions::dimensions(p.exterior()) {
        Empty => Empty
        ZeroDimensional => ZeroDimensional
        _ => TwoDimensional
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
      .map(HasDimensions::dimensions)
      .fold(init=Dimensions::Empty, max_dimension)
    @type.Geometry::MultiPolygon(mp) =>
      mp
      .polygons()
      .iter()
      .map(fn(p) { HasDimensions::dimensions(@type.Geometry::Polygon(p)) })
      .fold(init=Dimensions::Empty, max_dimension)
    @type.Geometry::Rect(r) => HasDimensions::dimensions(r)
    @type.Geometry::Triangle(_) => TwoDimensional
    @type.Geometry::GeometryCollection(gc) =>
      gc
      .geometries()
      .iter()
      .map(HasDimensions::dimensions)
      .fold(init=Dimensions::Empty, max_dimension)
  }
}
