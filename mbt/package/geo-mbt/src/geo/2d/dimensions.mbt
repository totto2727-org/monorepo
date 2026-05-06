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
